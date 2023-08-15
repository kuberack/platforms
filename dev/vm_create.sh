#!/bin/bash

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
    declare n=$(echo $result | jq .name)
    # declare s=$(echo $result | jq .status)
    
    if [ $n != '$1' ]
    then
      echo "Could not find VM"
      return 1
    fi
    
    echo $n
    
    if [ $s != '"Running"' ]
    then
      echo "VM is not running"
      return 1
    fi
    
    echo "VM is running"
    return 0
}

# create the master VM
gcloud compute instances create k8s-master --project=virtual-lab-1 --zone=us-central1-a --machine-type=n1-standard-2 --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --can-ip-forward --no-restart-on-failure --maintenance-policy=TERMINATE --provisioning-model=SPOT --instance-termination-action=STOP --service-account=228483067154-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=ipip-peer --create-disk=auto-delete=yes,boot=yes,device-name=k8s-master,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230727,mode=rw,size=100,type=projects/virtual-lab-1/zones/us-central1-a/diskTypes/pd-standard --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

# create the worker VM
gcloud compute instances create instance-1 --project=virtual-lab-1 --zone=us-central1-a --machine-type=n1-standard-1 --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default --can-ip-forward --no-restart-on-failure --maintenance-policy=TERMINATE --provisioning-model=SPOT --instance-termination-action=STOP --service-account=228483067154-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=ipip-peer --create-disk=auto-delete=yes,boot=yes,device-name=k8s-master,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230727,mode=rw,size=100,type=projects/virtual-lab-1/zones/us-central1-a/diskTypes/pd-standard --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --labels=goog-ec-src=vm_add-gcloud --reservation-affinity=any

# check if the VMs are created
check_vm_creation "k8s-master"
check_vm_creation "instance-1"

