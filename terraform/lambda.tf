resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-trigger-training-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/lambda_trigger_training.py"
  output_path = "${path.module}/lambda/lambda_trigger_training.zip"
}

resource "aws_lambda_function" "trigger_training" {
  function_name = "trigger-sagemaker-training"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_trigger_training.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_zip.output_path

  timeout = 30

  environment {
    variables = {
      SAGEMAKER_ROLE_ARN = aws_iam_role.sagemaker_execution_role.arn
      TRAINING_DATA_URI  = "s3://sensor-pipeline-tony-2025/for-training/"
      MODEL_OUTPUT_URI   = "s3://sensor-pipeline-tony-2025/model-output/"
    }
  }

  depends_on = [aws_iam_role_policy.lambda_sagemaker_policy]
}


data "archive_file" "lambda_deploy_zip" {
  type        = "zip"
  source_file = "../lambda/lambda_deploy_model.py"
  output_path = "${path.module}/lambda/lambda_deploy_model.zip"
}

resource "aws_lambda_function" "deploy_model" {
  function_name = "deploy-sagemaker-endpoint"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_deploy_model.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.lambda_deploy_zip.output_path
  timeout       = 60

  environment {
    variables = {
      SAGEMAKER_ROLE_ARN  = aws_iam_role.sagemaker_execution_role.arn
      MODEL_OUTPUT_URI    = "s3://sensor-pipeline-tony-2025/model/output/"
      TRAINING_JOB_NAME   = "sensor-training-job-latest" # ✅ 可从事件传入更好
    }
  }

  depends_on = [aws_iam_role_policy.lambda_sagemaker_policy]
}
