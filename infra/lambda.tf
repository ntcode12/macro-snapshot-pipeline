# Lambda function for macro snapshot processing
resource "aws_lambda_function" "macro_snapshot" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "macro-snapshot-processor"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
  timeout         = 300
  memory_size     = 512

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.raw.id
      DB_HOST     = aws_db_instance.pg.address
      DB_NAME     = aws_db_instance.pg.db_name
      DB_USER     = aws_db_instance.pg.username
      DB_PASSWORD = var.db_password
    }
  }

  tags = {
    Project = var.project_tag
  }
}

# Create ZIP file for Lambda deployment
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_dir  = "${path.module}/../lambda"
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.macro_snapshot.function_name}"
  retention_in_days = 14

  tags = {
    Project = var.project_tag
  }
}

# Lambda permission for S3 trigger (if needed)
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.macro_snapshot.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw.arn
}

# S3 bucket notification for Lambda trigger
resource "aws_s3_bucket_notification" "lambda_notification" {
  bucket = aws_s3_bucket.raw.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.macro_snapshot.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# Output Lambda function ARN
output "lambda_function_arn" {
  value = aws_lambda_function.macro_snapshot.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.macro_snapshot.function_name
} 