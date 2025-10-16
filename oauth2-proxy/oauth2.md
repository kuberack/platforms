
# Install OAuth2 proxy
 - Ref: https://kubernetes.github.io/ingress-nginx/examples/auth/oauth-external-auth/
 - kubectl apply -f kuard_ingress.yaml // kuard_ingress is modified to redirect to oauth endpoints. Also ingress rule is modified to be exact
 - kubectl apply -f oauth2-proxy-modified.yaml // contains the oauth proxy with changes for client_id, client_secret

