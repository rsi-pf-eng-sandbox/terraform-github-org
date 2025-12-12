# Terraform GitHub Organization Management

## これは何？
Terraformを使用してGitHub Organizationのメンバーやチーム、ポリシーを管理するリポジトリです。

## 利用者向け

### GitHub Organizationへのメンバー追加・削除方法
GitHub Organizationのメンバーを追加・削除するには[data/members.yaml](data/members.yaml)ファイルを編集し、mainブランチへのPRを出してください

#### メンバーの追加
usernameでアルファベット順で並べてください
```yaml
members:
  ...
  - username: "sonedasaurus"
    email: "takuya.soneda@jp.ricoh.com"
    role: "member"
  ...
```
- username: GitHubのユーザー名
- email: メンバーの識別のために入力してください
- role: 基本的にmemberを指定してください

#### メンバーの削除
メンバーを削除する場合は、`members.yaml`から該当のユーザーを削除してください

### GitHub Organizationへのチーム追加・削除方法
チームを追加・削除するには[data/teams.yaml](data/teams.yaml)ファイルを編集し、mainブランチへのPRを出してください

#### チームの追加
```yaml
teams:
  ...
  - name: "new-team"
    description: "New team description"
    privacy: "closed"  # closed または secret
    maintainers:
      - "nmoa"  # チームのメンテナー
    members:
      - "sonedasaurus"  # チームのメンバー
  ...
```
- name: チーム名（アルファベット順で並べてください）
- description: チームの説明
- privacy: 基本的にclosedを指定してください
- maintainers: チームのメンテナー（GitHubのユーザー名）
- members: チームのメンバー（GitHubのユーザー名）

#### チームの削除
チームを削除する場合は、`teams.yaml`から該当のチームを削除してください

### GitHub Actionsを利用できるリポジトリの管理
GitHub Actionsを利用できるリポジトリの追加・削除を管理するには[data/actions-enabled-repositories.yaml](data/actions-enabled-repositories.yaml)ファイルを編集し、mainブランチへのPRを出してください

#### Actions権限の設定
```yaml
repositories:
  - "repo1"
  - "repo2"
  - "repo3"
```
- repositories: GitHub Actionsを有効にするリポジトリ名のリスト

## 管理者向け

### 初期設定
GitHub Actionsで使用するGitHub Appの設定を行ってください

#### GitHub Appの設定
1. **GitHub Appの作成**:
   - Organization Settings > Developer settings > GitHub Apps
   - "New GitHub App"をクリック
      - `GitHub App name`: 適当な名前をつける（例. terraform-github-org）
      - `Homepage URL`: 本リポジトリのURLを記載する
      - `Webhook`の`Active`: チェックを外す
   - 必要な権限を設定（下記参照）
2. **必要な権限**:
   - **Repository permissions:**
      - `Actions`: Read and write
      - `Administration`: Read and write
      - `Contents`: Read and write (terraform stateファイルのコミット用)
      - `Metadata`: Read
   - **Organization permissions:**
      - `Members`: Read and write
3. **Appのインストール**:
   - GitHub Appの作成が完了するとAppの設定ページに移るので、左メニューのInstall Appをクリック
   - `rfgricoh` Organizationの横にある"Install"をクリック
   - どのリポジトリにインストールするか聞かれるため、`Only select repositories`を選択し、`Select repositories`から本リポジトリを選択
4. **Appのprivate keyの取得**:
   - Appの設定ページに戻り、General > About に記載のClient IDを控えておく
   - General > Private keys にある`Generate a private key`をクリック
   - 秘密鍵のファイル(`.pem`)のダウンロードが促されるので、ローカルの適当な場所に保存

> [!CAUTION]
> 秘密鍵のファイルは情報漏洩を避けるため、クラウド等に保存しないでください。

5. **シークレットとVariablesの設定**:
   - Repository Settings > Secrets and variables > Actions
   - **Secrets**:
     - `PRIVATE_KEY`: ダウンロードした秘密鍵のファイルを開き、内容をコピーして貼り付け
       - **注意**: `PRIVATE_KEY`を設定したら、秘密鍵のファイルは情報漏洩を避けるため削除すること
   - **Variables**:
     - `APP_ID`: GitHub AppのClient IDを設定

### GitHub Actionsを使用した運用
1. **利用者が作成したPRのレビュー**:
   - PRが作成されると`terraform plan`が自動実行され、変更の計画が表示されます
   - 計画を確認し、問題がなければマージしてください
2. **変更の適用**:
   - PRがmainブランチにマージされると`terraform apply`が自動実行され、変更が適用されます

### ローカルで実行する場合
基本的にはGitHub Actionsを使用して管理しますが、ローカルで実行する場合は以下の手順に従ってください

```bash
# terraform.tfvarsを編集してGitHub Tokenを設定:
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 初期化
terraform init

# data/**.yamlを編集してメンバーやチーム、GitHub Actionsを利用できるリポジトリを追加・削除
vim data/members.yaml
vim data/teams.yaml
vim data/actions-enabled-repositories.yaml

# 計画確認
terraform plan

# 適用
terraform apply
```

## 既存リソースのインポート
既にGitHub Organization、メンバー、チームが存在する場合は、Terraformで管理するためにリソースをインポートする必要があります。

### インポート手順
#### 事前準備
```bash
# GitHub CLIがインストールされていることを確認
gh --version
# GitHub CLIで認証済みであることを確認
gh auth status
```

#### 既に存在しているデータを元にYAMLファイルを生成
```bash
./scripts/export-members-yaml.sh > data/members.yaml
./scripts/export-teams-yaml.sh > data/teams.yaml
./scripts/export-actions-enabled-repos.sh > data/actions-enabled-repositories.yaml
```
- 既存のYAMLファイルがある場合は、一時ファイル（例：`data/tmp_members.yaml`）に出力するなどして、手動でマージしてください

#### YAMLファイルの手動編集
必要に応じてYAMLファイルを編集します。特に、members.yamlのメールアドレスの追加は手動で行う必要があります。

#### importブロックファイルの生成とインポートの実行

```bash
# Terraformの初期化
terraform init

# ユーザーのimportファイルを生成
./scripts/generate-members-import.sh > users-import.tf

# チームのimportファイルを生成
./scripts/generate-teams-import.sh > teams-import.tf

# GitHub Actions組織権限のimportファイルを作成
cat > actions-import.tf << 'EOF'
import {
  to = github_actions_organization_permissions.org_actions
  id = "rfgricoh"
}
EOF

# インポートの計画を確認（差分がないことを確認）
# 差分がある場合は、YAMLファイルやTerraformコードを実際の設定に合わせて調整し、再度確認する
terraform plan

# 差分がなくなったらインポートを実行
terraform apply
```

#### インポート結果の確認
```bash
# importファイルを削除（インポート後は不要）
rm users-import.tf teams-import.tf actions-import.tf

# 最終的な差分確認
terraform plan
```
差分がないことを確認してください。差分が表示される場合は、YAMLファイルの設定を実際の状態に合わせて調整してください
