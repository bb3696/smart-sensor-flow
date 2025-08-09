import boto3
import os
import time

def lambda_handler(event, context):
    sagemaker = boto3.client('sagemaker')
    timestamp = int(time.time())

    training_job_name = event.get("TrainingJobName") or os.environ.get("TRAINING_JOB_NAME")
    if not training_job_name:
        raise ValueError("Missing TrainingJobName in event or env vars")

    model_name = f"sensor-model-{timestamp}"
    endpoint_config_name = f"sensor-endpoint-config-{timestamp}"
    endpoint_name = f"sensor-endpoint-{timestamp}"

    # ✅ 自动获取模型输出 S3 路径
    job_info = sagemaker.describe_training_job(TrainingJobName=training_job_name)
    model_data_url = job_info["ModelArtifacts"]["S3ModelArtifacts"]

    image_uri = "683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.5-1"

    # 1. Create model
    sagemaker.create_model(
        ModelName=model_name,
        PrimaryContainer={
            'Image': image_uri,
            'ModelDataUrl': model_data_url
        },
        ExecutionRoleArn=os.environ['SAGEMAKER_ROLE_ARN']
    )

    # 2. Create endpoint config
    sagemaker.create_endpoint_config(
        EndpointConfigName=endpoint_config_name,
        ProductionVariants=[{
            'VariantName': 'AllTraffic',
            'ModelName': model_name,
            'InstanceType': 'ml.m5.large',
            'InitialInstanceCount': 1
        }]
    )

    # 3. Create endpoint
    sagemaker.create_endpoint(
        EndpointName=endpoint_name,
        EndpointConfigName=endpoint_config_name
    )

    return {
        "status": "endpoint_created",
        "endpoint_name": endpoint_name
    }
