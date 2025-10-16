
# ClusterAPI

## Refs
 - Ref 1: https://cluster-api.sigs.k8s.io/user/quick-start-operator
 - Ref 2: https://cluster-api-gcp.sigs.k8s.io/quick-start
 - Ref 3: https://cluster-api-gcp.sigs.k8s.io/prerequisites

## Steps
 - Service Account needs Editor permission
 - Generate a JSON Key for service account and store it 
 - [1] Add CAPI operator, and cert manager repository
   - helm repo add capi-operator https://kubernetes-sigs.github.io/cluster-api-operator
   - helm repo add jetstack https://charts.jetstack.io --force-update
   - helm repo update
 - [1] Install cert manager
   - helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
 - [1] Deploy cluster API components with docker provider
   - helm install capi-operator capi-operator/cluster-api-operator --create-namespace -n capi-operator-system --set infrastructure.gcp.enabled=true --set cert-manager.enabled=true --set configSecret.name=${CREDENTIALS_SECRET_NAME} --set configSecret.namespace=${CREDENTIALS_SECRET_NAMESPACE}  --wait --timeout 90s

 - [2] kubectl apply -f capg.yaml

 - [2] Install the clusterctl binary

