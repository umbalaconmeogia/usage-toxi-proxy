# Ouput

## Server

```
PS tests\02_WireMockWithoutControl> ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
[INFO] Server started at http://localhost:12000/
[INFO] Press Ctrl+C to stop.
[20260414 003829] Receive request: GET /api/get-data
[20260414 003829] Return response: GET_DATA_OK
[20260414 003832] Receive UNKNOWN request: GET /api/post-data
[20260414 003832] Return response: UNKNOWN request
[20260414 003835] Receive request: POST /api/post-data
[20260414 003835] Return response: POST_DATA_OK
[20260414 003838] Receive request: GET /api/token
[20260414 003838] Return response: TOKEN_OK
```

## Client

```
PS tests\02_WireMockWithoutControl> ..\..\client\client.ps1 .\scenario-client.csv
[INFO] Scenario file: .\scenario-client.csv

[20260414 003828] Send request: GET http://localhost:13000/api/get-data
         Remarks: Normal GET request
[20260414 003829] Receive response: 200 GET_DATA_OK

[20260414 003829] WAIT: 1 second(s)

[20260414 003830] Send request: GET http://localhost:13000/api/post-data
         Remarks: Error
[20260414 003832] Receive response: 200 UNKNOWN request

[20260414 003832] WAIT: 2 second(s)

[20260414 003834] Send request: POST http://localhost:13000/api/post-data
         Remarks: Normal POST request
[20260414 003835] Receive response: 200 POST_DATA_OK

[20260414 003835] WAIT: 3 second(s)

[20260414 003838] Send request: GET http://localhost:13000/api/token
         Remarks: Get token
[20260414 003838] Receive response: 200 TOKEN_OK
```