# Specification: Client

## 1. Tổng quan (Overview)

`client.ps1` là một **chương trình client dùng cho mục đích test**, có nhiệm vụ **gửi các HTTP request theo một kịch bản định sẵn** đến một server (hoặc proxy như Toxiproxy), nhằm kiểm tra hành vi xử lý, retry, và fault tolerance của hệ thống đích.

Chương trình được thiết kế để:

* Chạy trên **môi trường Windows tiêu chuẩn**
* Không phụ thuộc vào framework hay runtime bổ sung
* Hoạt động độc lập với hệ thống production

---

## 2. Cú pháp (Syntax)

```powershell
program.ps1 [<scenario file>]
```

| Tham số            | Mô tả                                                   |
| :------------------ | :-------------------------------------------------------- |
| `<scenario file>` | File CSV mô tả kịch bản gửi request. Ví dụ: `scenario.csv` |

### 2.2 Giá trị mặc định

| Tham số            | Giá trị mặc định   |
| :------------------ | :------------------ |
| `<scenario file>` | `scenario.csv` |

---

## 3. Định dạng file scenario

### 3.1 File: `scenario.csv`

File scenario là file CSV với các cột sau:

```csv
method, url, param, remarks
```

| Cột       | Mô tả                                                                                                                                                              |
| :-------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `method`  | HTTP Method (GET, POST, PUT, DELETE, ...) hoặc pseudo-method `WAIT`.                                                                                              |
| `url`     | URL đầy đủ (ví dụ: `http://localhost:12000/api/data`). Không bắt buộc nếu method là `WAIT`.                                                                      |
| `param`   | Tham số đi kèm: <br>- Nếu `method` là `WAIT`: Số giây cần chờ. <br>- Nếu `method` là `POST`: Nội dung body gửi đi. |
| `remarks` | Ghi chú cho kịch bản (không ảnh hưởng logic).                                                                                                                     |

### 3.2 Ví dụ

```csv
method, url, param, remarks
GET, http://localhost:12000/api/data,, normal request
WAIT,, 5, wait 5 seconds
POST, http://localhost:12000/api/data, {"id": 1}, post request
GET, http://localhost:12001/api/token,, get token from server 2
```

---

## 4. Chức năng (Behavior)

`client.ps1` thực hiện các bước sau:

1. Đọc file scenario CSV được chỉ định.
2. Lần lượt xử lý từng dòng trong file scenario.
3. Với mỗi dòng:
   * Nếu `method` là `WAIT`:
     * Chờ số giây được chỉ định trong cột `param`.
   * Nếu `method` là request (GET, POST,...):
     * Lấy URL đầy đủ và Method tương ứng từ file CSV.
     * Nếu là `POST`, lấy nội dung từ cột `param` để làm body.
     * Hiển thị Ghi chú (remarks) nếu có.
     * Gửi HTTP request đến URL trên.
     * Nhận response từ server.
     * Ghi log ra màn hình theo định dạng quy định.
4. Kết thúc khi đã xử lý hết toàn bộ scenario.

---

## 5. Hiển thị ra màn hình (Log output)

Chương trình ghi log ra console với format cố định như sau:

### 5.1 Khi gửi request

```text
[yyyymmdd hhiiss] Send request: <method> <request url>
```

### 5.2 Khi nhận response

```text
[yyyymmdd hhiiss] Receive response: <http code> <response>
```

### 5.3 Ví dụ

```text
[20260409 141530] Send request: GET http://localhost:2000/api/data
[20260409 141530] Receive response: 200 DATA_OK
```

---

## 6. Xử lý lỗi (Error handling)

* Nếu HTTP request phát sinh lỗi (timeout, connection error, network error):
  * Ghi nhận lỗi
  * Hiển thị thông tin lỗi trong phần `<response>`
* Chương trình **không dừng đột ngột** khi gặp lỗi trong một request, mà tiếp tục xử lý scenario tiếp theo (sau wait time).

---

## 7. Phạm vi sử dụng (Scope)

`client.ps1` được sử dụng cho:

* √ System Test (ST)
* √ Test retry / fault tolerance
* √ Test cùng:
  * PowerShell test server
  * Toxiproxy
  * API endpoint giả lập

Không dùng cho:

* Production
* Load test
* Performance test

---

## 8. Tóm tắt ngắn gọn

> `client.ps1` là chương trình client chạy theo kịch bản CSV, gửi HTTP request tuần tự đến server/proxy, ghi nhận kết quả và hỗ trợ kiểm thử retry/fault-handling trong System Test.
