import boto3
import os
import time

def lambda_handler(event, context):
    client = boto3.client('sagemaker')

    training_job_name = f"sensor-training-job-{int(time.time())}"  # 避免重名

    response = client.create_training_job(
        TrainingJobName=training_job_name,
        AlgorithmSpecification={
            'TrainingImage': '683313688378.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.5-1',
            'TrainingInputMode': 'File'
        },
        RoleArn=os.environ['SAGEMAKER_ROLE_ARN'],
        InputDataConfig=[{
            'ChannelName': 'train',
            'DataSource': {
                'S3DataSource': {
                    'S3DataType': 'S3Prefix',
                    'S3Uri': os.environ['TRAINING_DATA_URI'],
                    'S3DataDistributionType': 'FullyReplicated'
                }
            },
            'ContentType': 'application/x-parquet'
        }],
        OutputDataConfig={
            'S3OutputPath': os.environ['MODEL_OUTPUT_URI']
        },
        ResourceConfig={
            'InstanceType': 'ml.m5.large',
            'InstanceCount': 1,
            'VolumeSizeInGB': 5
        },
        StoppingCondition={
            'MaxRuntimeInSeconds': 600
        },
        HyperParameters={
        "objective": "reg:squarederror",
        "num_round": "100",
        "max_depth": "5",
        "eta": "0.2",
        "gamma": "4",
        "min_child_weight": "6",
        "subsample": "0.7",
        "verbosity": "1"
        }
    )

    print("✅ Training job started:", response['TrainingJobArn'])
    return {"status": "started", "job": response['TrainingJobArn']}
