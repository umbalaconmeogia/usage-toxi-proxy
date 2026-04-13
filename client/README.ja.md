[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# 仕様：クライアント

## 1. 概要

`client.ps1` は、**テスト目的のクライアントプログラム**であり、サーバー（または Toxiproxy などのプロキシ）に対して**事前に定義されたシナリオに従って HTTP リクエストを送信し**、ターゲットシステムの処理動作、再試行、およびフォールトトレランス（障害耐性）をテストする役割を担います。

このプログラムは以下を目的として設計されています：

* **標準的な Windows 環境**で動作すること
* 追加のフレームワークやランタイムに依存しないこと
* 本番システムから独立して動作すること

---

## 2. 構文 (Syntax)

```powershell
program.ps1 [<scenario file>]
```

| パラメータ          | 説明                                                       |
| :----------------- | :-------------------------------------------------------- |
| `<scenario file>` | リクエストシナリオ को 記述した CSV ファイル。例：`scenario.csv` |

### 2.2 デフォルト値

| パラメータ          | デフォルト値       |
| :----------------- | :----------------- |
| `<scenario file>` | `scenario.csv`     |

---

## 3. シナリオファイルの形式

### 3.1 ファイル：`scenario.csv`

シナリオファイルは、以下の列を持つ CSV ファイルです：

```csv
method, url, param, remarks
```

| 列         | 説明                                                                                                                                                              |
| :--------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `method`   | HTTP メソッド (GET, POST, PUT, DELETE, ...) または擬似メソッド `WAIT`。                                                                                             |
| `url`      | 完全な URL（例：`http://localhost:12000/api/data`）。method が `WAIT` の場合は省略可能です。                                                                          |
| `param`    | 付随するパラメータ： <br>- `method` が `WAIT` の場合：待機する秒数。 <br>- `method` が `POST` の場合：送信するリクエストボディの内容。 |
| `remarks`  | シナリオのメモ（ロジックには影響しません）。                                                                                                                      |

### 3.2 例

```csv
method, url, param, remarks
GET, http://localhost:12000/api/data,, normal request
WAIT,, 5, wait 5 seconds
POST, http://localhost:12000/api/data, {"id": 1}, post request
GET, http://localhost:12001/api/token,, get token from server 2
```

---

## 4. 機能 (Behavior)

`client.ps1` は以下の手順を実行します：

1. 指定されたシナリオ CSV ファイルを読み込みます。
2. シナリオファイルの各行を順番に処理します。
3. 各行に対して：
   * `method` が `WAIT` の場合：
     * `param` 列で指定された秒数待機します。
   * `method` がリクエスト（GET, POST, ...）の場合：
     * CSV ファイルから完全な URL と対応するメソッドを取得します。
     * `POST` の場合は、`param` 列の内容をボディとして使用します。
     * 備考（remarks）があれば表示します。
     * 指定された URL に HTTP リクエストを送信します。
     * サーバーからレスポンスを受信します。
     * 規定の形式で画面にログを記録します。
4. シナリオ全体の処理が終わると終了します。

---

## 5. 画面表示 (Log output)

プログラムは、以下の固定形式でコンソールにログを記録します：

### 5.1 リクエスト送信時

```text
[yyyymmdd hhiiss] Send request: <method> <request url>
```

### 5.2 レスポンス受信時

```text
[yyyymmdd hhiiss] Receive response: <http code> <response>
```

### 5.3 例

```text
[20260409 141530] Send request: GET http://localhost:2000/api/data
[20260409 141530] Receive response: 200 DATA_OK
```

---

## 6. エラー処理 (Error handling)

* HTTP リクエストでエラー（タイムアウト、接続エラー、ネットワークエラー）が発生した場合：
  * エラーを記録します
  * `<response>` セクションにエラー情報を表示します
* プログラムは、リクエストでエラーが発生しても**突然停止することはありません**。次のシナリオの処理を（待機時間後に）継続します。

---

## 7. 利用範囲 (Scope)

`client.ps1` は以下の用途に使用されます：

* √ システムテスト (System Test - ST)
* √ 再試行 / フォールトトレランステスト
* √ 以下の環境でのテスト：
  * PowerShell テストサーバー
  * Toxiproxy
  * 模擬 API エンドポイント

以下の用途には使用されません：

* 本番環境 (Production)
* 負荷テスト (Load test)
* パフォーマンステスト

---

## 8. まとめ

> `client.ps1` は、CSV シナリオに基づいて動作し、サーバー/プロキシに対して HTTP リクエストを順次送信し、結果を記録し、システムテストにおける再試行/障害処理のテストをサポートするクライアントプログラムです。
