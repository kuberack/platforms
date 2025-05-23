#!/bin/bash

###################
# Dependencies
###################
#
# ssh key ~/.ssh/shivkube_gcp is to be setup in the GCP project metadata
# gcloud is installed
# jq is installed
# yq is installed
#
# kubeadm*.yaml, calico yaml present in below location in cloud storage bucket
#   - gcloud auth login
#   - gcloud config set project tubify-438815
#   - create the cloud bucket platform-infrastructure
#   - gsutil cp kubeadm_*.yaml gs://platform-infrastructure/
#   - gsutil cp calico.yaml gs://platform-infrastructure/
#   - gsutil cp cloud_controller_manager.yaml gs://platform-infrastructure/
#
# A firewall rule to enable IPIP traffic is added in project
#   - Firewall rule name : default-allow-ipip
#     Network            : default
#     Priority           : 1000
#     Direction          : Ingress
#     Action on match    : Allow
#     Target tags        : ipip-peer
#     Source filters
#     IP ranges          : 0.0.0.0/0
#     Protocols and ports: ipip



###################
# Utility Functions
###################

# Check if the vm is created successfully
# $1 = vm name
check_vm_creation () {
    # check if the VM is created, and running
    declare result=$(gcloud compute instances describe $1 --format="json(name, status)" 2>&1)
    
    # Check if command executed successfully
    if [ $? -eq 0 ]
    then
      echo "Successfully executed gcloud command"
      echo $result
    else
      echo "Error in executing gcloud command"
      return 1
    fi
    
    # Check for Error
    if [[ $result = *ERROR:*  ]]; then
      echo "Error in listing VM"
      return 1
    fi
    
    # Get the name, status
    declare n=$(echo $result | jq .name | tr -d '"')
    declare s=$(echo $result | jq .status | tr -d '"')
    
    if [ $n != $1 ]
    then
      echo "Could not find VM"
      echo $n $1
      return 1
    fi
    
    echo $n
    
    if [ $s != RUNNING ]
    then
      echo "VM is not running"
      echo $s
      return 1
    fi
    
    echo "VM is running"
    return 0
}

# retry function
# $1 command to be executed
# $2 parameter to the command
retry_command () {
    # Set the maximum number of attempts
    max_attempts=5
    
    # Set a counter for the number of attempts
    attempt_num=1
    
    # Set a flag to indicate whether the command was successful
    success=false
    
    # Loop until the command is successful or the maximum number of attempts is reached
    while [ $success = false ] && [ $attempt_num -le $max_attempts ]; do
      # Execute the command
      $1 $2
    
      # Check the exit code of the command
      if [ $? -eq 0 ]; then
        # The command was successful
        success=true
      else
        # The command was not successful
        echo "Attempt $attempt_num failed. Trying again..."
        # Increment the attempt counter
        attempt_num=$(( attempt_num + 1 ))
	# delay
	sleep 10
      fi
    done
    
    # Check if the command was successful
    if [ $success = true ]; then
      # The command was successful
      echo "The command was successful after $attempt_num attempts."
      return 0
    else
      # The command was not successful
      echo "The command failed after $max_attempts attempts."
      return 1
    fi
}


# get the instance ip 
# $1 = vm name
get_instance_ip () {
    result=$(gcloud compute instances describe $1 --format="json(networkInterfaces[0].accessConfigs[0].natIP)")
    ip=$(echo $result | jq .networkInterfaces[0].accessConfigs[0].natIP | tr -d '"')
    echo $ip
}


# copy file to remote, and execute script
# $1 = vm name
bringup_k8s () {
    ip=$(get_instance_ip $1)
    scp -o "UserKnownHostsFile=/dev/null" k8s_pkg_install.sh shivkb@$ip:
    ssh -o "UserKnownHostsFile=/dev/null" -i ~/.ssh/shivkube_gcp shivkb@$ip ./k8s_pkg_install.sh
}

# create the VMs
# $1 = name
# $2 = project
# $3 = vm type
# $4 = service account name
# $5 = image name
create_vm () {
gcloud compute instances create $1 --project=$2 --zone=us-central1-a --machine-type=$3 --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --can-ip-forward --no-restart-on-failure --maintenance-policy=TERMINATE --provisioning-model=SPOT --instance-termination-action=STOP --service-account=$4@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=ipip-peer --create-disk=auto-delete=yes,boot=yes,device-name=$1,image=projects/ubuntu-os-cloud/global/images/$5,mode=rw,size=100,type=projects/$2/zones/us-central1-a/diskTypes/pd-standard --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any
}


###################
# Main Script
###################


# create the vms
pr=tubify-438815
sa=753257145360-compute 
im=ubuntu-minimal-2204-jammy-v20250520
echo "Creating VMs"
create_vm k8s-master tubify-438815 n1-standard-2 $sa $im
create_vm instance-1 tubify-438815 n1-standard-1 $sa $im

# check if the VMs are created
echo "Checking if VMs are created"
retry_command check_vm_creation k8s-master
retry_command check_vm_creation instance-1

# bringup k8s on the master first, and then instance 1
echo "Bringing up kubernetes on the nodes"
bringup_k8s k8s-master
bringup_k8s instance-1

# Setup the kubeconfig file
ip=$(get_instance_ip k8s-master)
scp shivkb@$ip:.kube/config /home/hima/.kube/config
yq  -i '.clusters[0].cluster.server="https://localhost:2222"' ~/.kube/config
echo "ssh -i ~/.ssh/shivkube_gcp shivkb@$ip -L 2222:localhost:6443"
