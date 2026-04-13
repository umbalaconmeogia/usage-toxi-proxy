[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Client truy cập server thông qua Toxiproxy

## Tổng quan

Trong bài test này, client kết nối với server thông qua WireMock, và các sửa đổi (độ trễ, lỗi) được áp dụng.
* Nó gây ra lỗi cho lần gọi đầu tiên của /api/token, trả về HTTP 500.
* Nó gây ra lỗi logic cho lần gọi đầu tiên của /api/logic, trả về HTTP 200 nhưng thân phản hồi hiển thị cho client rằng lỗi đã xảy ra.
* Nó gây ra lỗi timeout.

```mermaid
graph LR
    Client["Client"] -- "Yêu cầu (Cổng 13000)" --> WM_Proxy["WireMock"]
    WM_Proxy -- "Chuyển tiếp (Cổng 12000)" --> Server["Server"]
  
    subgraph "Tiến trình WireMock"
        WM_Proxy
        WM_Mappings["Mappings<br>00_default_proxy<br>01_500_on_token<br>02_logic_error<br>03_timeout"]
    end
```

## Hành động kiểm tra

* **Khởi chạy WireMock**
  Đi tới thư mục `tests\03_WireMockWithControl` và chạy:
  ```powershell
   dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
  ```
* **Khởi chạy server**
  Đi tới thư mục `tests\03_WireMockWithControl` và chạy:
  ```powershell
  ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
  ```
* **Khởi chạy client**
  Đi tới thư mục `tests\03_WireMockWithControl` và chạy:
  ```powershell
  ..\..\client\client.ps1 .\scenario-client.csv
  ```
* **Dừng server**
  Sau khi tất cả các yêu cầu của client đã được gửi, nhấn **Ctrl+C** trên terminal của server để dừng.

## Mô tả luồng yêu cầu

Sau đây là trình tự yêu cầu được xác minh bởi các bản ghi `output.md` và các tệp kịch bản. WireMock chặn các định tuyến cụ thể để mô phỏng lỗi trước khi chuyển tiếp các yêu cầu khác một cách minh bạch đến server.

```mermaid
sequenceDiagram
    participant Client
    participant WM as WireMock
    participant Server

    Note over Client: Bắt đầu kịch bản

    Client->>WM: GET /api/get-data (Cổng 13000)
    WM->>Server: Chuyển tiếp (Cổng 12000)
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Client->>WM: GET /api/post-data
    WM->>Server: Chuyển tiếp
    Note right of Server: Kịch bản không khớp (không có GET được định nghĩa cho đường dẫn này)
    Server-->>WM: 200 UNKNOWN request
    WM-->>Client: 200 UNKNOWN request

    Client->>WM: POST /api/post-data (body: abc)
    WM->>Server: Chuyển tiếp
    Server-->>WM: 200 POST_DATA_OK
    WM-->>Client: 200 POST_DATA_OK

    Client->>WM: GET /api/token
    Note over WM: Mapping 01: chặn cuộc gọi đầu tiên,<br/>trả về 500 (Kịch bản: Token_Failed_Once)
    WM-->>Client: 500 Internal Server Error

    Client->>WM: GET /api/token (Thử lại)
    WM->>Server: Chuyển tiếp (trạng thái kịch bản: Will_Pass_Next_Time)
    Server-->>WM: 200 TOKEN_OK
    WM-->>Client: 200 TOKEN_OK

    Client->>WM: GET /api/get-data
    WM->>Server: Chuyển tiếp
    Server-->>WM: 200 GET_DATA_OK
    WM-->>Client: 200 GET_DATA_OK

    Client->>WM: GET /api/logic
    Note over WM: Mapping 02: chặn cuộc gọi đầu tiên,<br/>trả về LOGIC_ERROR (Kịch bản: Logic_Error_One)
    WM-->>Client: 200 LOGIC_ERROR bởi WireMock

    Client->>WM: GET /api/logic (Thử lại)
    WM->>Server: Chuyển tiếp (trạng thái kịch bản: Data_Will_Be_Fixed_Next_Time)
    Server-->>WM: 200 LOGIC_OK
    WM-->>Client: 200 LOGIC_OK

    Client->>WM: GET /api/timeout
    Note over WM: Mapping 03: chuyển tiếp với độ trễ 60 giây
    WM->>Server: Chuyển tiếp (Cổng 12000)
    Note right of Server: Không có trình xử lý cho /api/timeout
    Server-->>WM: 200 UNKNOWN request
    Note over Client,WM: Client hết thời gian chờ sau 30 giây (trước khi WM phản hồi)
    WM--xClient: LỖI (timeout — phản hồi không bao giờ được gửi)

    Note over Client: Kết thúc kịch bản
```
