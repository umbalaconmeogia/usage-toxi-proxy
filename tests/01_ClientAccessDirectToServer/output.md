# Ouput

## Server

```
PS > ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
[INFO] Server started at http://localhost:12000/
[INFO] Press Ctrl+C to stop.
[20260413 144329] Receive request: GET /api/get-data
[20260413 144329] Return response: GET_DATA_OK
[20260413 144332] Receive UNKNOWN request: GET /api/post-data
[20260413 144332] Return response: UNKNOWN request
[20260413 144335] Receive request: POST /api/post-data
[20260413 144335] Return response: POST_DATA_OK
[20260413 144338] Receive request: GET /api/token
[20260413 144338] Return response: TOKEN_OK
[INFO] Server stopped immediately.
```

## Client

```
PS > ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
[INFO] Server started at http://localhost:12000/
[INFO] Press Ctrl+C to stop.
[20260413 144329] Receive request: GET /api/get-data
[20260413 144329] Return response: GET_DATA_OK
[20260413 144332] Receive UNKNOWN request: GET /api/post-data
[20260413 144332] Return response: UNKNOWN request
[20260413 144335] Receive request: POST /api/post-data
[20260413 144335] Return response: POST_DATA_OK
[20260413 144338] Receive request: GET /api/token
[20260413 144338] Return response: TOKEN_OK
[INFO] Server stopped immediately.
```