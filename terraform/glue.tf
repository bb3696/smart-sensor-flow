resource "aws_iam_role" "glue_role" {
  name = "glue-job1-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "glue.amazonaws.com"
      },
      Effect = "Allow",
      Sid = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_s3_access" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_glue_job" "job1_cleaning" {
  name     = "job1-clean-raw-data"
  role_arn = aws_iam_role.glue_role.arn

  glue_version = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
  command {
    name            = "glueetl"
    script_location = "s3://sensor-pipeline-tony-2025/scripts/glue_job1_cleaning.py"
    python_version  = "3"
  }
  max_retries = 0
  timeout     = 10
}

resource "aws_glue_job" "job2_aggregate" {
  name     = "job2-aggregate-cleaned-data"
  role_arn = aws_iam_role.glue_role.arn

  glue_version = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"

  command {
    name            = "glueetl"
    script_location = "s3://sensor-pipeline-tony-2025/scripts/glue_job2_aggregate.py"
    python_version  = "3"
  }

  max_retries = 0
  timeout     = 10
}

