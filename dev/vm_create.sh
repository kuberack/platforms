#!/bin/bash

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
    scp k8s_pkg_install.sh shivkb@$ip:
    ssh -i ~/.ssh/shivkube_gcp shivkb@$ip ./k8s_pkg_install.sh
}

# create the VMs
# $1 = name
# $2 = vm type
create_vm () {
    gcloud compute instances create $1 --project=virtual-lab-1 --zone=us-central1-a --machine-type=$2 --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --can-ip-forward --no-restart-on-failure --maintenance-policy=TERMINATE --provisioning-model=SPOT --instance-termination-action=STOP --service-account=228483067154-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=ipip-peer --create-disk=auto-delete=yes,boot=yes,device-name=k8s-master,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230727,mode=rw,size=100,type=projects/virtual-lab-1/zones/us-central1-a/diskTypes/pd-standard --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any
}


###################
# Main Script
###################


# create the vms
echo "Creating VMs"
create_vm k8s-master n1-standard-2
create_vm instance-1 n1-standard-1

# check if the VMs are created
echo "Checking if VMs are created"
retry_command check_vm_creation k8s-master
retry_command check_vm_creation instance-1

# bringup k8s on the master first, and then instance 1
echo "Bringing up kubernetes on the nodes"
bringup_k8s k8s-master
bringup_k8s instance-1

