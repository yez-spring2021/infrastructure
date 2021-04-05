resource "aws_sns_topic" "webapp_sns_topic" {
  name = "webapp_sns_topic"
}

resource "aws_sns_topic_subscription" "lambda_sns_topic_subscribe" {
  topic_arn = aws_sns_topic.webapp_sns_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.webapp_lambda.arn
}

