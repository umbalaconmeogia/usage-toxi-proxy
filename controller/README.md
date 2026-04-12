# Specification: Toxiproxy Controller

## 1. Tổng quan (Overview)

**Toxiproxy Controller** là một chương trình điều khiển thực thi các kịch bản lỗi (fault scenarios) đối với luồng request đi qua **Toxiproxy**, dựa trên một file kịch bản dạng CSV (`toxi-scenario.csv`).

Controller đóng vai trò:

* Theo dõi thứ tự request (request count)
* Diễn giải kịch bản lỗi theo từng request
* Điều khiển hành vi của Toxiproxy (forward, trả lỗi, timeout, delay, shutdown...)

> **Lưu ý:** Controller **chỉ dùng trong môi trường test**, không tồn tại trong production.

***

## 2. Phạm vi vai trợ (Role of Controller)

Controller có trách nhiệm:

* Đếm **số thứ tự request** đi qua Toxiproxy
* Đọc và áp dụng **1 dòng kịch bản tương ứng với mỗi request**
* Quyết định **hành vi xử lý request** tại Toxiproxy:
    * Chuyển tiếp đến server thật
    * Trả lỗi HTTP
    * Không trả response (timeout)
    * Delay phản hồi
    * Dừng Toxiproxy

Controller **không**:

* Thực hiện business logic
* Xử lý nội dung response của server thật
* Thay đổi cấu trúc production

***

## 3. Input / Output

### 3.1 Input

| Thành phần           | Mô tả                                                  |
| :------------------- | :----------------------------------------------------- |
| `toxi-scenario.csv`  | File mô tả kịch bản lỗi theo thứ tự request            |
| Request runtime info | Thông tin request đi qua Toxiproxy (thứ tự, thời điểm) |
| Toxiproxy Admin API  | REST API để điều khiển Toxiproxy                       |

***

### 3.2 Output

* Hành vi tương ứng trên mỗi request:
    * Forward request
    * HTTP error response
    * Timeout
    * Delay
    * Proxy shutdown
* Log thực thi controller (phục vụ trace test)

***

## 4. Định dạng file `toxi-scenario.csv`

### 4.1 Cấu trúc cột

| Cột  | Tên        | Mô tả                                                 |
| :--- | :--------- | :---------------------------------------------------- |
| 1    | `No`       | Số thứ tự (chỉ để dễ đọc, **không dùng trong logic**) |
| 2    | `process`  | Hành vi controller cần thực hiện                      |
| 3    | `response` | Nội dung response (khi applicable)                    |
| 4    | `param`    | Tham số phụ (delay time, body, v.v.)                  |

***

### 4.2 Ý nghĩa cột `process`

| Giá trị                    | Ý nghĩa                                                  |
| :------------------------- | :------------------------------------------------------- |
| `*`                        | **PASS** - Forward request tới server, trả response thật |
| `NONE`                     | **TIMEOUT** - Không trả response (client tự timeout)     |
| `STOP`                     | **STOP¥ PROXY** - Dừng Toxiproxy (gây lỗi không kết nối) |
| `WAIT`                     | **DELAY** - Chờ theo thời gian (ms) tại cột `param`      |
| Số HTTP (vd: `500`, `503`) | Trả HTTP error tương ứng                                 |
| `200`                      | Trả HTTP 200 với body ở cột `response`                   |

***

### 4.3 Ví dụ `toxi-scenario.csv`

```csv
No, process, response, param
1, *, ,
2, *, ,
3, *, ,
4, 500, ,
5, *, ,
6, *, ,
7, NONE, ,
8, 200, PROGRAM ERROR,
```

***

## 5. Luồng xử lý (Flow)

### 5.1 Luồng xử lý tổng quát

1. Controller khởi động và đọc `toxi-scenario.csv`
2. Khởi tạo `request_counter = 0`
3. Mỗi khi có request đi qua Toxiproxy:
    * `request_counter += 1`
    * Lấy dòng thứ `request_counter` trong scenario
    * Diễn giải và thực thi hành vi tương ứng
4. Nếu scenario kết thúc:
    * Mặc định: tiếp tục **PASS**
    * Hoặc dừng test (tùy cấu hình)

***

### 5.2 Ánh xạ hành vi theo `process`

#### (a) `*` (PASS)

* Không can thiệp
* Cho Toxiproxy forward request đến server
* Trả lại response thật cho client

***

#### (b) HTTP Code (vd: `500`)

* Không forward request
* Tạo response HTTP với status code tương ứng
* Body:
    * rỗng, **hoặc**
    * lấy từ cột `response` nếu có

***

#### (c) `NONE` (Timeout)

* Không forward request
* Không gửi response
* Giữ connection mở cho tới khi client timeout

***

#### (d) `WAIT`

* Dừng xử lý trong thời gian `param` (milliseconds)
* Sau đó:
    * Forward hoặc trả response theo scenario kế tiếp
    * *(tùy lựa chọn implement)*

***

#### (e) `STOP`

* Dừng Toxiproxy thông qua Admin API
* Sau đó:
    * Client sẽ không connect được
* Dừng để test lỗi mức kết nối

***

## 6. Logging (Yêu cầu bắt buộc)

Controller phải log ít nhất các thông tin sau:

```text
[time] Request #N detected
[time] Scenario: process=<process>, response=<response>, param=<param>
[time] Action executed: <action>
```

Ví dụ:

```text
[10:01:05] Request #4 detected
[10:01:05] Scenario: process=500
[10:01:05] Action executed: Return HTTP 500
```

***

## 7. Ràng buộc & giả định (Constraints)

* Controller giả định request là **tuần tự** (sequential)
* Không hỗ trợ phân nhánh logic theo endpoint (version hiện tại)
* File scenario được đọc **theo thứ tự dòng**
* Controller không thay đổi proxy behavior ngoài test window

***

## 8. Phạm vi sử dụng (Scope)

Controller được dùng cho:

* √ System Test (ST)
* √ Retry behavior validation
* √ Fault tolerance testing
* √ Chaos / negative test
* √ Test kết hợp:
    * client -> Toxiproxy -> server

Không dùng cho:

* Production
* Performance test
* Load test

***

## 9. Tóm tắt (Summary)

> Toxiproxy Controller là chương trình điều phối kịch bản lỗi theo thứ tự request, sử dụng Toxiproxy như công cụ gây lỗi, giúp kiểm thử retry và fault-handling một cách có kiểm soát mà không thay đổi hệ thống production.
