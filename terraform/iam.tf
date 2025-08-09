data "aws_caller_identity" "current" {}


resource "aws_iam_policy" "glue_s3_access_policy" {
  name = "glue-s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::sensor-pipeline-tony-2025",
          "arn:aws:s3:::sensor-pipeline-tony-2025/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_access_custom" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_access_policy.arn
}


resource "aws_iam_role_policy" "lambda_sagemaker_policy" {
  name = "lambda-sagemaker-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sagemaker:CreateTrainingJob"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = "arn:aws:iam::896520308122:role/sagemaker-exec-role"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_policy" "lambda_sagemaker_deploy_policy" {
  name        = "lambda-sagemaker-deploy-policy"
  description = "Allow Lambda to deploy SageMaker model and endpoint"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sagemaker:DescribeTrainingJob",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateEndpoint"
        ],
        Resource = [
          "arn:aws:sagemaker:us-east-1:${data.aws_caller_identity.current.account_id}:training-job/*",
          "arn:aws:sagemaker:us-east-1:${data.aws_caller_identity.current.account_id}:model/*",
          "arn:aws:sagemaker:us-east-1:${data.aws_caller_identity.current.account_id}:endpoint-config/*",
          "arn:aws:sagemaker:us-east-1:${data.aws_caller_identity.current.account_id}:endpoint/*"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_sagemaker_deploy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_sagemaker_deploy_policy.arn
}

