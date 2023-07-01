data "aws_caller_identity" "current" {}

data "archive_file" "artifact" {
  type        = "zip"
  source_dir  = "${var.project_root}dist/"
  output_path = "${var.project_root}lambda_package.zip"
  depends_on  = [null_resource.build]

}
