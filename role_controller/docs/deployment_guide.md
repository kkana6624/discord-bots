# OCI 本番環境デプロイメント手順書

このドキュメントは、Discord AND条件ロール自動管理BotをOracle Cloud Infrastructure (OCI) の VM (Always Free枠等のコンテナ環境) 上に本番デプロイするための完全な手順書です。

## 1. Discord Developer Portal の事前準備 (重要)
Discord APIからメンバー情報やロール変更イベントを受け取るため、Botに特別な権限（Privileged Intents）を付与する必要があります。

1. [Discord Developer Portal](https://discord.com/developers/applications) にログインし、作成したアプリケーションを選択します。
2. 左側メニューの **[Bot]** を選択します。
3. **Privileged Gateway Intents** セクションまでスクロールします。
4. **`SERVER MEMBERS INTENT`** のトグルをオンにして保存します。
   > [!WARNING]
   > この設定がONになっていないと、`GUILD_MEMBER_UPDATE`イベントを受信できず、Botはメンバーの権限変更を検知できません。

---

## 2. OCI IAM と Vault の構成 (セキュアな構成)

クレデンシャルをファイルに直書きしないため、OCI Vault と Instance Principal を活用します。

### 2.1 動的グループ (Dynamic Group) の作成
Computeインスタンスが自身の権限でVaultにアクセスできるようにします。
1. OCI コンソールから **Identity & Security > Dynamic Groups** に移動。
2. 新しい動的グループを作成（例: `DiscordBot-DynamicGroup`）。
3. 以下のルールを追加して対象のコンピュートインスタンスを含めます（OCIDは適宜変更）。
   `ANY {instance.id = 'ocid1.instance.oc1...あなたのインスタンスOCID'}`

### 2.2 OCI Vault と Secret の作成
1. **Identity & Security > Vault** から新規Vaultを作成。
2. Master Encryption Keyを作成。
3. 新しい **Secret** を作成（例: `DiscordBotToken`）。
   - ContentsにBotのDiscord Tokenを**プレーンテキスト**で貼り付けます。
4. 作成された Secret の詳細画面を開き、 **Secret OCID** を控えておきます。

### 2.3 ポリシー (Policy) の作成
動的グループに対して、対象Secretの読み取り権限を付与します。
1. **Identity & Security > Policies** に移動し、新規ポリシーを作成。
2. 以下のステートメントを追加:
   `Allow dynamic-group DiscordBot-DynamicGroup to read secret-bundles in compartment あなたのコンパートメント名`

---

## 3. インスタンスへのデプロイと起動

### 3.1 ソースコードの配置とビルド
対象のOCIインスタンス（Ubuntu/Oracle Linux等）にSSH接続し、ソースコードをクローンしてイメージをビルドします。

```bash
# プロジェクトディレクトリへ移動
cd /path/to/role_controller

# 本番用のマルチステージビルドを実行
sudo docker build -t role_controller:latest .
```

### 3.2 コンテナの起動
取得した Secret OCID や サーバーID（Guild ID）、ロールIDを指定してコンテナを起動します。

```bash
sudo docker run -d \
  --name discord-role-controller \
  --restart always \
  -e VAULT_SECRET_OCID="ocid1.vaultsecret.oc1...控えたSecret_OCID..." \
  -e GUILD_ID="123456789012345678" \
  -e ROLE_A_ID="111111111111111111" \
  -e ROLE_B_ID="222222222222222222" \
  -e TARGET_ROLE_C_ID="333333333333333333" \
  role_controller:latest
```

### 3.3 動作確認とログ監視
コンテナが起動し、OCI Vaultから正しくシークレットを取得してBotが稼働しているか確認します。

```bash
# ログの確認
sudo docker logs -f discord-role-controller
```
以下のようなログが出力されていれば成功です。
- `Fetching secret from OCI Vault using Instance Principal...`
- `Secret successfully fetched and exported.`
- `Starting Elixir production release...`

---

## 4. トラブルシューティング

- **`Invalid token format` でクラッシュする**:
  OCI Vaultから正しく値が引けていないか、Vaultに保存した内容に余分な空白や改行が含まれている可能性があります。VaultのSecretの内容を確認してください。
- **ロールが付与/剥奪されない**:
  Discord Portalで `SERVER MEMBERS INTENT` をONにし忘れているか、Bot自身のロールが「ターゲットロールC」よりも上の階層（ロール設定画面での順位）に配置されていない可能性があります。Discordサーバーの設定で、Botの役割をターゲットロールの上にドラッグ＆ドロップしてください。
