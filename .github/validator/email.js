import validator from 'validator'

/**
 * メールアドレスの形式をバリデーションする
 * 
 * validator.jsライブラリを使用してメールアドレス形式をチェック
 * 
 * @param {string} email - バリデーション対象のメールアドレス
 * @returns {string} 'success' または エラーメッセージ
 */
export default function validateEmail(email) {
    // 空文字チェック
    if (!email || typeof email !== 'string') {
        return 'メールアドレスが入力されていません'
    }

    // 前後の空白を除去
    const trimmedEmail = email.trim()

    // validator.jsを使用してメールアドレス形式をチェック
    if (!validator.isEmail(trimmedEmail)) {
        return 'メールアドレスの形式が正しくありません（例: user@example.com）'
    }

    return 'success'
}
