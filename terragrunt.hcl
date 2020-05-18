# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------
remote_state {
  backend = "s3"
  config = {
    bucket = "admin-terraform-state.your_organization.biz"
    key = "${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
    role_arn = "arn:aws:iam::${get_env("TG_AWS_ACCT","${get_aws_account_id()}")}:role/TerragruntAdministrator"
    encrypt = true
    dynamodb_table = "admin-terraform-lock"
    s3_bucket_tags = {
      owner = "terragrunt"
      name = "Terraform state storage"
    }
    dynamodb_table_tags = {
      owner = "terragrunt"
      name = "Terraform lock table"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  default_yaml_path = find_in_parent_folders("empty.yaml")
}

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  # Configure Terragrunt to use common vars encoded as yaml to help you keep often-repeated variables (e.g., account ID)
  # DRY. We use yamldecode to merge the maps into the inputs, as opposed to using varfiles due to a restriction in
  # Terraform >=0.12 that all vars must be defined as variable blocks in modules. Terragrunt inputs are not affected by
  # this restriction.
  yamldecode(
    file("${get_terragrunt_dir()}/${find_in_parent_folders("shared.yaml", local.default_yaml_path)}"),
  ),
)
