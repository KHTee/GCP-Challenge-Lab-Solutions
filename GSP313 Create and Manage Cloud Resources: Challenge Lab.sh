export INSTANCE_NAME=nucleus-jumphost-562
export APP_PORT=8082
export FIREWALL_RULE=permit-tcp-rule-541
export ZONE=us-west3-a
export REGION=us-west3

### Task 1: Create a project jumphost instance
gcloud compute instances create $INSTANCE_NAME \
          --network nucleus-vpc \
          --zone $ZONE  \
          --machine-type e2-micro  \
          --image-family debian-11  \
          --image-project debian-cloud \
          --scopes cloud-platform \
          --no-address

          
### Task 2: Create a Kubernetes service cluster
gcloud container clusters create nucleus-backend \
          --num-nodes 1 \
          --network nucleus-vpc \
          --region $REGION
gcloud container clusters get-credentials nucleus-backend \
          --region $REGION

kubectl create deployment hello-server \
          --image=gcr.io/google-samples/hello-app:2.0

kubectl expose deployment hello-server \
          --type=LoadBalancer \
          --port $APP_PORT

### Task 3: Set up an HTTP load balancer
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF


gcloud compute instance-templates create web-server-template \
          --metadata-from-file startup-script=startup.sh \
          --network nucleus-vpc \
          --machine-type g1-small \
          --region $REGION


gcloud compute instance-groups managed create web-server-group \
          --base-instance-name web-server \
          --size 2 \
          --template web-server-template \
          --region $REGION


gcloud compute firewall-rules create $FIREWALL_RULE \
          --allow tcp:80 \
          --network nucleus-vpc
          
          
gcloud compute http-health-checks create http-basic-check

gcloud compute instance-groups managed \
          set-named-ports web-server-group \
          --named-ports http:80 \
          --region $REGION


gcloud compute backend-services create web-server-backend \
          --protocol HTTP \
          --http-health-checks http-basic-check \
          --global
          
gcloud compute backend-services add-backend web-server-backend \
          --instance-group web-server-group \
          --instance-group-region $REGION \
          --global


gcloud compute url-maps create web-server-map \
          --default-service web-server-backend
          
gcloud compute target-http-proxies create http-lb-proxy \
          --url-map web-server-map


gcloud compute forwarding-rules create http-content-rule \
        --global \
        --target-http-proxy http-lb-proxy \
        --ports 80
        
gcloud compute forwarding-rules list
