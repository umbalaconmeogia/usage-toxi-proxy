[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Client truy cập server qua WireMock (Có Controller)

## Tổng quan

Trong bài kiểm tra này, client kết nối với server thông qua WireMock, và các thay đổi (độ trễ, lỗi) được áp dụng.
* Gây lỗi cho lần gọi đầu tiên của /api/token, trả về HTTP 500.
* Gây lỗi logic cho lần gọi đầu tiên của /api/logic, trả về HTTP 200 nhưng nội dung phản hồi cho client biết đã xảy ra lỗi.
* Gây lỗi timeout.

```mermaid
graph LR
    Client["Client"] -- "Request (Port 13000)" --> WM_Proxy["WireMock"]
    WM_Proxy -- "Forward (Port 12000)" --> Server["Server"]
  
    subgraph "WireMock Process"
        WM_Proxy
        WM_Mappings["Mappings<br>00_default_proxy<br>01_500_on_token<br>02_logic_error<br>03_timeout"]
    end
```

## Các bước kiểm tra

* **Khởi động WireMock**
  Truy cập vào thư mục `tests\03_WireMockWithControl` và chạy:
  ```powershell
   dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
  ```
* **Khởi động server**
  Truy cập vào thư mục `tests\03_WireMockWithControl` và chạy:
  ```powershell
  ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
  ```
* **Khởi động client**
  Truy cập vào thư mục `tests\03_WireMockWithControl` và chạy:
  ```powershell
  ..\..\client\client.ps1 .\scenario-client.csv
  ```
* **Dừng server**
  Sau khi tất cả các yêu cầu từ client đã được gửi, nhấn **Ctrl+C** trên terminal của server để dừng.

## Mô tả luồng yêu cầu

Dưới đây là trình tự yêu cầu được xác nhận bởi nhật ký `output.md` và các tệp kịch bản. WireMock chặn các route cụ thể để mô phỏng lỗi, trong khi các route khác được chuyển tiếp trong suốt đến server.

```mermaid
sequenceDiagram
    participant Client
    participant WM as WireMock
    participant Server

    Note over Client: Bắt đầu kịch bản

    Client->>WM: GET /api/get-data (Port 13000)
    WM->>Server: Forward (Port 12000)
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Client->>WM: GET /api/post-data
    WM->>Server: Forward
    Note right of Server: Kịch bản không khớp (không có GET cho đường dẫn này)
    Server-->>WM: 200 UNKNOWN request
    WM-->>Client: 200 UNKNOWN request

    Client->>WM: POST /api/post-data (body: abc)
    WM->>Server: Forward
    Server-->>WM: 200 POST_DATA_OK
    WM-->>Client: 200 POST_DATA_OK

    Client->>WM: GET /api/token
    Note over WM: Mapping 01: chặn lần gọi đầu tiên,<br/>trả về 500 (Scenario: Token_Failed_Once)
    WM-->>Client: 500 Internal Server Error

    Client->>WM: GET /api/token (Thử lại)
    WM->>Server: Forward (scenario state: Will_Pass_Next_Time)
    Server-->>WM: 200 TOKEN_OK
    WM-->>Client: 200 TOKEN_OK

    Client->>WM: GET /api/get-data
    WM->>Server: Forward
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Client->>WM: GET /api/logic
    Note over WM: Mapping 02: chặn lần gọi đầu tiên,<br/>trả về LOGIC_ERROR (Scenario: Logic_Error_One)
    WM-->>Client: 200 LOGIC_ERROR by WireMock

    Client->>WM: GET /api/logic (Thử lại)
    WM->>Server: Forward (scenario state: Data_Will_Be_Fixed_Next_Time)
    Server-->>WM: 200 LOGIC_OK
    WM-->>Client: 200 LOGIC_OK

    Client->>WM: GET /api/timeout
    Note over WM: Mapping 03: giữ request lại 60s (Delay: 60000ms)
    Note over Client,WM: Client timeout sau 30s — ngừng chờ
    Client-->>Client: ERROR (timeout)
    Note over WM: Sau 60s, WireMock mới forward đến server
    WM->>Server: Forward (Port 12000)
    Note right of Server: Không có handler cho /api/timeout
    Server-->>WM: 200 UNKNOWN request
    Note over WM: Response bị bỏ — client đã ngắt kết nối

    Note over Client: Kết thúc kịch bản
```
