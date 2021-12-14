#!/bin/bash

# Create S3 bucket for Terraform backend
#
# Terraform is an administrative tool that manages your infrastructure,
# and so ideally the infrastructure that is used by Terraform should exist
# outside of the infrastructure that Terraform manages.
#
# It is highly recommended that you enable Bucket Versioning on the S3 bucket
# to allow for state recovery in the case of accidental deletions and human error.
#
# https://www.terraform.io/docs/backends/types/s3.html

if ! type aws >/dev/null 2>&1; then
  printf "\nNot found aws, run command\n\n"
  printf "    \033[36mpip install awscli\033[0m\n"
  exit 1
fi

if [ -f ./config.json1 ]; then
  ACCOUNT_ID=$(cat config.json | jq -r .account_id)
  REGION=$(cat config.json | jq -r .region)
else
  read -p "AWS Account Id: " ACCOUNT_ID
  read -p "S3 Bucket Location [eu-west-1]: " REGION
  REGION=${REGION:-eu-west-1}
fi

# Creates a new bucket.
# Regions outside of us-east-1 require the appropriate LocationConstraint
# to be specified in order to create the bucket in the desired region.
# https://docs.aws.amazon.com/cli/latest/reference/s3api/create-bucket.html
BUCKET_NAME="terraform-backend-${ACCOUNT_ID}"

aws s3 ls s3://${BUCKET_NAME} 2>/dev/null
if [ $? -eq 0 ]; then
  echo -e "\nBucket ${BUCKET_NAME} already exists"
  exit 0
else
  echo -e "\nCreating ${BUCKET_NAME} in ${REGION} ..."
  aws s3api create-bucket --bucket "${BUCKET_NAME}" --create-bucket-configuration LocationConstraint="${REGION}"
  if [ $? -ne 0 ]; then exit $?; fi
  aws s3api get-bucket-location --bucket "${BUCKET_NAME}"
fi

# Sets the versioning state of an existing bucket.
# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-versioning.html
echo -e "\nEnabling versioning ..."
aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled

if [ $? -ne 0 ]; then exit $?; fi
aws s3api get-bucket-versioning --bucket "${BUCKET_NAME}"

# Creates a new server-side encryption configuration.
# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-bucket-encryption.html
echo -e "\nEnabling encryption ..."
aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'

if [ $? -ne 0 ]; then exit $?; fi
aws s3api get-bucket-encryption --bucket "${BUCKET_NAME}"

# Creates or modifies the PublicAccessBlock configuration for an Amazon S3 bucket.
# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-public-access-block.html
echo -e "\nBlocking Public Access ..."
aws s3api put-public-access-block --bucket "${BUCKET_NAME}" --public-access-block-configuration '{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}'

if [ $? -ne 0 ]; then exit $?; fi
aws s3api get-public-access-block --bucket "${BUCKET_NAME}"
