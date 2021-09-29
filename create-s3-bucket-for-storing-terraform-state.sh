#!/usr/bin/env bash

S3_BUCKET="alex-misc"

aws s3api create-bucket \
    --acl private \
    --bucket "${S3_BUCKET}" \
    --region "${AWS_DEFAULT_REGION:-us-east-1}"

aws s3api put-public-access-block \
    --bucket "${S3_BUCKET}" \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

aws resourcegroupstaggingapi tag-resources \
    --resource-arn-list "arn:aws:s3:::${S3_BUCKET}" \
    --tags owner=alex.ryndin
