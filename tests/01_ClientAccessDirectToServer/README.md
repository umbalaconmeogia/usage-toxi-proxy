[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Client access direct to server

## Overview

In this example, we make the client access directly to the server without using Toxiproxy, just to demonstrate the basic usage of the client and server.

```mermaid
graph LR
    Client["Client"] -- "Request (Port 12000)" --> Server["Server"]
```

## Test action

* Start server
   Go to folder `tests\ClientAccessDirectToServer` then run
   ```powershell
   ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
   ```
* Start client
   Go to folder `tests\ClientAccessDirectToServer` then run
   ```powershell
   ..\..\client\client.ps1 .\scenario-client.csv
   ```
* After all client's requests sent, stop server
   Press Ctrl+C on server terminal to stop the server.

## Describe request flow

Following is the request sequence based on the scenario and actual results:

```mermaid
sequenceDiagram
    participant Client
    participant Server
    
    Note over Client: Start of scenario
    
    Client->>Server: GET /api/get-data
    Server-->>Client: 200 GET_DATA_OK
    
    Note over Client: Wait 1 second (WAIT)
    
    Client->>Server: GET /api/post-data
    Note right of Server: Scenario mismatch
    Server-->>Client: 200 UNKNOWN request
    
    Note over Client: Wait 2 seconds (WAIT)
    
    Client->>Server: POST /api/post-data (body: abc)
    Server-->>Client: 200 POST_DATA_OK
    
    Note over Client: Wait 3 seconds (WAIT)
    
    Client->>Server: GET /api/token
    Server-->>Client: 200 TOKEN_OK
    
    Note over Client: End of scenario
```
