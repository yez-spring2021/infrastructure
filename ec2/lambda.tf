data "aws_iam_role" "iam_lambda_role" {
  name = "iam_lambda_role"
}
// need to create one 
data "aws_iam_role" "CodeDeployLambdaServiceRole" {
  name = "CodeDeployLambdaServiceRole"
}

resource "aws_codedeploy_app" "csye6225-lambda" {
  compute_platform = "Lambda"
  name             = "csye6225-lambda"
}

//codedeploy group
resource "aws_codedeploy_deployment_group" "csye6225-lambda-deployment" {
  app_name              = aws_codedeploy_app.csye6225-lambda.name
  deployment_group_name = "csye6225-lambda-deployment"
  service_role_arn      = data.aws_iam_role.CodeDeployLambdaServiceRole.arn
  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"


  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

}

resource "aws_s3_bucket_object" "lambda_file" {
  bucket     = var.serverless_bucketname
  key        = "csye6225-lambda.zip"
  source        = "csye6225-lambda.zip"
}

resource "aws_lambda_function" "webapp_lambda" {
  function_name = "webapp_lambda"
  s3_bucket     = var.serverless_bucketname
  s3_key        = "csye6225-lambda.zip"
  role          = data.aws_iam_role.iam_lambda_role.arn
  handler       = "index.handler"
  memory_size   = 256
  timeout       = 180
  publish       = true
  runtime = "nodejs14.x"

  environment {
    variables = {
      Name = "Lambda Function"
      EMAIL_SOURCE = var.email_source
    }
  }
}

resource "aws_lambda_permission" "lambda_sns_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webapp_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.webapp_sns_topic.arn
}

resource "aws_lambda_alias" "lambda_alias" {
  name             = "sendEmail"
  description      = "alias for sendEmail"
  function_name    = aws_lambda_function.webapp_lambda.function_name
  function_version = aws_lambda_function.webapp_lambda.version
}