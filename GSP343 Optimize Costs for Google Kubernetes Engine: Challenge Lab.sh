#!/bin/bash

### Task 1
export CLUSTER_NAME=onlineboutique-cluster-399
export POOL_NAME=optimized-pool-9393
export MAX_REPLICA=10
export ZONE=us-central1-b
export REGION=us-central1

gcloud container clusters create $CLUSTER_NAME \
   --project=${DEVSHELL_PROJECT_ID} --zone=${ZONE} \
   --machine-type=n1-standard-2 --num-nodes=2

kubectl create namespace dev
kubectl create namespace prod

kubectl config set-context --current --namespace dev

git clone https://github.com/GoogleCloudPlatform/microservices-demo.git
cd microservices-demo
kubectl apply -f ./release/kubernetes-manifests.yaml --namespace dev

kubectl get svc -w --namespace dev

### Task 2
gcloud container node-pools create $POOL_NAME \
   --cluster=$CLUSTER_NAME \
   --machine-type=custom-2-3584 \
   --num-nodes=2 \
   --zone=$ZONE

for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
   kubectl cordon "$node";
done

for node in $(kubectl get nodes -l cloud.google.com/gke-nodepool=default-pool -o=name); do
   kubectl drain --force --ignore-daemonsets --delete-local-data --grace-period=10 "$node";
done

kubectl get pods -o=wide --namespace dev

gcloud container node-pools delete default-pool \
   --cluster $CLUSTER_NAME --zone $ZONE

### Task 3

kubectl create poddisruptionbudget onlineboutique-frontend-pdb \
--selector app=frontend --min-available 1  --namespace dev

KUBE_EDITOR="nano" kubectl edit deployment/frontend --namespace dev

### Task 4

kubectl autoscale deployment frontend --cpu-percent=50 \
   --min=1 --max=$MAX_REPLICA --namespace dev

kubectl get hpa --namespace dev

gcloud beta container clusters update $CLUSTER_NAME \
   --enable-autoscaling --min-nodes 1 --max-nodes 6 --zone $ZONE

kubectl exec $(kubectl get pod --namespace=dev | grep 'loadgenerator' | cut -f1 -d ' ') \
   -it --namespace=dev -- bash -c "export USERS=8000; sh ./loadgen.sh"
