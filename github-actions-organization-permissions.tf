# Load YAML file for actions enabled repositories
locals {
  actions_repos_data = yamldecode(file(var.actions_enabled_repositories_file))
  actions_enabled_repositories = local.actions_repos_data.repositories
}

# Data sources to get repository IDs from names
data "github_repository" "actions_enabled" {
  for_each = toset(local.actions_enabled_repositories)
  name     = each.value
}

resource "github_actions_organization_permissions" "org_actions" {
  allowed_actions      = "selected"
  enabled_repositories = "selected"

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
    patterns_allowed = []
  }

  enabled_repositories_config {
    repository_ids = [
      for repo in data.github_repository.actions_enabled : repo.repo_id
    ]
  }

  lifecycle {
    prevent_destroy = true
  }
}
