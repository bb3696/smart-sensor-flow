resource "aws_cloudwatch_event_rule" "sagemaker_training_completed" {
  name        = "sagemaker-training-complete"
  description = "Trigger on SageMaker training job state change to Completed"
  event_pattern = jsonencode({
    "source": ["aws.sagemaker"],
    "detail-type": ["SageMaker Training Job State Change"],
    "detail": {
      "TrainingJobStatus": ["Completed"]
    }
  })
}

resource "aws_lambda_permission" "allow_eventbridge_invoke_deploy" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deploy_model.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sagemaker_training_completed.arn
}

resource "aws_cloudwatch_event_target" "trigger_deploy_lambda" {
  rule      = aws_cloudwatch_event_rule.sagemaker_training_completed.name
  target_id = "TriggerDeployLambda"
  arn       = aws_lambda_function.deploy_model.arn
  input_transformer {
    input_paths = {
      jobName = "$.detail.TrainingJobName"
    }
    input_template = <<JSON
{
  "TrainingJobName": <jobName>
}
JSON
  }
}

resource "aws_cloudwatch_event_rule" "glue_job2_success" {
  name        = "glue-job2-success-rule"
  description = "Trigger Lambda when Glue Job2 completes successfully"
  event_pattern = jsonencode({
    "source": ["aws.glue"],
    "detail-type": ["Glue Job State Change"],
    "detail": {
      "jobName": ["job2-aggregate-cleaned-data"],  # 替换为你真实的 Glue Job2 名称
      "state": ["SUCCEEDED"]
    }
  })
}

resource "aws_lambda_permission" "allow_eventbridge_trigger_training" {
  statement_id  = "AllowGlueEventTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_training.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.glue_job2_success.arn
}

resource "aws_cloudwatch_event_target" "trigger_lambda_after_glue" {
  rule      = aws_cloudwatch_event_rule.glue_job2_success.name
  target_id = "TriggerTrainingLambda"
  arn       = aws_lambda_function.trigger_training.arn

  # 可选：如果你 Lambda 支持自定义输入，可以配置 input_transformer
  input_transformer {
    input_paths = {
      jobName = "$.detail.jobName"
    }
    input_template = <<JSON
{
  "triggeredBy": "GlueJob2",
  "jobName": <jobName>
}
JSON
  }
}
