#!/bin/bash

# Run only at create time
if [[ -f /etc/startup_was_launched ]]; then exit 0; fi

# Setup the hugepages
sudo sysctl -w vm.nr_hugepages=512
echo "vm.nr_hugepages=512" | sudo tee -a /etc/sysctl.conf

# Install the runtime prerequisites
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Install the runtime
sudo apt-get update 
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update 
sudo apt-get install containerd.io -y
sudo mkdir -p /etc/containerd

# Configure the runtime
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo sed -i 's/k8s.gcr.io/registry.k8s.io/g' /etc/containerd/config.toml
sudo sed -i 's/pause:3.8/pause:3.10/g' /etc/containerd/config.toml

# Restart the daemons
sudo systemctl restart containerd

# Install the kubelet, kubeadm, and kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly
sudo apt-get update 
sudo apt-get install -y kubelet kubeadm kubectl 
sudo apt-mark hold kubelet kubeadm kubectl 

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/09-extra-args.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF

# get the kubeadm_* files from the bucket
gsutil cp gs://platform-infrastructure/kubeadm_*.yaml .

# in the master, setup the API server
if [[ $HOSTNAME =~ "master" ]]; then
  echo "Master here!"

  # setup the master node
  output=$(sudo kubeadm init --config kubeadm_init.yaml)

  if [[ $output =~ "kubeadm join" ]]; then
    echo "Master Init done!"

    # create a temp file
    tempfile=$(mktemp /tmp/kubeadm_join_extra.XXXXXX)

    # open once for writing, and reading
    exec 3> "$tempfile" 4< "$tempfile"

    # delete the file
    rm "$tempfile"

    # get the master ip port
    t=${output#*kubeadm join }
    master_ip_port=${t%% *}
    echo "    apiServerEndpoint: \"$master_ip_port\"" >&3

    # get the token
    t=${output#*--token }
    token=${t%% *}
    echo "    token: \"$token\"" >&3

    # get the hash
    t=${output#*--discovery-token-ca-cert-hash }
    cert_hash=${t%% *}
    echo "    caCertHashes: [\"$cert_hash\"]" >&3

    # install the calico CNI plugin
    gsutil cp gs://platform-infrastructure/calico.yaml .
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    knodes=$(kubectl get nodes)
    if [[ $knodes =~ $HOSTNAME ]]; then
      echo "Able to get nodes"
      kubectl apply -f calico.yaml
      echo "calico install done"
    else
      echo "Unable to get nodes"
      exit 1
    fi

    # wait for time for the node to get ready
    # ideally we should poll every second
    sleep 10

    knodes=$(kubectl get nodes)
    if [[ $knodes =~ Ready ]]; then
      echo "Node is ready!"
      gsutil cp $HOME/.kube/config gs://platform-infrastructure/kubeconfig
      echo "Config file copied!"
    else
      echo "Node is not ready"
      exit 1
    fi

    # capture the output, and write the parameters to a bucket
    # write the incremental file to the bucket
    cat <&4 | gsutil cp - gs://platform-infrastructure/kubeadm_extra.yaml

    echo "$host: master init done"

  else
    echo "Error: master init error"
    exit 1
  fi

else

  # on the worker nodes, wait for the parameters on the bucket
  # poll
  # modify the join file as per the parameters
  echo "Checking if kubeadm extra file exists"
  file_path=gs://platform-infrastructure/kubeadm_extra.yaml
  while : ; do
    gsutil -q stat $file_path
    status=$?
    [[ $status != 0 ]] || break
  done

  echo "kubeadm extra file exists"

  # concatenate extra.yaml to the join.yam
  gsutil cp gs://platform-infrastructure/kubeadm_extra.yaml .
  cat kubeadm_extra.yaml >> kubeadm_join.yaml
  sudo kubeadm join --config kubeadm_join.yaml

  echo "$host: Worker node init done"
fi

# create a file to show that the startup was completed
sudo touch /etc/startup_was_launched

