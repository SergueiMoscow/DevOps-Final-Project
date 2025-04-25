#!/bin/bash
cd ../sa_bucket
echo "Fetching outputs from sa_bucket..."
export SA_ACCESS_KEY=$(terraform output -raw sa_access_key)
export SA_SECRET_KEY=$(terraform output -raw sa_secret_key)
export BUCKET_NAME=$(terraform output -raw bucket_name)
cd ../infra

echo "SA_ACCESS_KEY: $SA_ACCESS_KEY"
echo "SA_SECRET_KEY: $SA_SECRET_KEY"
echo "BUCKET_NAME: $BUCKET_NAME"

if [ -z "$SA_ACCESS_KEY" ] || [ -z "$SA_SECRET_KEY" ] || [ -z "$BUCKET_NAME" ]; then
  echo "Error: One or more outputs are empty. Check terraform outputs in sa_bucket."
  exit 1
fi

echo "Initializing Terraform in infra..."
terraform init -reconfigure \
  -backend-config="bucket=$BUCKET_NAME" \
  -backend-config="access_key=$SA_ACCESS_KEY" \
  -backend-config="secret_key=$SA_SECRET_KEY"