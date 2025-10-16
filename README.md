# platforms
Contains scripts, manifests to setup a generic k8s based platform. This platform consists of a base k8s cluster and other extensions, controllers for proxies, identity, persistent storage, databases and observability. Applications such as [taxify](https://github.com/kuberack/taxify) can use this generic platform.

 - [Setup base k8s and controller manager](k8s/k8s.md)
 - [Setup ingress and cert-manager](cert-manager/cert-manager.md)
 - [Setup the OAuth2 proxy](oauth2-proxy/oauth2.md)
 - [Setup the gce pd CSI driver](gce-pd-csi/gce-pd.md)
 - [WIP - Setup vitess](vitess/vitess.md)
 - [WIP - Use cluster API to setup k8s cluster](capi/capi.md)
 - TODO - CD (Argo), configuration and secrets, observability

