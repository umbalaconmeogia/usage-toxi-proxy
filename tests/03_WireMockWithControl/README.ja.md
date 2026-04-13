[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Toxiproxy経由でのサーバーへのクライアントアクセス

## 概要

このテストでは、クライアントはWireMockを介してサーバーに接続し、変更（遅延、エラー）が適用されます。
* /api/tokenの初回呼び出し時にエラーを発生させ、HTTP 500を返します。
* /api/logicの初回呼び出し時にロジックエラーを発生させ、HTTP 200を返しますが、レスポンスボディでクライアントにエラーが発生したことを示します。
* タイムアウトエラーを発生させます。

```mermaid
graph LR
    Client["クライアント"] -- "リクエスト (ポート 13000)" --> WM_Proxy["WireMock"]
    WM_Proxy -- "転送 (ポート 12000)" --> Server["サーバー"]
  
    subgraph "WireMock プロセス"
        WM_Proxy
        WM_Mappings["マッピング<br>00_default_proxy<br>01_500_on_token<br>02_logic_error<br>03_timeout"]
    end
```

## テスト手順

* **WireMockの起動**
  `tests\03_WireMockWithControl` フォルダに移動して実行します：
  ```powershell
   dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
  ```
* **サーバーの起動**
  `tests\03_WireMockWithControl` フォルダに移動して実行します：
  ```powershell
  ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
  ```
* **クライアントの起動**
  `tests\03_WireMockWithControl` フォルダに移動して実行します：
  ```powershell
  ..\..\client\client.ps1 .\scenario-client.csv
  ```
* **サーバーの停止**
  すべてのクライアントリクエストが送信された後、サーバーのターミナルで **Ctrl+C** を押して停止します。

## リクエストフローの説明

以下は、`output.md` ログとシナリオファイルによって検証されたリクエストシーケンスです。WireMockは特定のルートをインターセプトしてエラーをシミュレートし、それ以外を透過的にサーバーに転送します。

```mermaid
sequenceDiagram
    participant Client
    participant WM as WireMock
    participant Server

    Note over Client: シナリオ開始

    Client->>WM: GET /api/get-data (ポート 13000)
    WM->>Server: 転送 (ポート 12000)
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Client->>WM: GET /api/post-data
    WM->>Server: 転送
    Note right of Server: シナリオ不一致（このパスにGETが定義されていません）
    Server-->>WM: 200 UNKNOWN request
    WM-->>Client: 200 UNKNOWN request

    Client->>WM: POST /api/post-data (body: abc)
    WM->>Server: 転送
    Server-->>WM: 200 POST_DATA_OK
    WM-->>Client: 200 POST_DATA_OK

    Client->>WM: GET /api/token
    Note over WM: マッピング 01: 初回呼び出しをインターセプトし、<br/>500を返す (シナリオ: Token_Failed_Once)
    WM-->>Client: 500 Internal Server Error

    Client->>WM: GET /api/token (再試行)
    WM->>Server: 転送 (シナリオ状態: Will_Pass_Next_Time)
    Server-->>WM: 200 TOKEN_OK
    WM-->>Client: 200 TOKEN_OK

    Client->>WM: GET /api/get-data
    WM->>Server: 転送
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Client->>WM: GET /api/logic
    Note over WM: マッピング 02: 初回呼び出しをインターセプトし、<br/>LOGIC_ERRORを返す (シナリオ: Logic_Error_One)
    WM-->>Client: 200 Logic_ERROR by WireMock

    Client->>WM: GET /api/logic (再試行)
    WM->>Server: 転送 (シナリオ状態: Data_Will_Be_Fixed_Next_Time)
    Server-->>WM: 200 LOGIC_OK
    WM-->>Client: 200 LOGIC_OK

    Client->>WM: GET /api/timeout
    Note over WM: マッピング 03: 60秒の遅延で転送
    WM->>Server: 転送 (ポート 12000)
    Note right of Server: /api/timeout のハンドラーなし
    Server-->>WM: 200 UNKNOWN request
    Note over Client,WM: クライアントは30秒後にタイムアウト (WMが応答する前)
    WM--xClient: エラー (タイムアウト — レスポンスが配信されませんでした)

    Note over Client: シナリオ終了
```
