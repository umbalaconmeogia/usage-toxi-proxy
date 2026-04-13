[English](README.md) | [Tiếng Việt](README.vi.md) | [日本語](README.ja.md)

# Truy cập server qua Toxiproxy (Không có Controller)

## Tổng quan

Trong bài kiểm tra này, client kết nối với server thông qua Toxiproxy, nhưng không có thay đổi nào (độ trễ, lỗi) được áp dụng. Điều này minh họa hành vi chuyển tiếp mặc định của Toxiproxy.

```mermaid
graph LR
    Client["Client"] -- "Request (Port 13000)" --> TP_Proxy["Toxiproxy\n(Proxy Port)"]
    TP_Proxy -- "Forward (Port 12000)" --> Server["Server"]
  
    subgraph "Toxiproxy Process"
        TP_Proxy
        TP_Admin["Admin API\n(Port 8474)"]
    end
```

## Các bước kiểm tra

* **Khởi động server**
   Truy cập vào thư mục `tests\02_ToxiProxyWithoutController` và chạy:
   ```powershell
   ..\..\server\server.ps1 .\scenario-server.csv http://localhost:12000 3
   ```
* **Khởi động ToxiProxy**
   Chạy Toxiproxy server với cấu hình đã định nghĩa trước:
   ```powershell
    ..\..\toxiproxy\toxiproxy-server-windows-amd64.exe -config ..\..\toxiproxy\server1-config.json
   ```
* **Khởi động client**
   Chạy kịch bản client (trỏ đến cổng Toxiproxy `13000`):
   ```powershell
   ..\..\client\client.ps1 .\scenario-client.csv
   ```
* **Dừng server**
   Sau khi tất cả các yêu cầu từ client đã được gửi, nhấn **Ctrl+C** trên terminal của server để dừng.

## Mô tả luồng yêu cầu

Dưới đây là trình tự yêu cầu được xác nhận bởi nhật ký `output.md` và các tệp kịch bản. Ngay cả khi không có lỗi nào được đưa vào, các yêu cầu vẫn đi qua "cổng phản chiếu" của Toxiproxy trên cổng 13000.

```mermaid
sequenceDiagram
    participant Client
    participant TP as Toxiproxy
    participant Server

    Note over Client: Bắt đầu kịch bản

    Client->>TP: GET /api/get-data (Port 13000)
    TP->>Server: Forward (Port 12000)
    Server-->>TP: 200 GET_DATA_OK
    TP-->>Client: 200 GET_DATA_OK

    Note over Client: Đợi 1 giây (WAIT)

    Client->>TP: GET /api/post-data
    TP->>Server: Forward
    Note right of Server: Kịch bản không khớp (không có GET cho đường dẫn này)
    Server-->>TP: 200 UNKNOWN request
    TP-->>Client: 200 UNKNOWN request

    Note over Client: Đợi 2 giây (WAIT)

    Client->>TP: POST /api/post-data (body: abc)
    TP->>Server: Forward
    Server-->>TP: 200 POST_DATA_OK
    TP-->>Client: 200 POST_DATA_OK

    Note over Client: Đợi 3 giây (WAIT)

    Client->>TP: GET /api/token
    TP->>Server: Forward
    Server-->>TP: 200 TOKEN_OK
    TP-->>Client: 200 TOKEN_OK

    Note over Client: Kết thúc kịch bản
```
