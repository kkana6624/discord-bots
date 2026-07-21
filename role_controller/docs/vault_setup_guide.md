# OCI Vault および 環境変数 設定ガイド

本番運用に向けて、シークレット（機密情報）を安全に管理するための OCI Vault の設定方法、および `.env` ファイルを利用したローカルでの設定方法を解説します。

---

## 1. ローカル・開発環境での設定 (.env の利用)

リポジトリに含まれている `.env.sample` をコピーして `.env` を作成し、IDを埋めて実行します。

```bash
# テンプレートをコピー
cp .env.sample .env

# ファイルを編集して各IDとトークンを入力
nano .env
```

`.env` には平文でトークンが含まれるため、**絶対にGitにコミットしないでください**（`.gitignore` で除外されていますが、念のため注意してください）。

ローカルでDockerコンテナを起動する場合は、以下のように読み込ませます。
```bash
docker run -d --env-file .env role_controller:latest
```

---

## 2. 本番環境での設定 (OCI Vault を用いたセキュア運用)

本番環境（OCI Compute インスタンス）では、最も機密性の高い `DISCORD_TOKEN` をコンテナの環境変数に直接渡すことを避け、OCI Vault（暗号化キーストア）に預けます。

コンテナの起動スクリプト（`entrypoint.sh`）は、起動時にVaultから安全にトークンを取り出してメモリ上でのみ展開します。

### Step 1: OCI Vault での Secret の作成
1. OCIコンソールのメニューから **「アイデンティティとセキュリティ (Identity & Security)」** > **「Vault」** を開きます。
2. Vaultを作成（または既存のものを選択）し、**「マスター暗号化キー (Master Encryption Key)」** を作成します。
3. **「シークレット (Secrets)」** メニューを開き、「シークレットの作成」をクリックします。
4. 以下の通り入力します：
   - **名前**: 任意の分かりやすい名前（例: `DiscordBotToken`）
   - **説明**: 任意
   - **シークレット・コンテンツ・テンプレート (Secret Contents)**: `プレーン・テキスト (Plain-Text)` を選択します。
   - **シークレット・コンテンツ**: Discord Developer Portalからコピーした Bot のトークン（例: `MTI...`）を**改行や空白を含めずにそのまま**貼り付けます。
   ※ base64エンコード等を事前に行う必要はありません。コンソールからプレーンテキストで入力すると、OCI側でAPIレスポンス時に自動的にbase64化し、コンテナ側（`entrypoint.sh`）で自動的にデコードする設計になっています。
5. 作成後、詳細画面から **「シークレットのOCID (Secret OCID)」** をコピーして控えておきます。（`ocid1.vaultsecret.oc1...` で始まる文字列です）

### Step 2: IAM (動的グループとポリシー) の設定
ComputeインスタンスがVaultのシークレットを読み取れるようにします。
1. **アイデンティティ > 動的グループ (Dynamic Groups)** を作成し、コンテナを動かすインスタンスを所属させます。
   - ルール例: `ANY {instance.id = 'あなたのインスタンスのOCID'}`
2. **アイデンティティ > ポリシー (Policies)** を作成し、動的グループに読み取り権限を与えます。
   - 構文例: `Allow dynamic-group <動的グループ名> to read secret-bundles in compartment <コンパートメント名>`

### Step 3: コンテナの起動コマンド
トークン以外の変数（サーバーIDやロールID）は機密情報ではないため、通常の環境変数としてコンテナに渡します。`DISCORD_TOKEN` の代わりに、先ほどコピーした `VAULT_SECRET_OCID` を指定します。

```bash
docker run -d \
  --name discord-role-controller \
  --restart always \
  -e VAULT_SECRET_OCID="ocid1.vaultsecret.oc1.ap-tokyo-1.xxxxxxxxxxxxxxxxxxxx" \
  -e GUILD_ID="123456789012345678" \
  -e ROLE_A_ID="111111111111111111" \
  -e ROLE_B_ID="222222222222222222" \
  -e TARGET_ROLE_C_ID="333333333333333333" \
  role_controller:latest
```

これで、コンテナは起動時にOCI APIを叩き、セキュアにトークンを取得してBotを稼働させます。サーバーのプロセスリスト等からトークンが漏洩することはありません。
