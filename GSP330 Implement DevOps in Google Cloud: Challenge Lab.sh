#!/bin/bash

### Task 1
export PROJECT_ID=qwiklabs-gcp-00-fec9c00bb3ff
export CLUSTER_NAME=hello-cluster
export ZONE=us-central1-a
export REGION=us-central1
export REPO=sample-app

gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    sourcerepo.googleapis.com

export PROJECT_ID=$(gcloud config get-value project)
gcloud projects add-iam-policy-binding $PROJECT_ID \
--member=serviceAccount:$(gcloud projects describe $PROJECT_ID \
--format="value(projectNumber)")@cloudbuild.gserviceaccount.com --role="roles/container.developer"

git config --global user.email sample@gmail.com
git config --global user.name sample-user

gcloud artifacts repositories create $REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="Subscribe to quicklab"


gcloud beta container --project "$PROJECT_ID" clusters create "$CLUSTER_NAME" --zone "$ZONE" --no-enable-basic-auth --cluster-version latest --release-channel "regular" --machine-type "e2-medium" --image-type "COS_CONTAINERD" --disk-type "pd-balanced" --disk-size "100" --metadata disable-legacy-endpoints=true  --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/$PROJECT_ID/global/networks/default" --subnetwork "projects/$PROJECT_ID/regions/$REGION/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --enable-autoscaling --min-nodes "2" --max-nodes "6" --location-policy "BALANCED" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes --node-locations "$ZONE"

kubectl create namespace prod

kubectl create namespace dev


### Task 2
gcloud source repos create sample-app

git clone https://source.developers.google.com/p/$PROJECT_ID/r/sample-app


cd ~
gsutil cp -r gs://spls/gsp330/sample-app/* sample-app

git init
cd sample-app/
git add .
git commit -m "Subscribe to quicklab"
git push -u origin master

git branch dev
git checkout dev
git push -u origin dev


# Task 4
COMMIT_ID="$(git rev-parse --short=7 HEAD)"
gcloud builds submit --tag="${REGION}-docker.pkg.dev/${PROJECT_ID}/$REPO/hello-cloudbuild:${COMMIT_ID}" .

sed -i "s/<version>/v1.0/g" cloudbuild-dev.yaml
sed -i "s/my-repository/$REPO/g" cloudbuild-dev.yaml
sed -i "s/<todo>/${REGION}-docker.pkg.dev\/${PROJECT_ID}\/$REPO\/hello-cloudbuild:${COMMIT_ID}/g" dev/deployment.yaml
git add .
git commit -m "Subscribe to quicklab"
git push -u origin dev

git checkout master
sed -i "s/<version>/v1.0/g" cloudbuild.yaml
sed -i "s/my-repository/$REPO/g" cloudbuild.yaml
sed -i "s/<todo>/${REGION}-docker.pkg.dev\/${PROJECT_ID}\/$REPO\/hello-cloudbuild:${COMMIT_ID}/g" dev/deployment.yaml
git add .
git commit -m "Subscribe to quicklab"
git push -u origin master

### Task 5
git checkout dev

cat << EOF > main.go
/**
 * Copyright 2023 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
        "image"
        "image/color"
        "image/draw"
        "image/png"
        "net/http"
)

func main() {
        http.HandleFunc("/blue", blueHandler)
        http.HandleFunc("/red", redHandler)
        http.ListenAndServe(":8080", nil)
}

func redHandler(w http.ResponseWriter, r *http.Request) {
        img := image.NewRGBA(image.Rect(0, 0, 100, 100))
        draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{255, 0, 0, 255}}, image.ZP, draw.Src)
        w.Header().Set("Content-Type", "image/png")
        png.Encode(w, img)
}

func blueHandler(w http.ResponseWriter, r *http.Request) {
        img := image.NewRGBA(image.Rect(0, 0, 100, 100))
        draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{0, 0, 255, 255}}, image.ZP, draw.Src)
        w.Header().Set("Content-Type", "image/png")
        png.Encode(w, img)
}
EOF

sed -i "s/v1.0/v2.0/g" cloudbuild-dev.yaml
git add .
git commit -m "Subscribe to quicklab"
git push -u origin dev

git checkout master

cat << EOF > main.go
/**
 * Copyright 2023 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
        "image"
        "image/color"
        "image/draw"
        "image/png"
        "net/http"
)

func main() {
        http.HandleFunc("/blue", blueHandler)
        http.HandleFunc("/red", redHandler)
        http.ListenAndServe(":8080", nil)
}

func redHandler(w http.ResponseWriter, r *http.Request) {
        img := image.NewRGBA(image.Rect(0, 0, 100, 100))
        draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{255, 0, 0, 255}}, image.ZP, draw.Src)
        w.Header().Set("Content-Type", "image/png")
        png.Encode(w, img)
}

func blueHandler(w http.ResponseWriter, r *http.Request) {
        img := image.NewRGBA(image.Rect(0, 0, 100, 100))
        draw.Draw(img, img.Bounds(), &image.Uniform{color.RGBA{0, 0, 255, 255}}, image.ZP, draw.Src)
        w.Header().Set("Content-Type", "image/png")
        png.Encode(w, img)
}
EOF

sed -i "s/v1.0/v2.0/g" cloudbuild.yaml
git add .
git commit -m "Subscribe to quicklab"
git push -u origin master
