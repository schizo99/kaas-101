# Prerequisites
 * gcloud - [gcloud sdk](https://cloud.google.com/sdk/)

We'll be using istio to expose our application

# Deploy stand alone application

```bash
kubectl apply -f deployment.yml
```

# Set ingress ip & ports

export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].port}')

# Enable auto injection of istio sidecars
Besides the Deployment and Service we need 2 more components in order to expose our application to the consumers.

*Gateway* acts as a load balancer which handling requests and their response.

*VirtualService* which is bound to a gateway to controls forwarding of the request that comes to the gateway.

```bash
# Enable istio-sidecar auto injection on the namespace you deploy your app in.
kubectl label namespace default istio-injection=enabled
```

Traffic flow.

Request -> Istio Ingress Gateway -> Gateway -> Virtual Service -> Service -> Pod

```bash
kubectl apply -f deployment_ingress.yml
```


# Deployment with 2 versions requires a Destination Rule to identify the deployments.
*DestinationRule* defines the routing policies.

```bash
kubectl apply -f deployment_ingress_multiple_versions.yml
```

# Enable SSL termination for endpoints

### Generate a certificate

```bash
cat << EOF > tls.template
[ req ]
default_bits = 2048
default_md = sha256
distinguished_name = req_distinguished_name
prompt = no
string_mask = nombstr
req_extensions = v3_req
[ req_distinguished_name ]
countryName = SE
stateOrProvinceName = Smaland
localityName = Elmhult
organizationName = IKEA
organizationalUnitName = IT
commonName = testapp.$INGRESS_HOST.xip.io
[ v3_req ]
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOF

openssl req -new -config tls.template -batch -newkey rsa:2048 -keyout tls.key -nodes -out tls.csr
openssl x509 -req -days 365 -in tls.csr -signkey tls.key -out tls.crt
```


### Create a secret containing the key and certificate
```bash
kubectl create -n istio-system secret tls istio-ingressgateway-certs --key tls.key --cert tls.crt
```

### Update the gateway for https traffic instead of http
```bash
kubectl apply -f -<<EOF 
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: testapp-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
    hosts:
    - "testapp.$INGRESS_HOST.xip.io"
EOF
```
