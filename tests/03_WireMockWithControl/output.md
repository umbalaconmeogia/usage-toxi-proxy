# Ouput

## Server

```
PS tests\03_WireMockWithControl> ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
[INFO] Server started at http://localhost:12000/
[INFO] Press Ctrl+C to stop.
[20260414 011331] Receive request: GET /api/get-data
[20260414 011331] Return response: GET_DATA_OK
[20260414 011334] Receive UNKNOWN request: GET /api/post-data
[20260414 011334] Return response: UNKNOWN request
[20260414 011337] Receive request: POST /api/post-data
[20260414 011337] Return response: POST_DATA_OK
[20260414 011340] Receive request: GET /api/token
[20260414 011340] Return response: TOKEN_OK
[20260414 011343] Receive request: GET /api/get-data
[20260414 011343] Return response: GET_DATA_OK
[20260414 011346] Receive request: GET /api/logic
[20260414 011346] Return response: LOGIC_OK
[20260414 011446] Receive UNKNOWN request: GET /api/timeout
[20260414 011446] Return response: UNKNOWN request
```

## Client

```
PS tests\03_WireMockWithControl> ..\..\client\client.ps1 .\scenario-client.csv
[INFO] Scenario file: .\scenario-client.csv

[20260414 011330] Send request: GET http://localhost:13000/api/get-data
         Remarks: Normal GET request
[20260414 011331] Receive response: 200 GET_DATA_OK

[20260414 011331] Send request: GET http://localhost:13000/api/post-data
         Remarks: Error without trying
[20260414 011334] Receive response: 200 UNKNOWN request

[20260414 011334] Send request: POST http://localhost:13000/api/post-data
         Remarks: Normal POST request
[20260414 011337] Receive response: 200 POST_DATA_OK

[20260414 011337] Send request: GET http://localhost:13000/api/token
         Remarks: Error 500
[20260414 011337] Receive response: 500 {"error":"Internal Server Error","message":"Simulated error by WireMock."}

[20260414 011337] Send request: GET http://localhost:13000/api/token
         Remarks: Retry
[20260414 011340] Receive response: 200 TOKEN_OK

[20260414 011340] Send request: GET http://localhost:13000/api/get-data
         Remarks: Normal GET request
[20260414 011343] Receive response: 200 GET_DATA_OK

[20260414 011343] Send request: GET http://localhost:13000/api/logic
         Remarks: Error by program (HTTP OK)
[20260414 011343] Receive response: 200 LOGIC_ERROR by WireMock

[20260414 011343] Send request: GET http://localhost:13000/api/logic
         Remarks: Retry
[20260414 011346] Receive response: 200 LOGIC_OK

[20260414 011346] Send request: GET http://localhost:13000/api/timeout
         Remarks: Proxy not return to client
[20260414 011416] Receive response: ERROR 処理がタイムアウトになりました。
```