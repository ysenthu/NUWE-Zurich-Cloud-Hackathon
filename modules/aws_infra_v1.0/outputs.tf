output "bucket_name" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.bucket.bucket
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = aws_dynamodb_table.database.name
}

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.serverless.function_name
}