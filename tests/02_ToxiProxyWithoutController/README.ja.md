[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Toxiproxy経由でのサーバーへのクライアントアクセス（コントローラーなし）

## 概要

このテストでは、クライアントはToxiproxyを介してサーバーに接続しますが、変更（遅延、エラーなど）は適用されません。これは、Toxiproxyのデフォルトのパススルー動作を示しています。

```mermaid
graph LR
    Client["クライアント"] -- "リクエスト (ポート 13000)" --> TP_Proxy["Toxiproxy\n(プロキシポート)"]
    TP_Proxy -- "転送 (ポート 12000)" --> Server["サーバー"]
  
    subgraph "Toxiproxy プロセス"
        TP_Proxy
        TP_Admin["管理用 API\n(ポート 8474)"]
    end
```

## テスト手順

* **サーバーの起動**
   `tests\02_ToxiProxyWithoutController` フォルダに移動し、以下を実行します：
   ```powershell
   ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
   ```
* **ToxiProxy の起動**
   `tests\02_ToxiProxyWithoutController` フォルダに移動し、以下を実行します：
   ```powershell
    ..\..\toxiproxy\toxiproxy-server-windows-amd64.exe -config ..\..\toxiproxy\server1-config.json
   ```
* **クライアントの起動**
   `tests\02_ToxiProxyWithoutController` フォルダに移動し、以下を実行します：
   ```powershell
   ..\..\client\client.ps1 .\scenario-client.csv
   ```
* **サーバーの停止**
   すべてのクライアントリクエストが送信された後、サーバーのターミナルで **Ctrl+C** を押して停止します。

## リクエストフローの説明

以下は、`output.md` ログとシナリオファイルによって確認されたリクエストシーケンスです。エラーは挿入されていませんが、リクエストはポート 13000 にある Toxiproxy の「ミラー」を介して渡されます。

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant TP as Toxiproxy
    participant Server as サーバー

    Note over Client: シナリオ開始

    Client->>TP: GET /api/get-data (ポート 13000)
    TP->>Server: 転送 (ポート 12000)
    Server-->>TP: 200 GET_DATA_OK
    TP-->>Client: 200 GET_DATA_OK

    Note over Client: 1秒待機 (WAIT)

    Client->>TP: GET /api/post-data
    TP->>Server: 転送
    Note right of Server: シナリオの不一致（このパスに GET が定義されていない）
    Server-->>TP: 200 UNKNOWN request
    TP-->>Client: 200 UNKNOWN request

    Note over Client: 2秒待機 (WAIT)

    Client->>TP: POST /api/post-data (body: abc)
    TP->>Server: 転送
    Server-->>TP: 200 POST_DATA_OK
    TP-->>Client: 200 POST_DATA_OK

    Note over Client: 3秒待機 (WAIT)

    Client->>TP: GET /api/token
    TP->>Server: 転送
    Server-->>TP: 200 TOKEN_OK
    TP-->>Client: 200 TOKEN_OK

    Note over Client: シナリオ終了
```
