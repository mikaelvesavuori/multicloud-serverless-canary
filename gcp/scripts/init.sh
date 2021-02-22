#!/bin/bash

# These must be set to your values!
export PROJECT_ID=""
export BILLING_ID="" # Get it at: https://console.cloud.google.com/billing (or in step below)
export REPO_NAME="canary-demo"
export RUN_SERVICE_NAME="canary-demo"
export LOCATION="europe-north1"
export DESCRIPTION="Canary deploy and release demo for Cloud Run"
export IMAGE="canary"

# Update
gcloud components update

# Create new project and set as current
gcloud projects create $PROJECT_ID
gcloud config set project $PROJECT_ID

# Get project number
gcloud projects list
export PROJECT_NUMBER="" # From above

# Enable billing
gcloud services enable cloudbilling.googleapis.com
gcloud alpha billing accounts list
gcloud alpha billing projects link $PROJECT_ID --billing-account $BILLING_ID

# Enable Google APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sourcerepo.googleapis.com
gcloud services enable artifactregistry.googleapis.com

# Create Source Repository
gcloud source repos create $REPO_NAME

# Create Artifact Registry for image
gcloud beta artifacts repositories create $REPO_NAME \
  --repository-format="docker" \
  --location=$LOCATION \
  --description="$DESCRIPTION" \
  --async

# Create a build trigger, working on the master branch
gcloud beta builds triggers create cloud-source-repositories \
  --repo $REPO_NAME \
  --branch-pattern "master" \
  --build-config "gcp/pipeline/cloudbuild.yaml"

# Set permissions for Cloud Build
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/logging.viewer

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/run.admin

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:$PROJECT_NUMBER@cloudbuild.gserviceaccount.com \
  --role=roles/iam.serviceAccountUser

# Clean git history
rm -rf .git
git init

# Remove junk you won't need (also backup package.json just in case)
cp package.json package_backup.json
sed -i '' 's/"azure-functions-core-tools": "^3.0.3284",//' package.json
sed -i '' 's/"serverless": "^2.25.2",//' package.json
sed -i '' 's/"serverless-azure-functions": "^2.1.0",//' package.json
sed -i '' 's/"serverless-offline": "^6.8.0",//' package.json
sed -i '' 's/"serverless-plugin-aws-alerts": "^1.7.1",//' package.json
sed -i '' 's/"serverless-plugin-canary-deployments": "^0.5.0"//' package.json
sed -i '' 's/"^2.2.1",/"^2.2.1"/' package.json

sed '/^[[:space:]]*$/d' package.json | sed '/^\s*$/d' | sed '/^$/d' | sed -n '/^\s*$/!p' >> _package.json

rm package.json
mv _package.json package.json

# Commit code
gcloud init && git config --global credential.https://source.developers.google.com.helper gcloud.sh
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/$REPO_NAME
git add .
git commit -m "Initial commit"
git push --all google
git push --set-upstream google master