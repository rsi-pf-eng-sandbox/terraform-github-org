/**
 * GitHubユーザー名の形式をバリデーションし、以下をチェックする:
 * 1. ユーザー名の形式が正しいか
 * 2. ユーザーが実際に存在するか
 * 3. ユーザーがmembers.yamlに既に登録されていないか
 * 
 * GitHubユーザー名のルール:
 * - 1-39文字
 * - 英数字とハイフン(-)のみ使用可能
 * - ハイフンで始まったり終わったりできない
 * - 連続したハイフンは使用できない
 * 
 * @param {string} username - バリデーション対象のGitHubユーザー名
 * @returns {Promise<string>} 'success' または エラーメッセージ
 */
export default async function validateUsername(username) {
    // 空文字チェック
    if (!username || typeof username !== 'string') {
        return 'GitHubユーザー名が入力されていません'
    }

    // 前後の空白を除去
    const trimmedUsername = username.trim()

    // GitHubユーザー名の形式チェック
    // - 1-39文字
    // - 英数字とハイフン(-)のみ
    // - ハイフンで始まったり終わったりしない
    // - 連続したハイフンは使用不可
    // cf. https://github.com/shinnn/github-username-regex
    const gitHubUserNameRegex = /^[a-z\d](?:[a-z\d]|-(?=[a-z\d])){0,38}$/i
    const isValidFormat = gitHubUserNameRegex.test(trimmedUsername)

    if (!isValidFormat) {
        return 'ユーザー名が有効な形式ではありません（1-39文字、英数字とハイフンのみ、ハイフンは先頭・末尾・連続使用不可）'
    }

    // @octokit/restを使用してGitHub APIにアクセス
    const { Octokit } = await import('@octokit/rest')
    const core = await import('@actions/core')
    const fs = await import('fs')
    const YAML = await import('yaml')

    const octokit = new Octokit({
        auth: core.getInput('github-token', { required: true }),
    })

    try {
        // 1. GitHubユーザーが存在するかチェック
        core.info(`Checking if user '${trimmedUsername}' exists`)

        let userData
        try {
            const userResponse = await octokit.rest.users.getByUsername({
                username: trimmedUsername
            })
            userData = userResponse.data
        } catch (error) {
            if (error.status === 404) {
                return `GitHubユーザー '${trimmedUsername}' が見つかりません。ユーザー名を確認してください`
            }
            throw error
        }

        // アカウントタイプのチェック
        if (userData.type !== 'User') {
            return `'${trimmedUsername}' は有効なGitHubユーザーアカウントではありません（タイプ: ${userData.type}）`
        }

        core.info(`User '${trimmedUsername}' exists`)

        // 2. members.yamlにユーザーが既に登録されていないかチェック
        core.info(`Checking if user '${trimmedUsername}' is already in members.yaml`)

        const workspace = core.getInput('workspace', { required: true })
        const membersYamlPath = `${workspace}/data/members.yaml`

        if (fs.existsSync(membersYamlPath)) {
            const membersYamlContent = fs.readFileSync(membersYamlPath, 'utf8')
            const membersData = YAML.parse(membersYamlContent)

            const existingMember = membersData.members?.find(
                member => member.username.toLowerCase() === trimmedUsername.toLowerCase()
            )

            if (existingMember) {
                return `ユーザー '${trimmedUsername}' は既に members.yaml に登録されています`
            }

            core.info(`User '${trimmedUsername}' is not in members.yaml`)
        } else {
            core.warning(`members.yaml not found at ${membersYamlPath}`)
        }

        return 'success'
    } catch (error) {
        // その他のエラー
        core.error(`Validation error: ${error.message}`)
        return `バリデーション中にエラーが発生しました: ${error.message}`
    }
}
