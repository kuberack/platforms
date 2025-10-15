# platforms
- Contains scripts, manifests to install container runtime, and other kubernetes packages

- Copy the kubeadm_init.yaml, kubeadm_join  files to the cloud storage 
  bucket either using browser or below command
  - gcloud storage cp kubeadm_init.yaml gs://platform-infrastructure/

- Create the master and worker VMs using browser as per the course install 
  module

- Copy the k8s_pkg_install.sh to the master VM, and run the script to bring
  up the master
  - This will generate two files - kubeadm_extra.yaml, kubeconfig - in the 
    cloud storage bucket
  - kubeadm_extra.yaml contains information about the API server endpoint 
    which the worker node installation requires
  - kubeconfig is required by kubectl, and other clients, to access the API
    server

- Once the master is up, copy the k8s_pkg_install.sh to the worker VMs, and
  run the script to bring up the workers

