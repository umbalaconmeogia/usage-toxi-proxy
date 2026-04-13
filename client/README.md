[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Specification: Client

## 1. Overview

`client.ps1` is a **test client program** responsible for **sending HTTP requests according to a predefined scenario** to a server (or proxy like Toxiproxy), to test the handling behavior, retry mechanism, and fault tolerance of the target system.

The program is designed to:

* Run on **standard Windows environment**
* No dependency on additional frameworks or runtimes
* Work independently from the production system

---

## 2. Syntax

```powershell
program.ps1 [<scenario file>]
```

| Parameter          | Description                                               |
| :----------------- | :-------------------------------------------------------- |
| `<scenario file>` | CSV file describing the request scenario. Example: `scenario.csv` |

### 2.2 Default Values

| Parameter          | Default Value      |
| :----------------- | :----------------- |
| `<scenario file>` | `scenario.csv`     |

---

## 3. Scenario File Format

### 3.1 File: `scenario.csv`

The scenario file is a CSV file with the following columns:

```csv
method, url, param, remarks
```

| Column    | Description                                                                                                                                                              |
| :-------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `method`  | HTTP Method (GET, POST, PUT, DELETE, ...) or pseudo-method `WAIT`.                                                                                                       |
| `url`     | Full URL (e.g., `http://localhost:12000/api/data`). Optional if method is `WAIT`.                                                                                      |
| `param`   | Accompanying parameters: <br>- If `method` is `WAIT`: Number of seconds to wait. <br>- If `method` is `POST`: Content of the request body to be sent. |
| `remarks` | Notes for the scenario (does not affect logic).                                                                                                                          |

### 3.2 Example

```csv
method, url, param, remarks
GET, http://localhost:12000/api/data,, normal request
WAIT,, 5, wait 5 seconds
POST, http://localhost:12000/api/data, {"id": 1}, post request
GET, http://localhost:12001/api/token,, get token from server 2
```

---

## 4. Behavior

`client.ps1` performs the following steps:

1. Reads the specified scenario CSV file.
2. Processes each line in the scenario file sequentially.
3. For each line:
   * If `method` is `WAIT`:
     * Wait for the number of seconds specified in the `param` column.
   * If `method` is a request (GET, POST, ...):
     * Get the full URL and corresponding Method from the CSV file.
     * If it is `POST`, use the content from the `param` column as the body.
     * Display the Remarks (notes) if available.
     * Send the HTTP request to the specified URL.
     * Receive the response from the server.
     * Log to the console according to the specified format.
4. Finished when the entire scenario has been processed.

---

## 5. Console Output (Log Output)

The program logs to the console using a fixed format as follows:

### 5.1 When Sending Request

```text
[yyyymmdd hhiiss] Send request: <method> <request url>
```

### 5.2 When Receiving Response

```text
[yyyymmdd hhiiss] Receive response: <http code> <response>
```

### 5.3 Example

```text
[20260409 141530] Send request: GET http://localhost:2000/api/data
[20260409 141530] Receive response: 200 DATA_OK
```

---

## 6. Error Handling

* If an HTTP request encounters an error (timeout, connection error, network error):
  * Record the error
  * Display error information in the `<response>` section
* The program **does not stop abruptly** when encountering an error in a request, but continues to process the next scenario (after wait time).

---

## 7. Scope

`client.ps1` is used for:

* √ System Test (ST)
* √ Retry / fault tolerance testing
* √ Testing with:
  * PowerShell test server
  * Toxiproxy
  * Mock API endpoints

Not for:

* Production
* Load test
* Performance test

---

## 8. Summary

> `client.ps1` is a client program that runs based on a CSV scenario, sending HTTP requests sequentially to a server/proxy, recording results, and supporting retry/fault-handling tests in System Test.
