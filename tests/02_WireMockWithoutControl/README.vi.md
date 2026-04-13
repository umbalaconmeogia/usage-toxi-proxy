[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Truy cập server qua WireMock (Không có Controller)

## Tổng quan

Trong bài kiểm tra này, client kết nối với server thông qua WireMock hoạt động như một proxy trong suốt, nhưng không có thay đổi nào (độ trễ, lỗi) được áp dụng. Điều này minh họa hành vi chuyển tiếp mặc định của WireMock.

```mermaid
graph LR
    Client["Client"] -- "Request (Port 13000)" --> WM_Proxy["WireMock\n(Proxy Port)"]
    WM_Proxy -- "Forward (Port 12000)" --> Server["Server"]
  
    subgraph "WireMock Process"
        WM_Proxy
        WM_Admin["Admin API\n(Port 9091)"]
    end
```

## Các bước kiểm tra

* **Khởi động WireMock**
   Truy cập vào thư mục `tests\02_WireMockWithoutControl` và chạy:
   ```powershell
   dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
   ```
* **Khởi động server**
   Truy cập vào thư mục `tests\02_WireMockWithoutControl` và chạy:
   ```powershell
   ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
   ```
* **Khởi động client**
   Truy cập vào thư mục `tests\02_WireMockWithoutControl` và chạy:
   ```powershell
   ..\..\client\client.ps1 .\scenario-client.csv
   ```
* **Dừng server**
   Sau khi tất cả các yêu cầu từ client đã được gửi, nhấn **Ctrl+C** trên terminal của server để dừng.

## Mô tả luồng yêu cầu

Dưới đây là trình tự yêu cầu được xác nhận bởi nhật ký `output.md` và các tệp kịch bản. Ngay cả khi không có lỗi nào được đưa vào, các yêu cầu vẫn đi qua proxy trong suốt của WireMock trên cổng 13000.

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

    Note over Client: Đợi 1 giây (WAIT)

    Client->>WM: GET /api/post-data
    WM->>Server: Forward
    Note right of Server: Kịch bản không khớp (không có GET cho đường dẫn này)
    Server-->>WM: 200 UNKNOWN request
    WM-->>Client: 200 UNKNOWN request

    Note over Client: Đợi 2 giây (WAIT)

    Client->>WM: POST /api/post-data (body: abc)
    WM->>Server: Forward
    Server-->>WM: 200 POST_DATA_OK
    WM-->>Client: 200 POST_DATA_OK

    Note over Client: Đợi 3 giây (WAIT)

    Client->>WM: GET /api/token
    WM->>Server: Forward
    Server-->>WM: 200 TOKEN_OK
    WM-->>Client: 200 TOKEN_OK

    Note over Client: Kết thúc kịch bản
```
