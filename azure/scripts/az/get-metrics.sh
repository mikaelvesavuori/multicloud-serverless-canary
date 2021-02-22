#!/bin/bash

# Set timezone to what is used in Azure
export TZ=":Europe/London" date

SUB_ID="" # Azure subscription ID
RG_NAME="" # Resource group name
APP_NAME="" # Function app name

# Mac
START_TIME=$(date -v-10M +%FT%T+00:00)
END_TIME=$(date '+%FT%T+00:00')

# Linux
#START_TIME=$(date -d '-3 minutes' '+%FT%T+00:00') # Linux
#END_TIME=$(date '+%FT%T+00:00') # Linux

echo $START_TIME
echo $END_TIME

rm -f errors.txt
rm -f logs.txt
rm -f fixed_errors.txt

az monitor metrics list \
  --resource /subscriptions/$SUB_ID/resourceGroups/$RG_NAME/providers/Microsoft.Web/sites/$APP_NAME \
  --metric "Http5xx" \
  --interval "PT1M" \
  --start-time $START_TIME \
  --end-time $END_TIME >> logs.txt

# Get errors from logs
jq '.value[0].timeseries[0].data[] | .total' logs.txt >> errors.txt
# Remove zeroes
sed -i '' 's/0//gi' errors.txt
# Remove empty lines
sed '/^[[:space:]]*$/d' errors.txt | sed '/^\s*$/d' | sed '/^$/d' | sed -n '/^\s*$/!p' >> fixed_errors.txt

if (test $(wc -l < fixed_errors.txt) -gt 0); then
  echo "Found errors"
  cat fixed_errors.txt

  echo "Rolling back traffic to 0 percent..."
  az webapp traffic-routing clear --resource-group $RG_NAME --name $APP_NAME

  echo "Exiting..."
  exit 1
else
  echo "No errors"
fi