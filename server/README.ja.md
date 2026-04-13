[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# 仕様書: server.ps1

## 1. 概要 (Overview)

`server.ps1` は、システムテスト（ST）、特にリトライ、フォルトトレランス、およびプロキシ（例：Toxiproxy）に関連するテストにおいて、**API サーバーの動作をシミュレートする**ために使用される**シンプルな HTTP テストサーバー**です。

サーバーは、どのリクエストに対してどのレスポンスを返すかを定義したシナリオ CSV ファイルに基づいて動作し、制御されたテスト環境を作成します。

***

## 2. 構文 (Syntax)

```powershell
server.ps1 <scenario file> <url> <wait_time_in_second>
```
例:
```powershell
server.ps1 scenario.csv http://localhost:2000 5
```

***

#### 2.1 パラメーター

| パラメーター             | 説明                                                           |
| :----------------------- | :------------------------------------------------------------- |
| `<scenario file>`       | サーバーシナリオを記述した CSV ファイル。例: `server-scenario.csv` |
| `<url>`                 | サーバーがリッスンするベース URL。例: `http://localhost:2000` |
| `<wait time in second>` | レスポンスを返した後にサーバーが待機する時間（秒）            |

***

#### 2.2 デフォルト値

| パラメーター             | デフォルト値            |
| :----------------------- | :---------------------- |
| `<scenario file>`       | `server-scenario.csv`   |
| `<url>`                 | `http://localhost:2000` |
| `<wait time in second>` | `0`                     |

***

### 3. シナリオファイルの形式

#### 3.1 `server-scenario.csv` ファイル

CSV ファイルには以下の列が必要です。

```csv
method, request, response
```

| 列         | 説明                                     |
| :--------- | :--------------------------------------- |
| `method`   | HTTP メソッド (GET, POST, PUT, DELETE, ...) |
| `request`  | URL パス (例: `/api/data`)               |
| `response` | 返されるレスポンスの内容                |

***

#### 3.2 例

```csv
method, request, response
GET, /api/data, DATA OK
POST, /api/data, DATA POST_OK
GET, /api/token, TOKEN OK
```

***

### 4. 動作 (Behavior)

起動時、`server.ps1` は以下の手順を実行します。

1.  指定されたシナリオ CSV ファイルを読み込みます。
2.  指定された `<url>` で HTTP リクエストをリッスンします。
3.  リクエスト受信時:
    * ログ: `[yyyymmdd hhmiss] Receive request: <method> <request>`
    * **特別な処理**: パスが `/stop-server` の場合、サーバーは `SERVER STOPPED` を返し、自動的に停止します。
    * CSV ファイル内のシナリオと `(method, request)` のペアを照合します。
    * 見つかった場合:
        * 対応する `response` を返します。
        * ログ: `[yyyymmdd hhmiss] Receive request: <method> <request>`
    * 見つからない場合:
        * `UNKNOWN request` を返します。
        * ログ: `[yyyymmdd hhmiss] Receive UNKNOWN request: <method> <request>`
    * ログ: `[yyyymmdd hhmiss] Return response: <response>`
4.  レスポンスを返した後、`<wait time in second>`（0 より大きい場合）待機します。
5.  バックグラウンドで次のリクエストの処理を継続します。
6.  **Ctrl + C** シグナルを受信するとサーバーは停止します。

***

### 5. ログ出力

#### 5.1 リクエスト受信

```text
[yyyymmdd hhmiss] Receive [UNKNOWN] request: <method> <request>
```

*(注: リクエストがシナリオにない場合、`UNKNOWN` プレフィックスが追加されます)*

#### 5.2 レスポンス返却

```text
[yyyymmdd hhmiss] Return response: <response>
```

***

### 6. 使用範囲 (Scope)

`server.ps1` は以下の用途に使用されます。

* システムテスト (ST)
* リトライ / フォルトトレランステスト
* 以下のツールとの組み合わせテスト:
    * `client.ps1`
    * Toxiproxy
    * コントローラー (PowerShell / VBA)

以下の用途には適していません。

* 本番環境 (Production)
* パフォーマンステスト
* 負荷テスト (Load test)

***

### 7. まとめ

`server.ps1` は、CSV シナリオと指定されたベース URL に従って動作する HTTP テストサーバーであり、リクエストごとにレスポンスを制御できます。このツールは、システムテストにおけるリトライとエラー処理のテストを効果的にサポートします。
