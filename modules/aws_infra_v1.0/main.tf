# Define an AWS S3 bucket with versioning and server-side encryption
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.prefix}-${var.environment}"


}
resource "aws_s3_bucket_server_side_encryption_configuration" "cmk" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cmk.arn
      sse_algorithm     = "aws:kms"
    }
  }
}


resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.bucket_versioning
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id = "move-to-standard-ia-and-glacier"

    # First transition: After 30 days, move objects to the STANDARD_IA storage class
    transition {
      days          = var.file_ia_days
      storage_class = "STANDARD_IA"
    }

    # Second transition: After 60 days (30 days after the first transition),
    # move objects to the GLACIER_IR storage class
    transition {
      days          = var.file_glacier_days
      storage_class = "GLACIER_IR"
    }
    status = "Enabled"
  }
}


# Define an AWS KMS key for server-side encryption in S3
resource "aws_kms_key" "cmk" {
  description         = "KMS Key for S3 Encryption"
  enable_key_rotation = true

  policy = <<-POLICY
{
    "Version": "2012-10-17",
    "Id": "kms-default",
    "Statement": [
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                ]
            },
            "Action": [
                "kms:*"
            ],
            "Resource": "*"
        }
    ]
}
  POLICY
}

# Define an AWS DynamoDB table
resource "aws_dynamodb_table" "database" {
  name         = "${var.prefix}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "surname"
    type = "S"
  }
  attribute {
    name = "name"
    type = "S"
  }

  global_secondary_index {
    name               = "NameIndex"
    hash_key           = "name"
    projection_type    = "ALL"
    non_key_attributes = []
  }

  global_secondary_index {
    name               = "SurnameIndex"
    hash_key           = "surname"
    projection_type    = "ALL"
    non_key_attributes = []
  }

}

resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "rm -rf ${var.project_root}dist && rm -rf ${var.project_root}lambda_package.zip && mkdir ${var.project_root}dist && cp ${var.project_root}src/*.py ${var.project_root}dist/. && pip install -r ${var.project_root}src/requirements.txt -t ${var.project_root}dist/"
  }
  triggers = {
    always_run = "${timestamp()}"
  }
}


# Define an AWS Lambda function
resource "aws_lambda_function" "serverless" {
  function_name    = "${var.prefix}-lambda"
  filename         = data.archive_file.artifact.output_path
  source_code_hash = data.archive_file.artifact.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "event_handler.event_handler"
  runtime          = "python3.9"
  timeout          = 30
  environment {
    variables = {
      BUCKET = aws_s3_bucket.bucket.bucket
      TABLE  = aws_dynamodb_table.database.name
    }
  }
}


# Define AWS Lambda permissions for S3 bucket
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.serverless.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

# Define S3 bucket notification for Lambda function
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.serverless.arn
    events              = ["s3:ObjectCreated:*"]
    //filter_prefix       = "${var.prefix}/"
    filter_suffix = ".json"
  }
}

# Define an IAM role for the Lambda function
resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.prefix}-lambda-role"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}


# Define an IAM policy for the Lambda function
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.prefix}-lambda-policy"
  description = "Policy for ${var.prefix}-lambda function"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "${aws_s3_bucket.bucket.arn}/*",
          "${aws_s3_bucket.bucket.arn}"
          ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "dynamodb:PutItem"
        ],
        "Resource": "${aws_dynamodb_table.database.arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt"
        ],
        "Resource": "${aws_kms_key.cmk.arn}"
      }
    ]
  }
  EOF
}


# Define a CloudWatch log group for the Lambda function
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.serverless.function_name}"
  retention_in_days = var.log_retention
}
