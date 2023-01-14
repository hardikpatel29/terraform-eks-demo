# terraform-eks-demo

First CLone this Repo.


### STEPS To Follows


first setup aws profile in cli.

export,

export ENV=dev
export REGION=us-east-1
export BUCKET_NAME=demo-eks-bucket-1123456
export AWS_PROFILE=nameofprofile

then create s3 bucket as backend for terraform steps mentioned below,also you make shell script of below commands

#!/bin/bash

aws s3api create-bucket \
     --bucket $BUCKET_NAME \
     --region $REGION \
     #--create-bucket-configuration LocationConstraint=$REGION

aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

----------------------------------------------------
last hit terraform command 

terraform init -backend-config="bucket=$BUCKET_NAME" -backend-config="key=$ENV/terraform-state" -backend-config="region=$REGION"

terraform plan -out "demo.tfplan"

terraform apply "demo.tfplan"

once done

export REGION=us-east-1
export EKS_CLUSTER_NAME=my-cluster-dev

aws eks --region $REGION update-kubeconfig --name $EKS_CLUSTER_NAME
