#!/bin/bash

# Required .env variables:
# - PROJECT_ID
# - PROJECT_NAME
# - BILLING_ACCOUNT

set -euo pipefail

# Check if necessary variables are set.
if [ -z "${PROJECT_ID}" ]; then 
  echo "PROJECT_ID variable not set.";
  exit 1
elif [ -z ${PROJECT_NAME} ]; then
  echo "PROJECT_NAME variable not set.";
  exit 1
elif [ -z ${BILLING_ACCOUNT} ]; then
  echo "BILLING_ACCOUNT variable not set.";
  exit 1
fi

# Load variables from .env
source .env

# Check if the project exists
EXISTING_PROJECT=$(gcloud projects list --format="value(projectId)" --filter="projectId:${PROJECT_ID}")

if [[ -z "$EXISTING_PROJECT" ]]; then
  echo "Project ${PROJECT_ID} does not exist. Creating a new project..."
  # Create a new project
  gcloud projects create ${PROJECT_ID} --name=$PROJECT_NAME

  # Set the project as the default
  gcloud config set project ${PROJECT_ID}
  
  echo "New project ${PROJECT_ID} created and set as default."
else
  echo "Project ${PROJECT_ID} already exists."
fi


# Check if billing is enabled for the project
BILLING_ENABLED=$(gcloud billing projects describe ${PROJECT_ID} --format="value(billingEnabled)")

if [[ "$BILLING_ENABLED" == "False" ]]; then
  echo "Billing for ${PROJECT_ID} is not enabled. Linking billing account..."
  # Enable billing for the project
  gcloud billing projects link ${PROJECT_ID} --billing-account=$BILLING_ACCOUNT
  
  echo "Billing successfully enabled for project ${PROJECT_ID}."
else
  echo "Billing is already enabled for project ${PROJECT_ID}."
fi


# Check if the service account exists
if gcloud iam service-accounts describe ${PROJECT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com >/dev/null 2>&1; then
  echo "Service account already exists"
else
  # Create the service account
  gcloud iam service-accounts create ${PROJECT_NAME} \
    --description="Service Account to use with Terraform"

  # Create the key file
  gcloud iam service-accounts keys create service_account.json \
    --iam-account="${PROJECT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

  # Grant the Owner role
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${PROJECT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/owner"

  echo "Service account created"
fi

EOF