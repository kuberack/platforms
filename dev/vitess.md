
Install gce pd csi driver:
==========================
  - Ref: // https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver/blob/master/docs/kubernetes/user-guides/driver-install.md
   - install git, golang
   - $ git clone https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver $GOPATH/src/sigs.k8s.io/gcp-compute-persistent-disk-csi-driver
   - compute, cloud storage, iam for the project. Not sure if this is
     enough
   - gcloud iam service-accounts keys create ./cloud-sa.json --iam-account 753257145360-compute@developer.gserviceaccount.com --project tubify-438815
   - Edit the deploy-driver.sh to generate the yaml file, and not to
     apply the yaml file
       cp $tmp_spec ./tmp.yaml
       # ${KUBECTL} apply -v="${VERBOSITY}" -f $tmp_spec
   - ./deploy-driver.sh --skip-sa-check
   - THis will generate a tmp.yaml. Edit the yaml to remove the 
     toleration.
       --       tolerations:
       --       - operator: Exists


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

