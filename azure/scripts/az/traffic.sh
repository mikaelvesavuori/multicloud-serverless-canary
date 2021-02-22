#!/usr/bin/env bash

# See: https://docs.microsoft.com/en-us/cli/azure/webapp/traffic-routing

RG_NAME="" # Resource group name
APP_NAME="" # Function app name
SLOT_NAME="canary" # Secondary (canary) deployment slot name

# Clear the routing rules and send all traffic to production.
az webapp traffic-routing clear --resource-group $RG_NAME --name $APP_NAME

# Configure routing traffic to deployment slots.
az webapp traffic-routing set --distribution $SLOT_NAME=10 --resource-group $RG_NAME --name $APP_NAME

# Display the current distribution of traffic across slots.
az webapp traffic-routing show --resource-group $RG_NAME --name $APP_NAME