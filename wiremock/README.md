# Using WireMock

## Install

There are several ways to install WireMock.Net. Below is the steps to install it as global tooll.

* First, install .NET SDK if it is not installed.
    ```powershell
    winget install Microsoft.DotNet.SDK.8
    ```
* Open new PowerShell, then install WireMock.Net
    ```powershell
    dotnet nuget add source https://api.nuget.org/v3/index.json -n nuget.org
    dotnet tool install --global dotnet-wiremock
    ```
* After install, run 
    ```
    dotnet-wiremock --urls="http://localhost:9090/"
    cd d:\data\projects.it\openSource\usage-toxi-proxy\wiremock
    dotnet-wiremock --urls "http://localhost:13000" --ReadStaticMappings true --WireMockLogger WireMockConsoleLogger
    ```

## Config

Để biến ý tưởng "Đếm thứ tự Request 1-2-3 và bơm lỗi" từ file CSV của bạn sang tư duy của WireMock, chúng ta sẽ sử dụng một tính năng cực kỳ mạnh mẽ gọi là **Scenarios (Stateful Behaviour - Đặc tính lưu trạng thái)**.

Khác với ToxiProxy (bị mù thông tin), WireMock mô phỏng chính xác máy trạng thái (State Machine). Nó cho phép định nghĩa: *"Đang ở State 1, nếu gửi Request vào, thì ném lỗi 500 và chuyển sang State 2. Ở State 2 gọi vào thì cho Pass (Thành công)"*.

### Cách dịch file `scenario-controller.csv` sang WireMock JSON

Để cấu hình, bạn tạo một thư mục tên là `__admin/mappings/` (đặt trong thư mục chạy WireMock) và vứt các file JSON vào. Khi khởi động, WireMock sẽ tự đọc cấu hình.

Dưới đây là cách cấu hình WireMock để **hoạt động Y HỆT kịch bản 9 bước** trong CSV của bạn:

---

#### 1. File Dự Phòng (Default Proxy - Tương đương dòng có dấu `*` ở mọi nơi)
File này đóng vai trò "Tráng nền". Nếu một request bay vào mà không nằm trong bất kỳ State cụ thể nào (hoặc kịch bản lỗi), nó sẽ tự động được gông cổ và ném sang Dataverse / Server thật.
*Tên file tham khảo:* `00_default_proxy.json`

```json
{
  "Priority": 99, 
  "Request": {
    "Path": { "Matchers": [ { "Name": "WildcardMatcher", "Pattern": "/*" } ] }
  },
  "Response": {
    "ProxyUrl": "http://localhost:12000"
  }
}
```
*(Lưu ý: Priority = 99 nghĩa là ưu tiên thấp nhất. Nó chỉ tóm những Request không bị dính vào các bẫy ở dưới).*

---

#### 2. Kịch bản lỗi 500 vào Bước số 4 (Trạng thái đếm State)
Trong CSV của bạn, Request 4 báo lỗi 500, Request 5 Retry lại thì Pass (`*`).
Thay vì đếm số toàn cục cồng kềnh, trong môi trường API E2E, ta bám theo đường dẫn (`/api/token`).

*Tên file tham khảo:* `01_simulate_500_on_token.json`
```json
{
  "Priority": 1,
  "ScenarioName": "Token_Failed_Once_Scenario", 
  "RequiredScenarioState": "Started", 
  "NewScenarioState": "Will_Pass_Next_Time", 
  "Request": {
    "Methods": [ "GET" ],
    "Path": { "Matchers": [ { "Name": "WildcardMatcher", "Pattern": "/api/token" } ] }
  },
  "Response": {
    "StatusCode": 500,
    "BodyAsJson": { "error": "Internal Server Error", "message": "Simulated error by WireMock for testing retry." }
  }
}
```
**Giải thích cơ chế hoạt động y hệt CSV của file này:**
* Ban đầu, Scenario luôn ở trạng thái `"Started"`.
* Lần gọi đầu tiên vào `/api/token`, File này bắt được! Nó lập tức thả cái lỗi mã `500` vào mặt Asteria, đồng thời lật kịch bản sang một chương mới có tên là `"Will_Pass_Next_Time"`.
* Lần tiếp theo Client "Retry" và gọi lại `/api/token`, vì trạng thái hiện tại đã là `"Will_Pass_Next_Time"`, file này **từ chối nhận diện**. Do đó, Request nhả xuống file số 1 (Default Proxy) => Request được chạy thông qua Dataverse (Thành công!). Quá trình mô phỏng Retry giống 100% CSV của bạn!

---

#### 3. Kịch bản lỗi nghiệp vụ (Trả 200 nhưng Data sai) vào Bước số 7
Lỗi này là ác mộng của các hệ thống: Mạng không rơi, Server kêu OK, nhưng cục Data rác. Trong CSV bạn trả về `PROGRAM_ERROR`. 

*Tên file tham khảo:* `02_simulate_logic_error.json`
```json
{
  "Priority": 2,
  "ScenarioName": "Logic_Error_Scenario",
  "RequiredScenarioState": "Started",
  "NewScenarioState": "Data_Will_Be_Fixed_Next_Time",
  "Request": {
    "Methods": [ "POST" ],
    "Path": { "Matchers": [ { "Name": "WildcardMatcher", "Pattern": "/api/post-data" } ] }
  },
  "Response": {
    "StatusCode": 200,
    "Body": "PROGRAM_ERROR"
  }
}
```
*(Quá trình hoạt động tương tự: Gây rác data 1 lần với HTTP 200, lật trạng thái, lần sau cho qua).*

---

#### 4. Kịch bản Timeout (Tương đương NONE / Bước số 9)
Khi hệ thống gián đoạn, Dataverse treo, không gửi dữ liệu. Chúng ta dùng tham số `Delay` (Tính bằng ms).

*Tên file tham khảo:* `03_simulate_timeout.json`
```json
{
  "Priority": 3,
  "ScenarioName": "Timeout_Scenario",
  "RequiredScenarioState": "Started",
  "Request": {
    "Path": { "Matchers": [ { "Name": "WildcardMatcher", "Pattern": "/api/get-data" } ] }
  },
  "Response": {
    "StatusCode": 200,
    "ProxyUrl": "http://localhost:12000",
    "Delay": 60000 
  }
}
```
**Giải thích:**
WireMock nhận request, ném cho Dataverse, Dataverse trả lời, nhưng WireMock sẽ tự động **ngậm kết quả (sleep) trong vòng 60 giây (60000ms)** mới phun về cho Client gây ra Timeout Connection do ngâm quá lâu. 

---

### Kết luận đánh giá
Như bạn có thể thấy, toàn bộ logic tư duy trong file CSV cực kỳ xuất sắc của bạn hoàn toàn có thể biên dịch 1:1 sang các cấu trúc JSON của WireMock. 

Hơn thế nữa, WireMock khắc phục được nhược điểm "Cần chọc vào đúng Request số mấy" thành việc "Bắt đúng cái API đó vào lần gọi đầu tiên", giúp hệ thống Test của bạn tự tin giải quyết được tình trạng Asteria bắn request lung tung không thep trình tự.

Bạn đã cài thử và chạy cái file `wiremock-net` lên để gọi thử vài Postman vào xem WireMock làm nhiệm vụ của nó bao giờ chưa?