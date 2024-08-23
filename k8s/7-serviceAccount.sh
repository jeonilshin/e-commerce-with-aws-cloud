#!/bin/bash
cat <<EOF >> ./app-pod-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "rds:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
aws iam create-policy \
  --policy-name app-pod-policy \
  --policy-document file://app-pod-policy.json

eksctl create iamserviceaccount \
  --cluster=app-eks-cluster \
  --namespace=app \
  --name=app-sa \
  --role-name app-pod-role \
  --attach-policy-arn=arn:aws:iam::<계정 ID>:policy/app-pod-policy \
  --approve