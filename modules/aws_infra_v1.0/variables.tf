variable "prefix" {
  description = "Prefix for resources"
  type        = string
}


variable "environment" {
  description = "Environment tag"
  type        = string
}

variable "lambda_source_path" {
  description = "The path to the lambda function source code"
  default     = "./lambda_src"
  type        = string
}


variable "log_retention" {
  description = "Lambda Function Log retention period"
  default     = 90
  type        = number
}

variable "bucket_versioning" {
  description = "Bucket versioning Enabled/Disabled"
  default     = "Enabled"
  type        = string

}

variable "file_ia_days" {
  description = "Controls S3 object transition to Infrequent Access based on number of days"
  default     = 30
  type        = string

}

variable "file_glacier_days" {
  description = "Controls S3 object transition to Glacier based on number of days"
  default     = 60
  type        = number

}

variable "project_root" {
  description = "Root Path defined as relative to terraform invoke path"
  default     = "../../"
  type        = string

}