/**
 * チーム名のバリデーション
 * teams.yamlに登録されているかをチェックする
 * 
 * @param {string} field - バリデーション対象のフィールド
 * @returns {Promise<string>} 'success' または エラーメッセージ
 */
export default async function validateTeam(field) {
    const core = await import('@actions/core')
    const fs = await import('fs')
    const YAML = await import('yaml')

    // 空文字や配列が空の場合はスキップ（任意項目の場合）
    if (!field || (Array.isArray(field) && field.length === 0)) {
        return 'success'
    }

    // フィールドが文字列の場合は配列に変換（1つのチーム名）
    // 配列の場合はそのまま使用（複数のチーム名）
    let teamNames = []

    if (typeof field === 'string') {
        // 改行で分割して配列にする（textareaで複数行入力された場合を考慮）
        teamNames = field.split('\n')
            .map(name => name.trim())
            .filter(name => name.length > 0)
    } else if (Array.isArray(field)) {
        teamNames = field
    } else {
        return 'フィールドの型が無効です（stringまたはstring[]を期待）'
    }

    // チーム名が指定されていない場合は成功
    if (teamNames.length === 0) {
        return 'success'
    }

    try {
        const workspace = core.getInput('workspace', { required: true })
        // teams.yamlを読み込む
        const teamsYamlPath = `${workspace}/data/teams.yaml`

        if (!fs.existsSync(teamsYamlPath)) {
            core.warning(`teams.yaml not found at ${teamsYamlPath}`)
            return 'teams.yaml が見つかりません'
        }

        const teamsYamlContent = fs.readFileSync(teamsYamlPath, 'utf8')
        const teamsData = YAML.parse(teamsYamlContent)

        const registeredTeams = teamsData.teams?.map(team => team.name) || []

        // 各チーム名をバリデーション
        for (const teamName of teamNames) {
            core.info(`Validating team '${teamName}'`)

            // チームがteams.yamlに登録されているかチェック
            if (!registeredTeams.includes(teamName)) {
                core.error(`Team '${teamName}' is not registered in teams.yaml`)
                return `チーム '${teamName}' は teams.yaml に登録されていません`
            }

            core.info(`Team '${teamName}' is registered in teams.yaml`)
        }

        return 'success'
    } catch (error) {
        core.error(`Validation error: ${error.message}`)
        return `バリデーション中にエラーが発生しました: ${error.message}`
    }
}
