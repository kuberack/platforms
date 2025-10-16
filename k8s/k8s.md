
# Running the shell script
 - Setup the dependencies as indicated in next section
 - ./vm_create.sh
 - This shell script will
   - Create the master, worker VMs
   - Setup a k8s cluster with a calico CNI
   - Setup the cloud controller manager. This is needed for
     provisioning of gce persistent disks on GCP.

# Dependencies

## On local machine
 - gcloud is installed
 - jq is installed
 - yq is installed

## On GCP
 - ssh key ~/.ssh/shivkube_gcp is to be setup in the GCP project metadata
 - kubeadm*.yaml, calico yaml present in below location in cloud storage bucket
   -  gcloud auth login
   -  gcloud config set project tubify-438815
   -  create the cloud bucket platform-infrastructure
   -  gsutil cp kubeadm_*.yaml gs://platform-infrastructure/
   -  gsutil cp calico.yaml gs://platform-infrastructure/
   -  gsutil cp cloud_controller_manager.yaml gs://platform-infrastructure
 - Enable cloudresourcemanager.googleapis.com for the project
 - Once all the nodes are up, we need to manually remove the taint 
   from instance-1 node. This is because the taint is added by the
   kubeadm_join.yaml (cloud provider is external) on the worker
   node, and the cloud controller manager daemonset which is 
   supposed to remove the taint runs only on the master
   - kubectl taint nodes instance-1 node.cloudprovider.kubernetes.io/uninitialized:NoSchedule-
 - We need to manually add tags to the nodes. Else we get 
   error "failed to ensure Load balancer"..
   - gcloud compute instances add-tags k8s-master --tags=k8s-master
   - gcloud compute instances add-tags instance-1 --tags=instance-1

 - A firewall rule to enable IPIP traffic is added in project. This
   is for the calico CNI plugin.

   | Firewall rule name | default-allow-ipip  |
   |--------------------|---------------------|
   | Network            | default             |
   | Priority           | 1000                |
   | Direction          | Ingress             |
   | Action on match    | Allow               |
   | Target tags        | ipip-peer           |
   | Source filters     |                     |
   | IP ranges          | 0.0.0.0/0           |
   | Protocols and ports| ipip                |
                                            
