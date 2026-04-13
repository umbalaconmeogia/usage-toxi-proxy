## Server

```
PS > ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
[INFO] Server started at http://localhost:12000/
[INFO] Press Ctrl+C to stop.
[20260413 161628] Receive request: GET /api/get-data
[20260413 161628] Return response: GET_DATA_OK
[20260413 161631] Receive UNKNOWN request: GET /api/post-data
[20260413 161631] Return response: UNKNOWN request
[20260413 161634] Receive request: POST /api/post-data
[20260413 161634] Return response: POST_DATA_OK
[20260413 161638] Receive request: GET /api/token
[20260413 161638] Return response: TOKEN_OK
[INFO] Server stopped immediately.
```

## ToxiProxy

```
PS > ..\..\toxiproxy\toxiproxy-server-windows-amd64.exe -config ..\..\toxiproxy\server1-config.json
INFO[0000] Populated proxies from file                   config=..\..\toxiproxy\server1-config.json proxies=1
INFO[0000] Started proxy                                 name=dataverse proxy=127.0.0.1:13000 upstream=127.0.0.1:12000
INFO[0000] API HTTP server starting                      host=localhost port=8474 version=2.1.4
INFO[0084] Accepted client                               client=127.0.0.1:57272 name=dataverse proxy=127.0.0.1:13000 upstream=127.0.0.1:12000
WARN[0130] Source terminated                             bytes=473 err=read tcp 127.0.0.1:57273->127.0.0.1:12000: wsarecv: An existing connection was forcibly closed by the remote host. name=dataverse
WARN[0130] Source terminated                             bytes=687 err=read tcp 127.0.0.1:13000->127.0.0.1:57272: use of closed network connection name=dataverse
```

## Client

```
PS > ..\..\client\client.ps1 .\scenario-client.csv
[INFO] Scenario file: .\scenario-client.csv

[20260413 161626] Send request: GET http://localhost:13000/api/get-data
         Remarks: Normal GET request
[20260413 161629] Receive response: 200 GET_DATA_OK

[20260413 161629] WAIT: 1 second(s)

[20260413 161630] Send request: GET http://localhost:13000/api/post-data
         Remarks: Error
[20260413 161631] Receive response: 200 UNKNOWN request

[20260413 161631] WAIT: 2 second(s)

[20260413 161634] Send request: POST http://localhost:13000/api/post-data
         Remarks: Normal POST request
[20260413 161635] Receive response: 200 POST_DATA_OK

[20260413 161635] WAIT: 3 second(s)

[20260413 161638] Send request: GET http://localhost:13000/api/token
         Remarks: Get token
[20260413 161638] Receive response: 200 TOKEN_OK
```