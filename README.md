# Smart Sensor Flow

AWS Glue + SageMaker based IoT sensor data processing and machine learning pipeline.

## Overview

This project implements an automated end-to-end data processing and machine learning workflow:

1. Raw sensor data (CSV/Parquet) is uploaded to Amazon S3.
2. Glue Job 1 cleans the raw data (`glue_job1_cleaning.py`).
3. Glue Job 2 aggregates temperature and humidity in 5-minute windows (`glue_job2_aggregate.py`).
4. Aggregated data triggers SageMaker training (`train_model.py` using XGBoost).
5. The trained model is deployed to a SageMaker endpoint for real-time inference.
6. All AWS infrastructure is provisioned and managed using Terraform.

## Tech Stack

- Infrastructure: Terraform, AWS IAM, S3, Glue, Lambda, SageMaker
- Data Processing: AWS Glue (PySpark), Pandas, NumPy
- Model Training: SageMaker + XGBoost
- Orchestration: AWS Lambda, EventBridge
- Language: Python 3.x

## Project Structure

```
smart-sensor-flow/
├── data/                         # Example raw sensor data
├── glue_jobs/
│   ├── glue_job1_cleaning.py     # Data cleaning job
│   ├── glue_job2_aggregate.py    # Data aggregation job
├── lambda/
│   ├── lambda_deploy_model.py    # Deploy SageMaker model
│   ├── lambda_trigger_training.py# Trigger SageMaker training
├── model/                        # Model artifacts (optional)
├── sagemaker/
│   └── train_model.py            # Model training script
├── terraform/
│   ├── *.tf                      # Terraform IaC configuration
├── .gitignore
└── README.md
```

## Deployment

### 1. Prerequisites

- Python 3.x
- AWS CLI configured with necessary permissions
- Terraform installed

```
pip install -r requirements.txt
brew install terraform
```

### 2. Deploy AWS Infrastructure

```
cd terraform
terraform init
terraform apply
```

### 3. Upload Raw Data to S3

```
aws s3 cp data/raw_sensor_data.csv s3://<your-bucket-name>/raw/
```

### 4. Run Glue Jobs

- Run `glue_job1_cleaning`
- Run `glue_job2_aggregate`

### 5. Train and Deploy the Model

- `lambda_trigger_training` automatically triggers the SageMaker training job.
- Once training completes, `lambda_deploy_model` deploys the model to a SageMaker endpoint.

## Data Flow Architecture

```
Sensor Data -> S3 -> Glue Job 1 -> Glue Job 2 -> S3 (Aggregated)
       -> Lambda Trigger -> SageMaker Training -> Model Artifact
       -> Lambda Deploy -> SageMaker Endpoint
```

## License

MIT License
