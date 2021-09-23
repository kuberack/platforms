#!/bin/bash

# Run only at create time
if [[ -f /etc/startup_was_launched ]]; then exit 0; fi

# Install the runtime
sudo apt-get update 
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update 
sudo apt-get install -y containerd.io=1.2.13-1 docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker

# Install the kubelet, kubeadm, and kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update 
sudo apt-get install -y kubelet kubeadm kubectl 
sudo apt-mark hold kubelet kubeadm kubectl 

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/09-extra-args.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=gce"
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

    # write the incremental file to the bucket
    cat <&4 | gsutil cp - gs://platform-infrastructure/kubeadm_extra.yaml


    # install the calico CNI plugin
    # capture the output, and write the parameters to a bucket

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
touch /etc/startup_was_launched

