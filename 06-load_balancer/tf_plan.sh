#!/bin/bash
echo "Fetching outputs from 01-sa_bucket..."
export TF_VAR_sa_access_key=$(terraform -chdir=../01-sa_bucket output -raw sa_access_key)
export TF_VAR_sa_secret_key=$(terraform -chdir=../01-sa_bucket output -raw sa_secret_key)
export TF_VAR_bucket_name=$(terraform -chdir=../01-sa_bucket output -raw bucket_name)

echo "TF_VAR_sa_access_key: $TF_VAR_sa_access_key"
echo "TF_VAR_sa_secret_key: $TF_VAR_sa_secret_key"
echo "TF_VAR_bucket_name: $TF_VAR_bucket_name"

if [ -z "$TF_VAR_sa_access_key" ] || [ -z "$TF_VAR_sa_secret_key" ] || [ -z "$TF_VAR_bucket_name" ]; then

  echo "Error: One or more outputs are empty. Check terraform outputs in 01-sa_bucket."
  exit 1
fi

echo "Planning Terraform in load-balancer..."
terraform plan
