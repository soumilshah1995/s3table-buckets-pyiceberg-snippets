#!/bin/bash

# Variables
AWS_ACCOUNT_ID="XX"
AWS_REGION="us-east-2"
BUCKET_NAME="pyiceberg-blog-bucket"
DATABASE_NAME="myblognamespace"
POLICY_NAME="irc-glue-lf-policy"
ROLE_NAME="pyiceberg-etl-role"

# Step 1: Create the IAM policy if it doesn't exist
if aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].PolicyName" --output text | grep -q "$POLICY_NAME"; then
    echo "Policy $POLICY_NAME already exists."
else
    aws iam create-policy --policy-name $POLICY_NAME --policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Sid\": \"VisualEditor0\",
                \"Effect\": \"Allow\",
                \"Action\": [
                    \"glue:GetCatalog\",
                    \"glue:GetDatabase\",
                    \"glue:GetDatabases\",
                    \"glue:GetTable\",
                    \"glue:GetTables\",
                    \"glue:CreateTable\",
                    \"glue:UpdateTable\"
                ],
                \"Resource\": [
                    \"arn:aws:glue:$AWS_REGION:$AWS_ACCOUNT_ID:catalog\",
                    \"arn:aws:glue:$AWS_REGION:$AWS_ACCOUNT_ID:catalog/s3tablescatalog\",
                    \"arn:aws:glue:$AWS_REGION:$AWS_ACCOUNT_ID:catalog/s3tablescatalog/$BUCKET_NAME\",
                    \"arn:aws:glue:$AWS_REGION:$AWS_ACCOUNT_ID:table/s3tablescatalog/$BUCKET_NAME/$DATABASE_NAME/*\",
                    \"arn:aws:glue:$AWS_REGION:$AWS_ACCOUNT_ID:database/s3tablescatalog/$BUCKET_NAME/$DATABASE_NAME\"
                ]
            },
            {
                \"Effect\": \"Allow\",
                \"Action\": [
                    \"lakeformation:GetDataAccess\"
                ],
                \"Resource\": \"*\"
            }
        ]
    }"
    echo "Policy $POLICY_NAME created."
fi

# Step 3: Create the IAM role if it doesn't exist
if aws iam get-role --role-name $ROLE_NAME &>/dev/null; then
    echo "Role $ROLE_NAME already exists."
else
    aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document "{
        \"Version\": \"2012-10-17\",
        \"Statement\": [
            {
                \"Effect\": \"Allow\",
                \"Principal\": {
                    \"AWS\": \"arn:aws:iam::$AWS_ACCOUNT_ID:root\"
                },
                \"Action\": \"sts:AssumeRole\",
                \"Condition\": {}
            }
        ]
    }"
    echo "Role $ROLE_NAME created."
fi

# Step 4: Attach the policy to the role
if aws iam list-attached-role-policies --role-name $ROLE_NAME --query "AttachedPolicies[?PolicyName=='$POLICY_NAME'].PolicyName" --output text | grep -q "$POLICY_NAME"; then
    echo "Policy $POLICY_NAME is already attached to the role $ROLE_NAME."
else
    aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$POLICY_NAME
    echo "Policy $POLICY_NAME attached to the role $ROLE_NAME."
fi

echo "Bucket, policy, and role have been checked/created and configured successfully."
