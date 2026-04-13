[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Client access server via WireMock

## Overview

In this test, the client connects to the server through WireMock, and modifications (latency, errors) are applied.
* It causes error for the first time call of /api/token, return HTTP 500.
* It causes logic error for the first call of /api/logic, return HTTP 200 but the response body show to the client that error occured.
* It causes timeout error.

```mermaid
graph LR
    Client["Client"] -- "Request (Port 13000)" --> WM_Proxy["WireMock"]
    WM_Proxy -- "Forward (Port 12000)" --> Server["Server"]
  
    subgraph "WireMock Process"
        WM_Proxy
        WM_Mappings["Mappings<br>00_default_proxy<br>01_500_on_token<br>02_logic_error<br>03_timeout"]
    end
```

## Test action

* **Start WireMock**
  Go to the `tests\03_WireMockWithControl` folder and run:
  ```powershell
   dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
  ```
* **Start server**
  Go to the `tests\03_WireMockWithControl` folder and run:
  ```powershell
  ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
  ```
* **Start client**
  Go to the `tests\03_WireMockWithControl` folder and run:
  ```powershell
  ..\..\client\client.ps1 .\scenario-client.csv
  ```
* **Stop server**
  After all client requests are sent, press **Ctrl+C** on the server terminal to stop.

## Describe request flow

Following is the request sequence verified by the `output.md` logs and scenario files. WireMock intercepts specific routes to simulate errors before forwarding others transparently to the server.

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

    Client->>WM: GET /api/post-data
    WM->>Server: Forward
    Note right of Server: Scenario mismatch (no GET defined for this path)
    Server-->>WM: 200 UNKNOWN request
    WM-->>Client: 200 UNKNOWN request

    Client->>WM: POST /api/post-data (body: abc)
    WM->>Server: Forward
    Server-->>WM: 200 POST_DATA_OK
    WM-->>Client: 200 POST_DATA_OK

    Client->>WM: GET /api/token
    Note over WM: Mapping 01: intercept first call,<br/>return 500 (Scenario: Token_Failed_Once)
    WM-->>Client: 500 Internal Server Error

    Client->>WM: GET /api/token (Retry)
    WM->>Server: Forward (scenario state: Will_Pass_Next_Time)
    Server-->>WM: 200 TOKEN_OK
    WM-->>Client: 200 TOKEN_OK

    Client->>WM: GET /api/get-data
    WM->>Server: Forward
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Client->>WM: GET /api/logic
    Note over WM: Mapping 02: intercept first call,<br/>return LOGIC_ERROR (Scenario: Logic_Error_One)
    WM-->>Client: 200 LOGIC_ERROR by WireMock

    Client->>WM: GET /api/logic (Retry)
    WM->>Server: Forward (scenario state: Data_Will_Be_Fixed_Next_Time)
    Server-->>WM: 200 LOGIC_OK
    WM-->>Client: 200 LOGIC_OK

    Client->>WM: GET /api/timeout
    Note over WM: Mapping 03: hold request for 60s (Delay: 60000ms)
    Note over Client,WM: Client times out after 30s — gives up waiting
    Client-->>Client: ERROR (timeout)
    Note over WM: After 60s, WireMock forwards to server
    WM->>Server: Forward (Port 12000)
    Note right of Server: No handler for /api/timeout
    Server-->>WM: 200 UNKNOWN request
    Note over WM: Response discarded — client already disconnected

    Note over Client: End of scenario
```
