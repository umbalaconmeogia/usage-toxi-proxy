# Client access server via Toxiproxy (No Controller)

## Overview

In this test, the client connects to the server through Toxiproxy, but no modifications (latency, errors) are applied. This demonstrates Toxiproxy's default pass-through behavior.

```mermaid
graph LR
    Client["Client"] -- "Request (Port 13000)" --> TP_Proxy["Toxiproxy\n(Proxy Port)"]
    TP_Proxy -- "Forward (Port 12000)" --> Server["Server"]
  
    subgraph "Toxiproxy Process"
        TP_Proxy
        TP_Admin["Admin API\n(Port 8474)"]
    end
```

## Test action

* **Start server**
   Go to the `tests\02_ToxiProxyWithoutController` folder and run:
   ```powershell
   ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
   ```
* **Start ToxiProxy**
   Run the Toxiproxy server with the predefined configuration:
   ```powershell
    ..\..\toxiproxi\toxiproxy-server-windows-amd64.exe -config ..\..\toxiproxi\server1-config.json
   ```
* **Start client**
   Run the client scenario (pointing to the Toxiproxy port `13000`):
   ```powershell
   ..\..\client\client.ps1 .\scenario-client.csv
   ```
* **Stop server**
   After all client requests are sent, press **Ctrl+C** on the server terminal to stop.

## Describe request flow

Following is the request sequence verified by the `output.md` logs and scenario files. Even though no errors are injected, the requests pass through Toxiproxy's "mirror" on port 13000.

```mermaid
sequenceDiagram
    participant Client
    participant TP as Toxiproxy
    participant Server

    Note over Client: Start of scenario

    Client->>TP: GET /api/get-data (Port 13000)
    TP->>Server: Forward (Port 12000)
    Server-->>TP: 200 GET_DATA_OK
    TP-->>Client: 200 GET_DATA_OK

    Note over Client: Wait 1 second (WAIT)

    Client->>TP: GET /api/post-data
    TP->>Server: Forward
    Note right of Server: Scenario mismatch (no GET defined for this path)
    Server-->>TP: 200 UNKNOWN request
    TP-->>Client: 200 UNKNOWN request

    Note over Client: Wait 2 seconds (WAIT)

    Client->>TP: POST /api/post-data (body: abc)
    TP->>Server: Forward
    Server-->>TP: 200 POST_DATA_OK
    TP-->>Client: 200 POST_DATA_OK

    Note over Client: Wait 3 seconds (WAIT)

    Client->>TP: GET /api/token
    TP->>Server: Forward
    Server-->>TP: 200 TOKEN_OK
    TP-->>Client: 200 TOKEN_OK

    Note over Client: End of scenario
```
