
Install nginx-ingress and cert-manager
======================================
Ref: https://cert-manager.io/docs/tutorials/acme/nginx-ingress/
 - $ helm install quickstart ingress-nginx/ingress-nginx
   NAME: quickstart
   ... lots of output ...
 - Modify the config map of the ingress controller to disable 
   strict-validate-path-type. This is needed because the HTTP
   challenge verification fails otherwise.
   $ kubectl edit cm quickstart-ingress-nginx-controller
   data:
     strict-validate-path-type: "false"
   $ k rollout restart deployment quickstart-ingress-nginx-controller
 - Add the dns entry for the load balancer ip address 
 - Install kuard
   kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/deployment.yaml
   kubectl apply -f https://raw.githubusercontent.com/cert-manager/website/master/content/docs/tutorials/acme/example/service.yaml
 - helm repo add jetstack https://charts.jetstack.io --force-update
 - helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.18.0 \
  --set crds.enabled=true
 - kubectl apply -f cert-manager-issuer-staging.yaml 
   kubectl apply -f cert-manager-issuer-prod.yaml 
 - Create the ingress resource
   kubectl apply -f kuard-ingress.yaml // this uses the prod issuer
   Check that the certificate is created
     $ kg certificate
     NAME                     READY   SECRET                   AGE
     quickstart-example-tls   True    quickstart-example-tls   24m
   Check that the tls secret is created
     $ kg secret
     NAME                    TYPE                 DATA   AGE
     quickstart-example-tls  kubernetes.io/tls    2      19m
 - Check that you are able to access https://example.kuberack.net


Deleting GCP load balancers
===========================
Forwarding Rule	gcloud compute forwarding-rules delete [FORWARDING_RULE]
Target Proxy	gcloud compute target-${PROTOCOL}-proxies delete [TARGET_PROXY]
URL Map	gcloud compute url-maps delete [URL_MAP]
Backend Service	gcloud compute backend-services delete [BACKEND_SERVICE]
Health Check	gcloud compute health-checks delete [HEALTH_CHECK]
Static IP	gcloud compute addresses delete [IP_ADDRESS]

Install OAuth2 proxy
====================
 - Ref: https://kubernetes.github.io/ingress-nginx/examples/auth/oauth-external-auth/
 - kubectl apply -f kuard_ingress.yaml // kuard_ingress is modified to redirect to oauth endpoints. Also ingress rule is modified to be exact
 - kubectl apply -f oauth2-proxy-modified.yaml // contains the oauth proxy with changes for client_id, client_secret

Install gce pd csi driver:
==========================
  - Ref: // https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver/blob/master/docs/kubernetes/user-guides/driver-install.md
   - install git, golang
   - $ git clone https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver $GOPATH/src/sigs.k8s.io/gcp-compute-persistent-disk-csi-driver
   - compute, cloud storage, iam for the project. Not sure if this is
     enough
   - gcloud iam service-accounts keys create ./cloud-sa.json --iam-account 753257145360-compute@developer.gserviceaccount.com --project tubify-438815
   - export GCE_PD_SA_DIR=/home/hima/repos/kuberack/platforms/dev/
   - Edit the deploy-driver.sh to generate the yaml file, and not to
     apply the yaml file
       cp $tmp_spec ./tmp.yaml
       # ${KUBECTL} apply -v="${VERBOSITY}" -f $tmp_spec
   - ./deploy-driver.sh --skip-sa-check
   - THis will generate a tmp.yaml. Edit the yaml to remove the 
     toleration.
       --       tolerations:
       --       - operator: Exists
   - Apply tmp.yaml
     $ kgp -n gce-pd-csi-driver
     NAME                                     READY   STATUS    RESTARTS   AGE
     csi-gce-pd-controller-6545bd95f7-hlznl   5/5     Running   0          26s
     csi-gce-pd-node-4wjln                    2/2     Running   0          25s


Install Vitesse Operator
========================
 - Ref: https://vitess.io/docs/22.0/get-started/operator/
        https://github.com/planetscale/vitess-operator/blob/main/docs/gcp-quickstart.md
 - create a ns example
 - storage class
   - create a storage class using gce-pd.yaml
 - operator.yaml
   - Add the storage class to the volumeClaimTemplate
   - 101...yaml

ClusterAPI
==========
 - Ref 1: https://cluster-api.sigs.k8s.io/user/quick-start-operator
   Ref 2: https://cluster-api-gcp.sigs.k8s.io/quick-start
   Ref 3: https://cluster-api-gcp.sigs.k8s.io/prerequisites

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




Taxi booking app
================
Instant Cab Booking
 - Users can book a taxi instantly by entering pickup and drop-off locations.
 - Drivers receive immediate notifications, reducing idle time and unnecessary driving around the city.

Scheduled Rides
 - Riders can schedule rides in advance for future times, ensuring availability and convenience.

Real-Time Tracking
 - Both riders and drivers can track each other’s real-time location using integrated maps, reducing wait times and improving safety.

Automated Dispatch System
 - The app automatically assigns the nearest available driver to a rider, optimizing efficiency and reducing response time.

Dynamic Pricing
 - Fares adjust automatically based on demand, traffic, weather, and special events, ensuring fairness and maximizing revenue.

Multiple Payment Options
 - Supports cash, card, digital wallets, and corporate billing for flexible payment solutions.

Driver-Rider Matching
 - AI matches riders with drivers based on proximity, ratings, preferences, and other factors, improving satisfaction and reducing cancellations.

Route Optimization
 - AI-powered navigation suggests the fastest and most fuel-efficient routes using live traffic data and historical patterns.

SOS/Emergency Features
 - Emergency call features connect users to local authorities or support, enhancing safety.

Ratings and Reviews
 - Both riders and drivers can rate each other, fostering accountability and trust within the platform.

Personalized Offers and Discounts
 - Based on user data, the app can suggest tailored promotions or discounts to encourage repeat usage.

Analytics and Reporting
 - Admins can access detailed reports on bookings, cancellations, payments, and user activity to make informed business decisions.

Corporate/Business Accounts
 - Dedicated dashboards for businesses enable seamless taxi bookings for employees and expense management.

AI Chatbots and Customer Support
 - AI-powered chatbots provide instant responses, help manage bookings, and resolve queries efficiently.

Fraud Detection and Security
 - AI monitors for suspicious activities, unusual routes, or fake accounts, improving security and compliance.

