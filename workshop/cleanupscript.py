#!/usr/bin/env python3

import boto3

## Disable logging for Code Server ALB

client = boto3.client('elbv2')

# Get ALB ARN by name
response = client.describe_load_balancers(Names=['REPLACE_CODE_SERVER_ALB'])
alb_arn = response['LoadBalancers'][0]['LoadBalancerArn']

client.modify_load_balancer_attributes(
LoadBalancerArn=alb_arn,
Attributes=[
        {
        'Key': 'access_logs.s3.enabled',
        'Value': 'false'
        }
    ]
)

## Disable logging for Code Server CloudFront Distribution

client = boto3.client('cloudfront')

# Get current distribution config
response = client.get_distribution_config(Id='REPLACE_CLOUDFRONT_DISTRIBUTION_ID')
config = response['DistributionConfig']
etag = response['ETag']

# Disable logging
config['Logging']['Enabled'] = False

# Update distribution
client.update_distribution(
    Id='REPLACE_CLOUDFRONT_DISTRIBUTION_ID',
    DistributionConfig=config,
    IfMatch=etag
)

## Empty workshop S3 buckets

BUCKETS = [
    'REPLACE_S3_BUCKET_ARTIFACT',
    'REPLACE_S3_BUCKET_GIT',
    'REPLACE_S3_BUCKET_LOGS',
    'REPLACE_S3_BUCKET_WILDLIFE'
]

s3 = boto3.resource('s3')

for bucket_name in BUCKETS:
    try:
        bucket = s3.Bucket(bucket_name)
        bucket.objects.all().delete()
        bucket.object_versions.delete()
        print(f"Deleted all objects from S3 bucket: {bucket_name}")
    except Exception as e:
        print(f"Error deleting objects from S3 bucket: {bucket_name}: {e}")


# Disable container insights for ECS cluster
ecs = boto3.client('ecs')

ecs.update_cluster(
    cluster='REPLACE_PREFIX_CODE-ecs',
    settings=[
        {
            'name': 'containerInsights',
            'value': 'disabled'
        }
    ]
)

# Delete workshop CloudWatch log groups
log_groups = [
    '/aws/codebuild/REPLACE_PREFIX_CODE-codebuildproject-terraform-build',
    '/aws/codepipeline/REPLACE_PREFIX_CODE-pipeline',
    '/aws/ec2/REPLACE_PREFIX_CODE-codeserver',
    '/aws/ecs/REPLACE_PREFIX_CODE-alerts',
    '/aws/ecs/xray-daemon',
    '/aws/ecs/containerinsights/REPLACE_PREFIX_CODE-ecs/performance',
    '/aws/ecs/service-connect/REPLACE_PREFIX_CODE-app',
    '/aws/ecs/REPLACE_PREFIX_CODE-dataapi',
    '/aws/ecs/REPLACE_PREFIX_CODE-datadb',
    '/aws/ecs/REPLACE_PREFIX_CODE-frontend',
    '/aws/ecs/REPLACE_PREFIX_CODE-media',
    '/aws/lambda/REPLACE_PREFIX_CODE-lambda-gps',
    '/aws/vpc/REPLACE_PREFIX_CODE-flowlogs'
]

client = boto3.client('logs')

for log_group in log_groups:
    try:
        client.delete_log_group(logGroupName=log_group)
        print(f"Deleted: {log_group}")
    except:
        print(f"Failed: {log_group}")