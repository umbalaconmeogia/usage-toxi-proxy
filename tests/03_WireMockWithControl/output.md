## Server

```
PS D:\data\projects.it\openSource\usage-toxi-proxy\tests\03_ToxyProxyWithController> ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
[INFO] Server started at http://localhost:12000/
[INFO] Press Ctrl+C to stop.
[20260413 170218] Receive request: GET /api/get-data
[20260413 170218] Return response: GET_DATA_OK
[20260413 170221] Receive UNKNOWN request: GET /api/post-data
[20260413 170221] Return response: UNKNOWN request
[20260413 170224] Receive request: POST /api/post-data
[20260413 170224] Return response: POST_DATA_OK
[20260413 170227] Receive request: GET /api/token
[20260413 170227] Return response: TOKEN_OK
[20260413 170230] Receive request: GET /api/token
[20260413 170230] Return response: TOKEN_OK
[20260413 170233] Receive request: GET /api/get-data
[20260413 170233] Return response: GET_DATA_OK
[20260413 170236] Receive request: POST /api/post-data
[20260413 170236] Return response: POST_DATA_OK
[20260413 170239] Receive request: POST /api/post-data
[20260413 170239] Return response: POST_DATA_OK
[20260413 170242] Receive request: GET /api/get-data
[20260413 170242] Return response: GET_DATA_OK```

## ToxiProxy

```
PS D:\data\projects.it\openSource\usage-toxi-proxy\tests\03_ToxyProxyWithController> ..\..\toxiproxy\toxiproxy-server-windows-amd64.exe -config ..\..\toxiproxy\server1-config.json
INFO[0000] Started proxy                                 name=dataverse proxy=127.0.0.1:13000 upstream=127.0.0.1:12000
INFO[0000] Populated proxies from file                   config=..\..\toxiproxy\server1-config.json proxies=1
INFO[0000] API HTTP server starting                      host=localhost port=8474 version=2.1.4
INFO[0032] Accepted client                               client=127.0.0.1:61835 name=dataverse proxy=127.0.0.1:13000 upstream=127.0.0.1:12000
```

## Controller

```
PS D:\data\projects.it\openSource\usage-toxi-proxy\tests\03_ToxyProxyWithController> ..\..\controller\controller.ps1 .\scenario-controller.csv
[INFO] Loaded scenario file: .\scenario-controller.csv
[INFO] Proxy name: dataverse
[INFO] Toxiproxy API: http://127.0.0.1:8474

[20260413 170201] Controller started. Waiting for requests...
Press ENTER when next request is detected:
```

## Client

```
PS D:\data\projects.it\openSource\usage-toxi-proxy\tests\03_ToxyProxyWithController> ..\..\client\client.ps1 .\scenario-client.csv
[INFO] Scenario file: .\scenario-client.csv

[20260413 170216] Send request: GET http://localhost:13000/api/get-data
         Remarks: Normal GET request
[20260413 170218] Receive response: 200 GET_DATA_OK

[20260413 170218] Send request: GET http://localhost:13000/api/post-data
         Remarks: Error without trying
[20260413 170221] Receive response: 200 UNKNOWN request

[20260413 170221] Send request: POST http://localhost:13000/api/post-data
         Remarks: Normal POST request
[20260413 170224] Receive response: 200 POST_DATA_OK

[20260413 170224] Send request: GET http://localhost:13000/api/token
         Remarks: Error 500
[20260413 170227] Receive response: 200 TOKEN_OK

[20260413 170227] Send request: GET http://localhost:13000/api/token
         Remarks: Retry
[20260413 170230] Receive response: 200 TOKEN_OK

[20260413 170230] Send request: GET http://localhost:13000/api/get-data
         Remarks: Normal GET request
[20260413 170233] Receive response: 200 GET_DATA_OK

[20260413 170233] Send request: POST http://localhost:13000/api/post-data
         Remarks: Error by program (HTTP OK)
[20260413 170236] Receive response: 200 POST_DATA_OK

[20260413 170236] Send request: POST http://localhost:13000/api/post-data
         Remarks: Normal POST request
[20260413 170239] Receive response: 200 POST_DATA_OK

[20260413 170239] Send request: GET http://localhost:13000/api/get-data
         Remarks: Proxy not return to client
[20260413 170242] Receive response: 200 GET_DATA_OK
```