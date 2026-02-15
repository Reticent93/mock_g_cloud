#!/bin/bash

echo "--- 1. Checking Environment Variables ---"
echo "AWS_REGION: $AWS_REGION"
echo "AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"

echo -e "\n--- 2. Checking AWS CLI Config Default ---"
aws configure get region

echo -e "\n--- 3. Checking Terraform Code for Hardcoded Strings ---"
grep -r "us-east-1" --include="*.tf" --include="*.tfvars" .

echo -e "\n--- 4. Checking Terraform Provider Requirement ---"
grep -r "version" .terraform/resource_lock.json 2>/dev/null | head -n 5

echo -e "\n--- 5. Checking for Local State Overrides ---"
if [ -f "terraform.tfstate" ]; then
    grep "region" terraform.tfstate | head -n 5
else
    echo "No local state file found (using remote backend)."
fi

echo -e "\n--- 6. Checking Current Caller Identity (AWS CLI) ---"
aws sts get-caller-identity --query "Arn" --output text