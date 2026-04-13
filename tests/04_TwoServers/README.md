[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Client access two servers via WireMock

## Overview

In this test, the client connects to **two separate servers** through **two WireMock instances**, each running on a different port. The routing is split by purpose:

* Requests to `/api/token` and `/api/get-data` on **port 13001** are handled by **WireMock #2**, which forwards to **Server #2** (port 12001).
* All other `/api/*` requests on **port 13000** are handled by **WireMock #1**, which forwards to **Server #1** (port 12000).

Error simulations applied:
* First call to `/api/token` (port 13001) returns HTTP 500.
* First call to `/api/logic` (port 13000) returns HTTP 200 with a logic error body.
* Call to `/api/timeout` (port 13000) causes a client-side timeout.

```mermaid
graph LR
    Client["Client"]

    Client -- "Port 13000" --> WM1["WireMock #1"]
    Client -- "Port 13001" --> WM2["WireMock #2"]

    WM1 -- "Forward (Port 12000)" --> Server1["Server #1"]
    WM2 -- "Forward (Port 12001)" --> Server2["Server #2"]

    subgraph "WireMock #1 (Port 13000)"
        WM1
        WM1_M["Mappings<br>00_default_proxy, 02_logic_error, 03_timeout"]
    end

    subgraph "WireMock #2 (Port 13001)"
        WM2
        WM2_M["Mappings<br>00_default_proxy, 01_500_on_token"]
    end
```

## Server scenarios

**Server #1** (`scenario-server.csv`) — handles general API routes:

| method | request        | response     |
| ------ | -------------- | ------------ |
| GET    | /api/get-data  | GET_DATA_OK  |
| POST   | /api/post-data | POST_DATA_OK |
| GET    | /api/logic     | LOGIC_OK     |

**Server #2** (`scenario-server-token.csv`) — handles token and get-data routes:

| method | request       | response    |
| ------ | ------------- | ----------- |
| GET    | /api/get-data | GET_DATA_OK |
| GET    | /api/token    | TOKEN_OK    |

## Test action

* **Start WireMock #1**
  Go to the `tests\04_TwoServers\wm1` folder and run:
  ```powershell
  dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
  ```

* **Start WireMock #2**
  Go to the `tests\04_TwoServers\wm2` folder and run:
  ```powershell
  dotnet-wiremock --urls "http://localhost:13001" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
  ```

* **Start Server #1**
  Go to the `tests\04_TwoServers` folder and run:
  ```powershell
  ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
  ```

* **Start Server #2**
  Go to the `tests\04_TwoServers` folder and run:
  ```powershell
  ..\..\server\server.ps1 .\scenario-server-token.csv http://localhost:12001 3
  ```

* **Start client**
  Go to the `tests\04_TwoServers` folder and run:
  ```powershell
  ..\..\client\client.ps1 .\scenario-client.csv
  ```

* **Stop servers**
  After all client requests are sent, press **Ctrl+C** on both server terminals to stop.

## Describe request flow

```mermaid
sequenceDiagram
    participant Client
    participant WM2 as WireMock-2 #2 (13001)
    participant WM1 as WireMock-1 #1 (13000)
    participant S2 as Server-2 #2 (12001)
    participant S1 as Server-1 #1 (12000)

    Note over Client: Start of scenario

    Client->>WM2: GET /api/get-data (Port 13001)
    WM2->>S2: Forward (Port 12001)
    S2-->>WM2: 200 GET_DATA_OK
    WM2-->>Client: 200 GET_DATA_OK

    Client->>WM1: GET /api/post-data (Port 13000)
    WM1->>S1: Forward (Port 12000)
    Note right of S1: Scenario mismatch (no GET defined for this path)
    S1-->>WM1: 200 UNKNOWN request
    WM1-->>Client: 200 UNKNOWN request

    Client->>WM1: POST /api/post-data (body: abc)
    WM1->>S1: Forward
    S1-->>WM1: 200 POST_DATA_OK
    WM1-->>Client: 200 POST_DATA_OK

    Client->>WM2: GET /api/token (Port 13001)
    Note over WM2: Mapping 01: intercept first call,<br/>return 500 (Scenario: Token_Failed_Once)
    WM2-->>Client: 500 Internal Server Error

    Client->>WM2: GET /api/token (Retry)
    WM2->>S2: Forward (scenario state: Will_Pass_Next_Time)
    S2-->>WM2: 200 TOKEN_OK
    WM2-->>Client: 200 TOKEN_OK

    Client->>WM1: GET /api/get-data (Port 13000)
    WM1->>S1: Forward
    S1-->>WM1: 200 GET_DATA_OK
    WM1-->>Client: 200 GET_DATA_OK

    Client->>WM1: GET /api/logic (Port 13000)
    Note over WM1: Mapping 02: intercept first call,<br/>return LOGIC_ERROR (Scenario: Logic_Error_One)
    WM1-->>Client: 200 LOGIC_ERROR by WireMock

    Client->>WM1: GET /api/logic (Retry)
    WM1->>S1: Forward (scenario state: Data_Will_Be_Fixed_Next_Time)
    S1-->>WM1: 200 LOGIC_OK
    WM1-->>Client: 200 LOGIC_OK

    Client->>WM1: GET /api/timeout (Port 13000)
    Note over WM1: Mapping 03: hold request for 60s (Delay: 60000ms)
    Note over Client,WM1: Client times out after 30s — gives up waiting
    Client-->>Client: ERROR (timeout)
    Note over WM1: After 60s, WireMock #1 forwards to server
    WM1->>S1: Forward (Port 12000)
    Note right of S1: No handler for /api/timeout
    S1-->>WM1: 200 UNKNOWN request
    Note over WM1: Response discarded — client already disconnected

    Note over Client: End of scenario
```
