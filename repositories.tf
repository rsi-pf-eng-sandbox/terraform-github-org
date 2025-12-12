# repositories.yaml の読み込み
locals {
  repositories_data = yamldecode(file(var.repositories_file))

  # name をキーにした map に整形
  repositories = {
    for repo in local.repositories_data.repositories :
    repo.name => repo
  }
}

# リポジトリ作成・削除
resource "github_repository" "repos" {
  for_each = local.repositories

  name        = each.value.name
  description = try(each.value.description, "")

  # visibility は public / private / internal
  visibility = try(each.value.visibility, "internal")

  auto_init             = try(each.value.auto_init, false)
  delete_branch_on_merge = try(each.value.delete_branch_on_merge, true)

  has_issues   = try(each.value.has_issues, true)
  has_projects = try(each.value.has_projects, false)
  has_wiki     = try(each.value.has_wiki, false)

  # topics が指定されていれば適用
  topics = try(each.value.topics, [])

}
