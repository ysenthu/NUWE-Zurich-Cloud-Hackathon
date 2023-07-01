module "aws_infra" {
  source = "../../modules/aws_infra_v1.0"

  prefix      = "zurch-cloud-hackathon-2023senthu"
  environment = "local"
}
