[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# WireMock経由でのサーバーへのクライアントアクセス（コントローラーなし）

## 概要

このテストでは、クライアントは透過プロキシとして動作するWireMockを介してサーバーに接続しますが、変更（遅延、エラーなど）は適用されません。これは、WireMockのデフォルトのパススルー動作を示しています。

```mermaid
graph LR
    Client["クライアント"] -- "リクエスト (ポート 13000)" --> WM_Proxy["WireMock\n(プロキシポート)"]
    WM_Proxy -- "転送 (ポート 12000)" --> Server["サーバー"]
  
    subgraph "WireMock プロセス"
        WM_Proxy
        WM_Admin["管理用 API\n(ポート 9091)"]
    end
```

## テスト手順

* **WireMock の起動**
   `tests\02_WireMockWithoutControl` フォルダに移動し、以下を実行します：
   ```powershell
   dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
   ```
* **サーバーの起動**
   `tests\02_WireMockWithoutControl` フォルダに移動し、以下を実行します：
   ```powershell
   ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
   ```
* **クライアントの起動**
   `tests\02_WireMockWithoutControl` フォルダに移動し、以下を実行します：
   ```powershell
   ..\..\client\client.ps1 .\scenario-client.csv
   ```
* **サーバーの停止**
   すべてのクライアントリクエストが送信された後、サーバーのターミナルで **Ctrl+C** を押して停止します。

## リクエストフローの説明

以下は、`output.md` ログとシナリオファイルによって確認されたリクエストシーケンスです。エラーは挿入されていませんが、リクエストはポート 13000 にある WireMock の透過プロキシを介して渡されます。

```mermaid
sequenceDiagram
    participant Client as クライアント
    participant WM as WireMock
    participant Server as サーバー

    Note over Client: シナリオ開始

    Client->>WM: GET /api/get-data (ポート 13000)
    WM->>Server: 転送 (ポート 12000)
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Note over Client: 1秒待機 (WAIT)

    Client->>WM: GET /api/post-data
    WM->>Server: 転送
    Note right of Server: シナリオの不一致（このパスに GET が定義されていない）
    Server-->>WM: 200 UNKNOWN request
    WM-->>Client: 200 UNKNOWN request

    Note over Client: 2秒待機 (WAIT)

    Client->>WM: POST /api/post-data (body: abc)
    WM->>Server: 転送
    Server-->>WM: 200 POST_DATA_OK
    WM-->>Client: 200 POST_DATA_OK

    Note over Client: 3秒待機 (WAIT)

    Client->>WM: GET /api/token
    WM->>Server: 転送
    Server-->>WM: 200 TOKEN_OK
    WM-->>Client: 200 TOKEN_OK

    Note over Client: シナリオ終了
```
