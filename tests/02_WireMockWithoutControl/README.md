[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Client access server via WireMock (No Controller)

## Overview

In this test, the client connects to the server through WireMock acting as a transparent proxy, but no modifications (latency, errors) are applied. This demonstrates WireMock's default pass-through behavior.

```mermaid
graph LR
    Client["Client"] -- "Request (Port 13000)" --> WM_Proxy["WireMock"]
    WM_Proxy -- "Forward (Port 12000)" --> Server["Server"]
  
    subgraph "WireMock Process"
        WM_Proxy
        WM_Mappings["Mappings<br>00_default_proxy"]
    end
```

## Test action

* **Start WireMock**
   Go to the `tests\02_WireMockWithoutControl` folder and run:
   ```powershell
   dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
   ```
* **Start server**
   Go to the `tests\02_WireMockWithoutControl` folder and run:
   ```powershell
   ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
   ```
* **Start client**
   Go to the `tests\02_WireMockWithoutControl` folder and run:
   ```powershell
   ..\..\client\client.ps1 .\scenario-client.csv
   ```
* **Stop server**
   After all client requests are sent, press **Ctrl+C** on the server terminal to stop.

## Describe request flow

Following is the request sequence verified by the `output.md` logs and scenario files. Even though no errors are injected, the requests pass through WireMock's transparent proxy on port 13000.

```mermaid
sequenceDiagram
    participant Client
    participant WM as WireMock
    participant Server

    Note over Client: Start of scenario

    Client->>WM: GET /api/get-data (Port 13000)
    WM->>Server: Forward (Port 12000)
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Note over Client: Wait 1 second (WAIT)

    Client->>WM: GET /api/post-data
    WM->>Server: Forward
    Note right of Server: Scenario mismatch (no GET defined for this path)
    Server-->>WM: 200 UNKNOWN request
    WM-->>Client: 200 UNKNOWN request

    Note over Client: Wait 2 seconds (WAIT)

    Client->>WM: POST /api/post-data (body: abc)
    WM->>Server: Forward
    Server-->>WM: 200 POST_DATA_OK
    WM-->>Client: 200 POST_DATA_OK

    Note over Client: Wait 3 seconds (WAIT)

    Client->>WM: GET /api/token
    WM->>Server: Forward
    Server-->>WM: 200 TOKEN_OK
    WM-->>Client: 200 TOKEN_OK

    Note over Client: End of scenario
```
