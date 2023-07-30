export REGION=us-central1
export DATASET_SERVICE_NAME=netflix-dataset-service-449
export FE_STAGING_SVC_NAME=frontend-staging-service-294
export FE_PROD_SVC_NAME=frontend-production-service-916


gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
git clone https://github.com/rosera/pet-theory.git

### Task 1: Firestore Database Create
# Go to Firestore > Select Naive Mode > Location: nam5 > Create Database

### Task 2: Firestore Database Populate
cd pet-theory/lab06/firebase-import-csv/solution
npm install
node index.js netflix_titles_original.csv

### Task 3: Cloud Build Rest API Staging
cd ~/pet-theory/lab06/firebase-rest-api/solution-01
npm install
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1
gcloud beta run deploy $DATASET_SERVICE_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.1 --allow-unauthenticated --region $REGION
SERVICE_URL=$(gcloud beta run services describe $DATASET_SERVICE_NAME --platform managed --region $REGION --format="value(status.url)")
echo $SERVICE_URL
curl -X GET $SERVICE_URL

### Task 4: Cloud Build Rest API Production
cd ~/pet-theory/lab06/firebase-rest-api/solution-02
npm install
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2
gcloud beta run deploy $DATASET_SERVICE_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/rest-api:0.2 --allow-unauthenticated --region $REGION
SERVICE_URL=$(gcloud beta run services describe $DATASET_SERVICE_NAME --platform managed --region $REGION --format="value(status.url)")
echo $SERVICE_URL
curl -X GET $SERVICE_URL

### Task 5: Cloud Build Frontend Staging
cd ~/pet-theory/lab06/firebase-frontend/public
sed -i '4,5d' app.js
sed -i "3 i const REST_API_SERVICE = \"$SERVICE_URL/2020\"" app.js
npm install
cd ~/pet-theory/lab06/firebase-frontend
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1
gcloud beta run deploy $FE_STAGING_SVC_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-staging:0.1 --allow-unauthenticated --region $REGION

### Task 6: Cloud Build Frontend Production
gcloud builds submit --tag gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1
gcloud beta run deploy $FE_PROD_SVC_NAME --image gcr.io/$GOOGLE_CLOUD_PROJECT/frontend-production:0.1 --allow-unauthenticated --region $REGION
