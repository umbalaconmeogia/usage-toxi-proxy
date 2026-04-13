[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Client truy cập hai server thông qua WireMock

## Tổng quan

Trong bài test này, client kết nối với **hai server riêng biệt** thông qua **hai thực thể WireMock**, mỗi thực thể chạy trên một cổng khác nhau. Định tuyến được chia theo mục đích:

* Các yêu cầu đến `/api/token` và `/api/get-data` trên **cổng 13001** được xử lý bởi **WireMock #2**, thực thể này sẽ chuyển tiếp đến **Server #2** (cổng 12001).
* Tất cả các yêu cầu `/api/*` khác trên **cổng 13000** được xử lý bởi **WireMock #1**, thực thể này sẽ chuyển tiếp đến **Server #1** (cổng 12000).

Mô phỏng lỗi được áp dụng:
* Cuộc gọi đầu tiên đến `/api/token` (cổng 13001) trả về HTTP 500.
* Cuộc gọi đầu tiên đến `/api/logic` (cổng 13000) trả về HTTP 200 với thân lỗi logic.
* Cuộc gọi đến `/api/timeout` (cổng 13000) gây ra lỗi timeout phía client.

```mermaid
graph LR
    Client["Client"]

    Client -- "Cổng 13000" --> WM1["WireMock #1"]
    Client -- "Cổng 13001" --> WM2["WireMock #2"]

    WM1 -- "Chuyển tiếp (Cổng 12000)" --> Server1["Server #1"]
    WM2 -- "Chuyển tiếp (Cổng 12001)" --> Server2["Server #2"]

    subgraph "WireMock #1 (Cổng 13000)"
        WM1
        WM1_M["Mappings<br>00_default_proxy, 02_logic_error, 03_timeout"]
    end

    subgraph "WireMock #2 (Cổng 13001)"
        WM2
        WM2_M["Mappings<br>00_default_proxy, 01_500_on_token"]
    end
```

## Các kịch bản Server

**Server #1** (`scenario-server.csv`) — xử lý các định tuyến API chung:

| method | request        | response     |
| ------ | -------------- | ------------ |
| GET    | /api/get-data  | GET_DATA_OK  |
| POST   | /api/post-data | POST_DATA_OK |
| GET    | /api/logic     | LOGIC_OK     |

**Server #2** (`scenario-server-token.csv`) — xử lý token và các định tuyến get-data:

| method | request       | response    |
| ------ | ------------- | ----------- |
| GET    | /api/get-data | GET_DATA_OK |
| GET    | /api/token    | TOKEN_OK    |

## Hành động kiểm tra

* **Khởi chạy WireMock #1**
  Đi tới thư mục `tests\04_TwoServers\wm1` và chạy:
  ```powershell
  dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
  ```

* **Khởi chạy WireMock #2**
  Đi tới thư mục `tests\04_TwoServers\wm2` và chạy:
  ```powershell
  dotnet-wiremock --urls "http://localhost:13001" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
  ```

* **Khởi chạy Server #1**
  Đi tới thư mục `tests\04_TwoServers` và chạy:
  ```powershell
  ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
  ```

* **Khởi chạy Server #2**
  Đi tới thư mục `tests\04_TwoServers` và chạy:
  ```powershell
  ..\..\server\server.ps1 .\scenario-server-token.csv http://localhost:12001 3
  ```

* **Khởi chạy client**
  Đi tới thư mục `tests\04_TwoServers` và chạy:
  ```powershell
  ..\..\client\client.ps1 .\scenario-client.csv
  ```

* **Dừng các server**
  Sau khi tất cả các yêu cầu của client đã được gửi, nhấn **Ctrl+C** trên cả hai terminal của server để dừng.

## Mô tả luồng yêu cầu

```mermaid
sequenceDiagram
    participant Client
    participant WM2 as WireMock-2 #2 (13001)
    participant WM1 as WireMock-1 #1 (13000)
    participant S2 as Server-2 #2 (12001)
    participant S1 as Server-1 #1 (12000)

    Note over Client: Bắt đầu kịch bản

    Client->>WM2: GET /api/get-data (Cổng 13001)
    WM2->>S2: Chuyển tiếp (Cổng 12001)
    S2-->>WM2: 200 GET_DATA_OK
    WM2-->>Client: 200 GET_DATA_OK

    Client->>WM1: GET /api/post-data (Cổng 13000)
    WM1->>S1: Chuyển tiếp (Cổng 12000)
    Note right of S1: Kịch bản không khớp (không có GET được định nghĩa cho đường dẫn này)
    S1-->>WM1: 200 UNKNOWN request
    WM1-->>Client: 200 UNKNOWN request

    Client->>WM1: POST /api/post-data (body: abc)
    WM1->>S1: Chuyển tiếp
    S1-->>WM1: 200 POST_DATA_OK
    WM1-->>Client: 200 POST_DATA_OK

    Client->>WM2: GET /api/token (Cổng 13001)
    Note over WM2: Mapping 01: chặn cuộc gọi đầu tiên,<br/>trả về 500 (Kịch bản: Token_Failed_Once)
    WM2-->>Client: 500 Internal Server Error

    Client->>WM2: GET /api/token (Thử lại)
    WM2->>S2: Chuyển tiếp (trạng thái kịch bản: Will_Pass_Next_Time)
    S2-->>WM2: 200 TOKEN_OK
    WM2-->>Client: 200 TOKEN_OK

    Client->>WM1: GET /api/get-data (Cổng 13000)
    WM1->>S1: Chuyển tiếp
    S1-->>WM1: 200 GET_DATA_OK
    WM1-->>Client: 200 GET_DATA_OK

    Client->>WM1: GET /api/logic (Cổng 13000)
    Note over WM1: Mapping 02: chặn cuộc gọi đầu tiên,<br/>trả về LOGIC_ERROR (Kịch bản: Logic_Error_One)
    WM1-->>Client: 200 LOGIC_ERROR bởi WireMock

    Client->>WM1: GET /api/logic (Thử lại)
    WM1->>S1: Chuyển tiếp (trạng thái kịch bản: Data_Will_Be_Fixed_Next_Time)
    S1-->>WM1: 200 LOGIC_OK
    WM1-->>Client: 200 LOGIC_OK

    Client->>WM1: GET /api/timeout (Cổng 13000)
    Note over WM1: Mapping 03: giữ yêu cầu trong 60 giây (Delay: 60000ms)
    Note over Client,WM1: Client hết thời gian chờ sau 30 giây — từ bỏ việc chờ đợi
    Client-->>Client: LỖI (timeout)
    Note over WM1: Sau 60 giây, WireMock #1 chuyển tiếp đến server
    WM1->>S1: Chuyển tiếp (Cổng 12000)
    Note right of S1: Không có trình xử lý cho /api/timeout
    S1-->>WM1: 200 UNKNOWN request
    Note over WM1: Phản hồi bị loại bỏ — client đã ngắt kết nối
    
    Note over Client: Kết thúc kịch bản
```
