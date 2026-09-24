locals {
  encrypted = { for k, v in yamldecode(file(var.secrets_file)) : k => v if k != "sops" }
  secrets   = yamldecode(ephemeral.sops_file.this.raw)
}

# Terraform does not store ephemeral resources in state or plan files. ref: https://developer.hashicorp.com/terraform/plugin/framework/ephemeral-resources
# Values defined as Sensitive. ref: https://registry.terraform.io/providers/binlab/sops/latest/docs/ephemeral-resources/file
ephemeral "sops_file" "this" {
  source_file = var.secrets_file
  input_type  = "yaml"
}

resource "aws_ssm_parameter" "this" {
  #checkov:skip=CKV_AWS_337
  for_each = local.encrypted

  name             = each.key
  type             = "SecureString"
  value_wo         = local.secrets[each.key]
  value_wo_version = parseint(substr(sha256(each.value), 0, 12), 16)
}
