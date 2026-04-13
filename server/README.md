[English](README.md) | [Tiếng Việt](README.vi.md)

# Specification: server.ps1

## 1. Overview

`server.ps1` is a **simple HTTP test server** used to **simulate API server behavior** in System Test (ST) scripts, especially tests related to retry mechanism, fault tolerance, and proxies (e.g., Toxiproxy).

The server operates based on a scenario CSV file that defines **which request yields which response**, creating a controlled testing environment.

***

## 2. Syntax

```powershell
server.ps1 <scenario file> <url> <wait_time_in_second>
```
Example:
```powershell
server.ps1 scenario.csv http://localhost:2000 5
```

***

#### 2.1 Parameter

| Parameter                | Description                                                    |
| :----------------------- | :------------------------------------------------------------- |
| `<scenario file>`       | CSV file describing the server scenario. Example: `server-scenario.csv` |
| `<url>`                 | Base URL the server will listen on. Example: `http://localhost:2000` |
| `<wait time in second>` | Time (seconds) the server waits after returning a response      |

***

#### 2.2 Default Values

| Parameter                | Default Value           |
| :----------------------- | :---------------------- |
| `<scenario file>`       | `server-scenario.csv`   |
| `<url>`                 | `http://localhost:2000` |
| `<wait time in second>` | `0`                     |

***

### 3. Scenario File Format

#### 3.1 File `server-scenario.csv`

The CSV file must have the following columns:

```csv
method, request, response
```

| Column     | Description                               |
| :--------- | :---------------------------------------- |
| `method`   | HTTP Method (GET, POST, PUT, DELETE, ...) |
| `request`  | URL path (e.g., `/api/data`)              |
| `response` | Response content returned                 |

***

#### 3.2 Example

```csv
method, request, response
GET, /api/data, DATA OK
POST, /api/data, DATA POST_OK
GET, /api/token, TOKEN OK
```

***

### 4. Behavior

When starting, `server.ps1` performs the following steps:

1.  Reads the specified scenario CSV file.
2.  Listens for HTTP requests at the specified `<url>`.
3.  Upon receiving a request:
    * Log: `[yyyymmdd hhmiss] Receive request: <method> <request>`
    * **Special Handling**: If the path is `/stop-server`, the server returns `SERVER STOPPED` and automatically stops.
    * Matches the `(method, request)` pair with the scenario in the CSV file.
    * If found:
        * Returns the corresponding `response`.
        * Log: `[yyyymmdd hhmiss] Receive request: <method> <request>`
    * If not found:
        * Returns `UNKNOWN request`.
        * Log: `[yyyymmdd hhmiss] Receive UNKNOWN request: <method> <request>`
    * Log: `[yyyymmdd hhmiss] Return response: <response>`
4.  After returning the response, waits for `<wait time in second>` (if > 0).
5.  Continues processing subsequent requests.
6.  The server stops when receiving a **Ctrl + C** signal.

***

### 5. Log Output

#### 5.1 Receiving Request

```text
[yyyymmdd hhmiss] Receive [UNKNOWN] request: <method> <request>
```

*(Note: The `UNKNOWN` prefix is added if the request is not in the scenario)*

#### 5.2 Returning Response

```text
[yyyymmdd hhmiss] Return response: <response>
```

***

### 6. Scope

`server.ps1` is used for:

* System Test (ST)
* Retry / fault tolerance testing
* Testing in combination with:
    * `client.ps1`
    * Toxiproxy
    * Controller (PowerShell / VBA)

Not for:

* Production
* Performance test
* Load test

***

### 7. Summary

`server.ps1` is an HTTP test server that runs according to a CSV scenario and a specified base URL, allowing controlled responses for each request. This tool effectively supports retry and fault-handling testing in System Test.
