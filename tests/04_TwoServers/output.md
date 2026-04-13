# Ouput

## Server 1

```
PS tests\04_TwoServers>   ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
[INFO] Server started at http://localhost:12000/
[INFO] Press Ctrl+C to stop.
[20260414 021553] Receive UNKNOWN request: GET /api/post-data
[20260414 021553] Return response: UNKNOWN request
[20260414 021556] Receive request: POST /api/post-data
[20260414 021556] Return response: POST_DATA_OK
[20260414 021559] Receive request: GET /api/get-data
[20260414 021559] Return response: GET_DATA_OK
[20260414 021602] Receive request: GET /api/logic
[20260414 021602] Return response: LOGIC_OK
[20260414 021702] Receive UNKNOWN request: GET /api/timeout
[20260414 021702] Return response: UNKNOWN request
```

## Server 2

```
PS tests\04_TwoServers>   ..\..\server\server.ps1 .\scenario-server-token.csv http://localhost:12001 3
[INFO] Server started at http://localhost:12001/
[INFO] Press Ctrl+C to stop.
[20260414 021552] Receive request: GET /api/get-data
[20260414 021552] Return response: GET_DATA_OK
[20260414 021556] Receive request: GET /api/token
[20260414 021556] Return response: TOKEN_OK
```

## Client

```
PS tests\04_TwoServers>   ..\..\client\client.ps1 .\scenario-client.csv
[INFO] Scenario file: .\scenario-client.csv

[20260414 021551] Send request: GET http://localhost:13001/api/get-data
         Remarks: Normal GET request
[20260414 021552] Receive response: 200 GET_DATA_OK

[20260414 021552] Send request: GET http://localhost:13000/api/post-data
         Remarks: Error without trying
[20260414 021553] Receive response: 200 UNKNOWN request

[20260414 021553] Send request: POST http://localhost:13000/api/post-data
         Remarks: Normal POST request
[20260414 021556] Receive response: 200 POST_DATA_OK

[20260414 021556] Send request: GET http://localhost:13001/api/token
         Remarks: Error 500
[20260414 021556] Receive response: 500 {"error":"Internal Server Error","message":"Simulated error by WireMock."}

[20260414 021556] Send request: GET http://localhost:13001/api/token
         Remarks: Retry
[20260414 021556] Receive response: 200 TOKEN_OK

[20260414 021556] Send request: GET http://localhost:13000/api/get-data
         Remarks: Normal GET request
[20260414 021559] Receive response: 200 GET_DATA_OK

[20260414 021559] Send request: GET http://localhost:13000/api/logic
         Remarks: Error by program (HTTP OK)
[20260414 021559] Receive response: 200 LOGIC_ERROR by WireMock

[20260414 021559] Send request: GET http://localhost:13000/api/logic
         Remarks: Retry
[20260414 021602] Receive response: 200 LOGIC_OK

[20260414 021602] Send request: GET http://localhost:13000/api/timeout
         Remarks: Proxy not return to client
[20260414 021632] Receive response: ERROR 処理がタイムアウトになりました。
```