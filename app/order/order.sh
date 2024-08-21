#!/bin/bash
aws dynamodb create-table --table-name Orders \
    --attribute-definitions AttributeName=OrderId,AttributeType=S \
    --key-schema AttributeName=OrderId,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5