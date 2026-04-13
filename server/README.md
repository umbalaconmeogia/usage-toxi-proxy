# Specification: server.ps1

## 1. Tổng quan (Overview)

`server.ps1` là một **HTTP test server đơn giản**, dùng để **mô phỏng hành vi của API server** trong các bài test System Test (ST), đặc biệt là các bài test liên quan đến retry, fault tolerance, và proxy (ví dụ Toxiproxy).

Server hoạt động dựa trên một file scenario CSV xác định **request nào sẽ trả response gì**, nhằm tạo ra môi trường test có kiểm soát.

***

## 2. Cú pháp (Syntax)

```powershell
server.ps1 <scenario file> <url> <wait_time_in_second>
```
Ví dụ:
```powershell
server.ps1 scenario.csv http://localhost:2000 5
```

***

#### 2.1 Tham số

| Tham số                 | Mô tả                                                           |
| :---------------------- | :-------------------------------------------------------------- |
| `<scenario file>`       | File CSV mô tả kịch bản server. Ví dụ: `server-scenario.csv`    |
| `<url>`                 | Base URL mà server sẽ lắng nghe. Ví dụ: `http://localhost:2000` |
| `<wait time in second>` | Thời gian (giây) server chờ sau khi trả response                |

***

#### 2.2 Giá trị mặc định

| Tham số                 | Giá trị mặc định        |
| :---------------------- | :---------------------- |
| `<scenario file>`       | `server-scenario.csv`   |
| `<url>`                 | `http://localhost:2000` |
| `<wait time in second>` | `0`                     |

***

### 3. Định dạng file scenario

#### 3.1 File `server-scenario.csv`

File CSV phải có các cột sau:

```csv
method, request, response
```

| Cột        | Mô tả                                     |
| :--------- | :---------------------------------------- |
| `method`   | HTTP Method (GET, POST, PUT, DELETE, ...) |
| `request`  | URL path (ví dụ: `/api/data`)             |
| `response` | Nội dung response trả về                  |

***

#### 3.2 Ví dụ

```csv
method, request, response
GET, /api/data, DATA OK
POST, /api/data, DATA POST_OK
GET, /api/token, TOKEN OK
```

***

### 4. Chức năng (Behavior)

Khi khởi động, `server.ps1` thực hiện các bước sau:

1.  Đọc file scenario CSV được chỉ định.
2.  Lắng nghe HTTP request tại `<url>` được chỉ định.
3.  Khi nhận request:
    * Ghi log: `[yyyymmdd hhmiss] Receive request: <method> <request>`
    * **Xử lý đặc biệt**: Nếu path là `/stop-server`, server sẽ trả về nội dung `SERVER STOPPED` và tự động dừng hoạt động.
    * So khớp cặp `(method, request)` với scenario trong file CSV.
    * Nếu tìm thấy:
        * Trả về `response` tương ứng.
        * Ghi log: `[yyyymmdd hhmiss] Receive request: <method> <request>`
    * Nếu không tìm thấy:
        * Trả về `UNKNOWN request`.
        * Ghi log: `[yyyymmdd hhmiss] Receive UNKNOWN request: <method> <request>`
    * Ghi log: `[yyyymmdd hhmiss] Return response: <response>`
4.  Sau khi trả response, chờ `<wait time in second>` (nếu > 0).
5.  Tiếp tục xử lý các request tiếp theo.
6.  Server dừng khi nhận tín hiệu **Ctrl + C**.

***

### 5. Log output

#### 5.1 Nhận request

```text
[yyyymmdd hhmiss] Receive [UNKNOWN] request: <method> <request>
```

*(Lưu ý: Có thêm tiền tố `UNKNOWN` nếu request không có trong kịch bản)*

#### 5.2 Trả response

```text
[yyyymmdd hhmiss] Return response: <response>
```

***

### 6. Phạm vi sử dụng (Scope)

`server.ps1` được sử dụng cho:

* System Test (ST)
* Test retry / fault tolerance
* Test kết hợp với:
    * `client.ps1`
    * Toxiproxy
    * Controller (PowerShell / VBA)

Không dùng cho:

* Production
* Performance test
* Load test

***

### 7. Tóm tắt

`server.ps1` là HTTP test server chạy theo kịch bản CSV và base URL chỉ định, cho phép kiểm soát response theo từng request. Công cụ này hỗ trợ hiệu quả việc kiểm thử retry và fault-handling trong System Test.
