module "ssm_params" {
  source = "../ssm-params"

  secrets_file = "${path.module}/secrets.enc.yaml"
}
