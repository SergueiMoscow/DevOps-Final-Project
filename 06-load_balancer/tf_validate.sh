#!/bin/bash
echo "Fetching outputs from 01-sa_bucket..."
export TF_VAR_sa_access_key=$(terraform -chdir=../01-sa_bucket output -raw sa_access_key)
export TF_VAR_sa_secret_key=$(terraform -chdir=../01-sa_bucket output -raw sa_secret_key)
export TF_VAR_bucket_name=$(terraform -chdir=../01-sa_bucket output -raw bucket_name)

if [ -z "$TF_VAR_sa_access_key" ] || [ -z "$TF_VAR_sa_secret_key" ] || [ -z "$TF_VAR_bucket_name" ]; then
    echo "SA_ACCESS_KEY: $SA_ACCESS_KEY"
    echo "SA_SECRET_KEY: $SA_SECRET_KEY"
    echo "BUCKET_NAME: $BUCKET_NAME"

  echo "Error: One or more outputs are empty. Check terraform outputs in 01-sa_bucket."
  exit 1
fi

echo "Initializing Terraform in load-balancer..."
terraform validate
