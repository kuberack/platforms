
# Install gce pd csi driver:

Ref: // https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver/blob/master/docs/kubernetes/user-guides/driver-install.md

## Steps
 - Install git, golang
 - Install the driver
   ```
   $ git clone https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver $GOPATH/src/sigs.k8s.io/gcp-compute-persistent-disk-csi-driver
   ```
 - Enable compute, cloud storage, iam for the project. Not sure if this is enough
 - Get the service account
   ```
   gcloud iam service-accounts keys create ./cloud-sa.json --iam-account 753257145360-compute@developer.gserviceaccount.com --project tubify-438815
 - Generate a yaml
   ```
   export GCE_PD_SA_DIR=/home/hima/repos/kuberack/platforms/dev/
   // Edit the deploy-driver.sh to generate the yaml file, and not to apply the yaml file
   cp $tmp_spec ./tmp.yaml
   ${KUBECTL} apply -v="${VERBOSITY}" -f $tmp_spec
   ./deploy-driver.sh --skip-sa-check
   ```
 - Above command will generate a tmp.yaml. Edit the yaml to remove the toleration.
   ```
       --       tolerations:
       --       - operator: Exists
   ```
 - Apply tmp.yaml
   ```
     $ kgp -n gce-pd-csi-driver
     NAME                                     READY   STATUS    RESTARTS   AGE
     csi-gce-pd-controller-6545bd95f7-hlznl   5/5     Running   0          26s
     csi-gce-pd-node-4wjln                    2/2     Running   0          25s
   ```

