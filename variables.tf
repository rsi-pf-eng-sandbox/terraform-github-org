variable "github_token" {
  description = "GitHub personal access token or GitHub App token"
  type        = string
  sensitive   = true
}

variable "members_file" {
  description = "Path to YAML file containing organization members"
  type        = string
  default     = "data/members.yaml"
}

variable "teams_file" {
  description = "Path to YAML file containing teams configuration"
  type        = string
  default     = "data/teams.yaml"
}

variable "actions_enabled_repositories_file" {
  description = "Path to YAML file containing enabled repositories for GitHub Actions"
  type        = string
  default     = "data/actions-enabled-repositories.yaml"
}