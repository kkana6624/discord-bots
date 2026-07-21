# Discord AND条件ロール自動管理Bot (Role Controller)

Discordの標準機能では実現できない「ロールAかつロールBを持っているユーザーにのみ、ロールCを付与する」というAND条件による権限管理を自動化するバックグラウンドBotです。

## 機能
- **リアルタイム付与/剥奪**: メンバーのロール更新イベントを検知し、AND条件を満たした瞬間にターゲットロールを付与します。条件が満たされなくなった場合は即座に剥奪します。
- **自動修復 (Reconciliation)**: BotのダウンタイムやAPIエラーによる変更の取りこぼしを防ぐため、1時間ごとに全メンバーをスキャンし、ロールの不整合を自動で修復します。

## 環境変数
Botを稼働させるためには、以下の環境変数を設定する必要があります。

| 変数名 | 説明 |
| ------ | ---- |
| `DISCORD_TOKEN` | Discord Developer Portalで取得したBotのトークン |
| `GUILD_ID` | Botを稼働させる対象のDiscordサーバー（Guild）ID |
| `ROLE_A_ID` | AND条件となるロール1のID |
| `ROLE_B_ID` | AND条件となるロール2のID |
| `TARGET_ROLE_C_ID` | 条件を満たした際に自動付与（および自動剥奪）されるターゲットロールのID |

---

## ローカルでの実行方法 (開発環境)

Elixir (>= 1.18) がインストールされている環境で実行します。

```bash
# 依存関係のインストール
mix deps.get

# 環境変数を指定して起動
DISCORD_TOKEN="Your_Token" \
GUILD_ID="123456789" \
ROLE_A_ID="111" \
ROLE_B_ID="222" \
TARGET_ROLE_C_ID="333" \
mix run --no-halt
```

---

## コンテナでの実行方法 (OCIへのデプロイ)

本Botはコンテナ（Docker/Podman）として動作するよう設計されており、特にOracle Cloud Infrastructure (OCI) のVM上での運用を前提としています。

### 1. イメージのビルド
```bash
docker build -t role_controller:latest .
```

### 2. 環境変数ファイルを使用した標準的な実行
`.env` ファイルを作成して必要な変数を記述し、コンテナを起動します。

```bash
docker run -d \
  --name role-controller \
  --restart always \
  --env-file .env \
  role_controller:latest
```

### 3. OCI Vaultを利用したシークレット管理での実行 (推奨)

セキュリティ向上のため、平文の `.env` ではなくOCI Vaultを利用して実行時に動的注入を行う構成です。コンテナの `entrypoint.sh` がOCI CLIを内包しているため、自動で読み込みます。

**前提条件**:
- コンテナを動かすOCI Computeインスタンスが「動的グループ」に所属していること
- 動的グループに対してOCI VaultのSecret Bundleを読み取るIAMポリシーが付与されていること

**実行コマンド**:
`DISCORD_TOKEN` をコンテナに渡す代わりに、VaultのOCIDを `VAULT_SECRET_OCID` として渡します。

```bash
docker run -d \
  --name role-controller \
  --restart always \
  -e VAULT_SECRET_OCID="ocid1.vaultsecret.oc1..." \
  -e GUILD_ID="123456789" \
  -e ROLE_A_ID="111" \
  -e ROLE_B_ID="222" \
  -e TARGET_ROLE_C_ID="333" \
  role_controller:latest
```

## テストの実行

```bash
mix test
```
