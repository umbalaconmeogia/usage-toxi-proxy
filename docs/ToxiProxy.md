# Evaluation: Limitations of ToxiProxy for Enterprise API Fault Injection

This document records the architectural decision regarding the use of ToxiProxy for automated E2E (End-to-End) and UAT (User Acceptance Testing) fault injection.

## Why We Transitioned Away from ToxiProxy

While ToxiProxy is an excellent tool for simulating network-level topology failures (such as latency, bandwidth throttling, and connection drops), it falls short when tasked with simulating complex, scenario-based REST API errors in an Enterprise ecosystem.

The primary reasons for transitioning away from ToxiProxy for API fault injection are:

### 1. Fundamental Limitation: Layer 4 vs. Layer 7
ToxiProxy operates strictly at **Layer 4 (TCP/IP)**. It manipulates raw byte streams and has absolutely no understanding of **Layer 7 (Application/HTTP)** protocols.
Because it does not parse HTTP, ToxiProxy cannot natively distinguish where one HTTP Request ends and another begins, which is especially problematic when clients utilize HTTP Keep-Alive (reusing a single TCP connection for multiple sequential requests).

### 2. Inability to Inspect HTTP Context
ToxiProxy cannot evaluate HTTP characteristics. It cannot read the URL path, the HTTP Method (GET/POST), or HTTP headers (such as `Authorization` or `Content-Type`). 
This means it is impossible to configure ToxiProxy to logically act on specific API endpoints (e.g., "return a 500 Error only when calling `/api/token`"). Any fault injected into ToxiProxy blindly applies to the entire active TCP stream.

### 3. Concurrency and Race Conditions
In automated test environments, if an external controller attempts to orchestrate ToxiProxy by tracking the volume of bytes transferred (`bytes_in`), it introduces severe race conditions. A client that sends requests sequentially and rapidly will overlap with the controller's orchestration. A simulated fault intended for Request #2 might accidentally be applied to the tail end of Request #1's active connection, invalidating the test results.

### 4. Lack of HTTPS/SSL Termination Support
In modern Enterprise environments, almost all communications are strictly secured via HTTPS (SSL/TLS). Because ToxiProxy routes raw TCP, it forwards the encrypted payload without inspecting it. It cannot terminate the SSL connection, inspect the encrypted HTTP payload, inject a custom HTTP 500 error body, and re-encrypt the traffic. This makes manipulating and mimicking secure REST API responses technically unfeasible.

## Conclusion

For automated E2E fault injection that requires evaluating specific HTTP endpoints, simulating HTTP status codes (e.g., 500 Internal Server Error, 401 Unauthorized), and maintaining stateful testing scenarios, a **Layer 7 API Mocking Tool / Reverse Proxy** (such as WireMock) must be used. 

ToxiProxy should remain reserved exclusively for chaotic network link testing (e.g., dropping database connections or degrading raw bandwidth).
