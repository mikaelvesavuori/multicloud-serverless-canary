#!/usr/bin/env bash

# Azure core variables
export TENANT_ID=""
export SUB_ID=""
export SUB_NAME=""

# General Azure
export STORAGE_ACCOUNT="canarydemo${RANDOM}"
export PLAN_NAME="canary-demo-plan"
export RG="canary-demo"
export LOCATION="westeurope"

# Azure DevOps
export ORG_NAME="your-org-name"
export DEVOPS_PROJECT="canary-demo"
export DEVOPS_REPO_NAME="canary-demo"
export GIT_ORIGIN="https://$ORG_NAME@dev.azure.com/$ORG_NAME/$DEVOPS_PROJECT/_git/$DEVOPS_REPO_NAME"
export DEVOPS_ORG="https://dev.azure.com/$ORG_NAME/"
export DEVOPS_PIPELINE_NAME="CanaryPipeline"
export DEVOPS_PIPELINE_DESC="Pipeline for canary deployment demo"
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="some-really-long-key-here"
export SRV_CONN_NAME="service-connection-arm-pipeline"

# Function app
export APP_NAME="canary-demo"
export OS="Windows"
export RUNTIME="node"

# API Management
export SECONDARY_SLOT="canary"
export API_ID="CanaryDemoApi"
export API_DISPLAY_NAME="Canary Demo API"
export API_SERVICE_NAME="canary-demo-${RANDOM}"
export API_DESC="API for canary demo"
export API_PLAN="Standard" # 'Standard' for deployment slots with traffic shifting; 'Consumption' if you are OK without traffic shifting
export PUBLISHER_EMAIL="youremail@someexamplehere.net"
export PUBLISHER_NAME="YourName"

###################
#      Group      #
###################

# Create resource group
az group create --location $LOCATION --name $RG

####################
# App Service Plan #
####################

az appservice plan create \
  --name $PLAN_NAME \
  --resource-group $RG \
  --location $LOCATION \
  --sku S1
# B1, B2, B3, D1, F1, FREE, I1, I1v2, I2, I2v2, I3, I3v2, P1V2, P1V3, P2V2, P2V3, P3V2, P3V3, PC2, PC3, PC4, S1, S2, S3, SHARED

###################
#     Storage     #
###################

# Create storage account for application
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RG \
  --access-tier Hot \
  --allow-blob-public-access false \
  --sku Standard_LRS \
  --https-only \
  --location $LOCATION \
  --min-tls-version TLS1_2 \
  --kind StorageV2

###################
#    Functions    #
###################

# Create function app
az functionapp create \
  --name $APP_NAME \
  --resource-group $RG \
  --plan $PLAN_NAME \
  --os-type $OS \
  --runtime $RUNTIME \
  --runtime-version 12 \
  --storage-account $STORAGE_ACCOUNT \
  --disable-app-insights false \
  --functions-version 3
#--consumption-plan-location $LOCATION \

# Set function app to only use HTTPS
az functionapp update \
  --name $APP_NAME \
  --resource-group $RG \
  --set httpsOnly=true

# Secure function app
az functionapp config set \
  --name $APP_NAME \
  --resource-group $RG \
  --ftps-state Disabled \
  --http20-enabled true \
  --min-tls-version 1.2 \
  --use-32bit-worker-process false

# Create staging deployment slot for function app
az functionapp deployment slot create \
  --resource-group $RG \
  --name $APP_NAME \
  --slot $SECONDARY_SLOT

###################
# API Management  #
###################

# Create API Management service instance
az apim create \
  --resource-group $RG \
  --location $LOCATION \
  --name $API_SERVICE_NAME \
  --sku-name $API_PLAN \
  --publisher-email $PUBLISHER_EMAIL \
  --publisher-name $PUBLISHER_NAME
#--no-wait

# Create API on the service instance
az apim api create \
  --resource-group $RG \
  --api-id $API_ID \
  --display-name $API_DISPLAY_NAME \
  --service-name $API_SERVICE_NAME \
  --path '/' \
  --api-type http \
  --description $API_DESC

# Set function to be run from compiled ZIP package during deployment
az functionapp config appsettings set \
  --resource-group $RG \
  --settings "WEBSITE_RUN_FROM_PACKAGE=1" \
  --name $APP_NAME

az functionapp config appsettings set \
  --resource-group $RG \
  --slot $SECONDARY_SLOT \
  --slot-settings "WEBSITE_RUN_FROM_PACKAGE=1" \
  --name $APP_NAME

###################
#      DevOps     #
###################

# Create DevOps project
az devops project create --name $DEVOPS_PROJECT --organization $DEVOPS_ORG

# Create repo
az repos create --name $DEVOPS_REPO_NAME -p $DEVOPS_PROJECT --org $DEVOPS_ORG

# Create (automatic Azure Resource Manager) service connection
# See: https://docs.microsoft.com/en-us/azure/devops/cli/service-endpoint?view=azure-devops#use-a-client-secretpassword
# This part I never got to work; If you're smarter than me, go ahead and fix it :9

#az devops service-endpoint azurerm create \
#  --name $SRV_CONN_NAME \
#  --azure-rm-tenant-id $TENANT_ID \
#  --azure-rm-service-principal-id $SRV_CONN_NAME \
#  --azure-rm-subscription-id $SUB_ID \
#  --azure-rm-subscription-name $SUB_NAME

# Create pipeline
az pipelines create \
  --name $DEVOPS_PIPELINE_NAME \
  --description $DEVOPS_PIPELINE_DESC \
  --repository $DEVOPS_REPO_NAME \
  --branch master \
  --repository-type tfsgit \
  --yml-path azure/pipeline/pipeline.yml

# Push code (HTTPS)
git remote add origin $GIT_ORIGIN
git push -u origin --all

# Push code (SSH)
# git remote add origin git@ssh.dev.azure.com:v3/mikael-vesavuori/canary-demo/canary-demo
# git push -u origin --all

echo "You may need to manually authorize the service connection in the DevOps pipeline"
echo "You will also need to manually create a service connection (Azure RM, 'automatic') called 'service-connection-arm-pipeline'"