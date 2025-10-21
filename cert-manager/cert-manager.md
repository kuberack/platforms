
# Install nginx-ingress and cert-manager
Ref: https://cert-manager.io/docs/tutorials/acme/nginx-ingress/
 - Add the helm repo
   ```
   $ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   ```
 - Update the repo
   ```
   $ helm repo update
   ```
 - Install an nginx-controller
   ```
   $ helm install quickstart ingress-nginx/ingress-nginx
   NAME: quickstart
   ... lots of output ...
   ```
 - Verify that the controller is up
   ```
   $ kubectl get svc
   NAME                                            TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
   ...
   quickstart-ingress-nginx-controller             LoadBalancer   10.107.132.69   34.58.216.38   80:32534/TCP,443:30374/TCP   13m
   quickstart-ingress-nginx-controller-admission   ClusterIP      10.104.243.97   <none>         443/TCP                      13m
   ```
 - Add two lines to the config map of the ingress controller to disable 
   strict-validate-path-type. This is needed because the HTTP challenge 
   verification fails otherwise.
   ```
   $ kubectl edit cm quickstart-ingress-nginx-controller
     data:
       strict-validate-path-type: "false"
   $ kubectl rollout restart deployment quickstart-ingress-nginx-controller
   ```
 - Add the dns entry for the load balancer ip address 
   ![dns-ip](https://github.com/kuberack/platforms/blob/main/cert-manager/dns-ip.png  "dns ip entry")

 - Install kuard
   ```
   kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/deployment.yaml
   kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/service.yaml
   ```
 - Setup the cert-manager
   ```
   helm repo add jetstack https://charts.jetstack.io --force-update
   helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --create-namespace \
     --version v1.18.0 \
     --set crds.enabled=true
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
     quickstart-example-tls   True    quickstart-example-tls   28s
   ```
 - Check that the tls secret is created
   ```
     $ kg secret
     NAME                    TYPE                 DATA   AGE
     quickstart-example-tls  kubernetes.io/tls    2      49s
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

