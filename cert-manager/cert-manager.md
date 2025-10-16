
# Install nginx-ingress and cert-manager
Ref: https://cert-manager.io/docs/tutorials/acme/nginx-ingress/
 - $ helm install quickstart ingress-nginx/ingress-nginx
   NAME: quickstart
   ... lots of output ...
 - Modify the config map of the ingress controller to disable 
   strict-validate-path-type. This is needed because the HTTP
   challenge verification fails otherwise.
   ```
   $ kubectl edit cm quickstart-ingress-nginx-controller
     data:
     strict-validate-path-type: "false"
   $ k rollout restart deployment quickstart-ingress-nginx-controller
   ```
 - Add the dns entry for the load balancer ip address 
 - Install kuard
   ```
   kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/deployment.yaml
   kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/service.yaml
   ```
 - Setup the cert-manager
   ```
   helm repo add jetstack https://charts.jetstack.io --force-update
   helm install cert-manager jetstack/cert-manager
     --namespace cert-manager
     --create-namespace
     --version v1.18.0
     --set crds.enabled=true
   kubectl apply -f cert-manager-issuer-staging.yaml 
   kubectl apply -f cert-manager-issuer-prod.yaml 
   ```
 - Create the ingress resource
   ```
   kubectl apply -f kuard-ingress.yaml // this uses the prod issuer
   ```
 - Check that the certificate is created
   ```
     $ kg certificate
     NAME                     READY   SECRET                   AGE
     quickstart-example-tls   True    quickstart-example-tls   24m
   ```
 - Check that the tls secret is created
   ```
     $ kg secret
     NAME                    TYPE                 DATA   AGE
     quickstart-example-tls  kubernetes.io/tls    2      19m
   ```
 - Check that you are able to access https://example.kuberack.net


# Deleting GCP load balancers
|Object | Command |
|-------|---------|
|Forwarding Rule | gcloud compute forwarding-rules delete [FORWARDING_RULE] |
|Target Proxy | gcloud compute target-${PROTOCOL}-proxies delete [TARGET_PROXY] |
|URL Map | gcloud compute url-maps delete [URL_MAP] |
|Backend Service | gcloud compute backend-services delete [BACKEND_SERVICE] |
|Health Check | gcloud compute health-checks delete [HEALTH_CHECK] |
|Static IP | gcloud compute addresses delete [IP_ADDRESS] |

