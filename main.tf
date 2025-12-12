provider "github" {
  token = var.github_token
  owner = "rsi-pf-eng-sandbox"
}
# Load YAML files
locals {
  members_data      = yamldecode(file(var.members_file))
  teams_data        = yamldecode(file(var.teams_file))

  # Transform members data for easier processing
  members = {
    for member in local.members_data.members : member.username => {
      username = member.username
      email    = try(member.email, null)
      role     = try(member.role, "member")
    }
  }

  # Transform teams data
  teams = {
    for team in local.teams_data.teams : team.name => {
      name           = team.name
      description    = try(team.description, "")
      privacy        = try(team.privacy, "closed")
      parent_team_id = try(team.parent_team, null)
      members        = try(team.members, [])
      maintainers    = try(team.maintainers, [])
    }
  }
}

# Organization members
resource "github_membership" "members" {
  for_each = local.members
  
  username = each.value.username
  role     = each.value.role
}

# Teams
resource "github_team" "teams" {
  for_each = local.teams

  name           = each.value.name
  description    = each.value.description
  privacy        = each.value.privacy
  parent_team_id = each.value.parent_team_id
}

# Team memberships
resource "github_team_membership" "team_members" {
  for_each = merge([
    for team_name, team in local.teams : {
      for member in team.members : "${team_name}-${member}" => {
        team_id  = github_team.teams[team_name].id
        username = member
        role     = "member"
      }
    }
  ]...)

  team_id  = each.value.team_id
  username = each.value.username
  role     = each.value.role
}

resource "github_team_membership" "team_maintainers" {
  for_each = merge([
    for team_name, team in local.teams : {
      for maintainer in team.maintainers : "${team_name}-${maintainer}" => {
        team_id  = github_team.teams[team_name].id
        username = maintainer
        role     = "maintainer"
      }
    }
  ]...)

  team_id  = each.value.team_id
  username = each.value.username
  role     = each.value.role
}

output "repo_ids" {
  value = {
    for name, repo in data.github_repository.actions_enabled :
    name => repo.repo_id
  }
}
