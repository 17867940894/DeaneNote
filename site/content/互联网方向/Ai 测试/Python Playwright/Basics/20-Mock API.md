## 简介

Web API 通常以 HTTP 端点的形式实现。Playwright 提供了用于 **模拟 (mock)** 和 **修改** 网络流量（包括 HTTP 和 HTTPS）的 API。页面发出的任何请求，包括 [XHR](https://mdn.org.cn/en-US/docs/Web/API/XMLHttpRequest) 和 [fetch](https://mdn.org.cn/en-US/docs/Web/API/Fetch_API) 请求，都可以被追踪、修改和模拟。使用 Playwright，你还可以利用包含页面发出的多个网络请求的 HAR 文件进行模拟。

## 模拟 API 请求

以下代码将拦截所有对 `*/**/api/v1/fruits` 的调用，并返回一个自定义响应。不会发出对该 API 的实际请求。测试将访问使用模拟路由的 URL，并断言页面上存在模拟数据。

```python
def test_mock_the_fruit_api(page: Page):
    def handle(route: Route):
        json = [{"name": "Strawberry", "id": 21}]
        # fulfill the route with the mock data
        route.fulfill(json=json)

    # Intercept the route to the fruit API
    page.route("*/**/api/v1/fruits", handle)

    # Go to the page
    page.goto("https://demo.playwright.dev/api-mocking")

    # Assert that the Strawberry fruit is visible
    expect(page.get_by_text("Strawberry")).to_be_visible()
```

从示例测试的追踪记录中可以看到，该 API 并未被实际调用，而是直接使用了模拟数据进行填充。

![api mocking trace](互联网方向/Ai 测试/Python Playwright/Basics/assets/3dc14cbf-c100-4efc-ac21-d7b52d698b53.png)

了解有关 [高级网络](https://playwright.cn/python/docs/network) 的更多信息。

## 修改 API 响应

有时，发出 API 请求是必不可少的，但响应需要修补以实现可重现的测试。在这种情况下，可以执行请求并用修改后的响应来满足它，而不是模拟请求。

在下面的示例中，我们拦截了对水果 API 的调用，并向数据中添加了一种名为“枇杷”的新水果。然后我们转到 URL 并断言该数据存在。


```py
def test_gets_the_json_from_api_and_adds_a_new_fruit(page: Page):
    def handle(route: Route):
        response = route.fetch()
        json = response.json()
        json.append({ "name": "Loquat", "id": 100})

        # Fulfill using the original response, while patching the response body

        # with the given JSON object.
        route.fulfill(response=response, json=json)
    page.route("https://demo.playwright.dev/api-mocking/api/v1/fruits", handle)

    # Go to the page
    page.goto("https://demo.playwright.dev/api-mocking")

    # Assert that the new fruit is visible
    expect(page.get_by_text("Loquat", exact=True)).to_be_visible()
```

在测试的追踪记录中，我们可以看到 API 已被调用且响应内容已被修改。

![trace of test showing api being called and fulfilled](互联网方向/Ai 测试/Python Playwright/Basics/assets/8b8dd82d-1b3e-428e-871b-840581fed439.png)

通过检查响应，我们可以看到我们的新水果已成功添加到列表中。

![trace of test showing the mock response](互联网方向/Ai 测试/Python Playwright/Basics/assets/03e6c87c-4ecc-47e8-9ca0-30fface25e9d.png)

了解有关 [高级网络](https://playwright.cn/python/docs/network) 的更多信息。

## 使用 HAR 文件进行模拟

HAR 文件是一种 [HTTP 存档 (HTTP Archive)](http://www.softwareishard.com/blog/har-12-spec/) 文件，其中记录了页面加载时发出的所有网络请求。它包含有关请求和响应头、Cookie、内容、耗时等信息。你可以使用 HAR 文件在测试中模拟网络请求。你需要

1. 记录 HAR 文件。
2. 将 HAR 文件与测试一起提交。
3. 在测试中使用保存的 HAR 文件路由请求。

### 录制 HAR 文件

要录制 HAR 文件，我们可以使用 [page.route_from_har()](https://playwright.cn/python/docs/api/class-page#page-route-from-har) 或 [browser_context.route_from_har()](https://playwright.cn/python/docs/api/class-browsercontext#browser-context-route-from-har) 方法。此方法接受 HAR 文件的路径和一个可选的选项对象。选项对象可以包含 URL，以便只有 URL 与指定的 glob 模式匹配的请求才会从 HAR 文件中获取响应。如果未指定，所有请求都将从 HAR 文件中获取响应。

将 `update` 选项设置为 true 将创建或更新 HAR 文件，其中包含实际网络信息，而不是从 HAR 文件提供请求。在创建测试以使用真实数据填充 HAR 时使用它。

####

或者，您也可以在创建浏览器上下文时，通过在 [browser.new_context()](https://playwright.cn/python/docs/api/class-browser#browser-new-context) 中使用 [record_har_path](https://playwright.cn/python/docs/api/class-browser#browser-new-context-option-record-har-path) 选项来录制 HAR 文件。这使您能够捕获整个上下文的所有网络流量，直到上下文关闭为止。


```py
def test_records_or_updates_the_har_file(page: Page):
    # Get the response from the HAR file
    page.route_from_har("./hars/fruit.har", url="*/**/api/v1/fruits", update=True)

    # Go to the page
    page.goto("https://demo.playwright.dev/api-mocking")

    # Assert that the fruit is visible
    expect(page.get_by_text("Strawberry")).to_be_visible()
```

### 修改 HAR 文件

记录 HAR 文件后，您可以通过打开 'hars' 文件夹内的哈希 .txt 文件并编辑 JSON 来修改它。此文件应提交到您的源代码管理。每当您使用 `update: true` 运行此测试时，它都会使用来自 API 的请求来更新您的 HAR 文件。

```json
[
  {
    "name": "Playwright",

    "id": 100
  }

  // ... other fruits
]
```

### 从 HAR 回放

现在您已经记录了 HAR 文件并修改了模拟数据，可以在测试中使用它来提供匹配的响应。为此，只需关闭或简单地删除 `update` 选项。这将使测试针对 HAR 文件运行，而不是击中 API。


```py
def test_gets_the_json_from_har_and_checks_the_new_fruit_has_been_added(page: Page):
    # Replay API requests from HAR.

    # Either use a matching response from the HAR,

    # or abort the request if nothing matches.
    page.route_from_har("./hars/fruit.har", url="*/**/api/v1/fruits", update=False)

    # Go to the page
    page.goto("https://demo.playwright.dev/api-mocking")

    # Assert that the Playwright fruit is visible
    expect(page.get_by_text("Playwright", exact=True)).to_be_visible()
```

在测试的追踪记录中，我们可以看到路由已通过 HAR 文件完成填充，且 API 未被调用。

![trace showing the HAR file being used](互联网方向/Ai 测试/Python Playwright/Basics/assets/1bd7ab66-ea4f-43c2-a4e5-ca17d4837ff1.png)

如果我们检查响应，可以看到我们的新水果已成功添加到 JSON 中，这是通过手动更新 `hars` 文件夹内经过哈希处理的 `.txt` 文件来实现的。

![trace showing response from HAR file](互联网方向/Ai 测试/Python Playwright/Basics/assets/db3117fc-7b02-4973-9a51-29e213261a6a.png)

HAR 重放严格匹配 URL 和 HTTP 方法。对于 POST 请求，它还严格匹配 POST 有效载荷。如果多个记录匹配一个请求，则选择具有最多匹配头的记录。导致重定向的条目将自动跟随。

与记录时类似，如果给定的 HAR 文件名以 `.zip` 结尾，则认为它是一个包含 HAR 文件以及存储为单独条目的网络有效载荷的存档。您也可以解压此存档，手动编辑有效载荷或 HAR 日志，然后指向解压后的 har 文件。所有有效载荷都将相对于文件系统上的解压后的 har 文件解析。

#### 使用 CLI 录制 HAR

我们建议使用 `update` 选项来记录您的测试的 HAR 文件。但是，您也可以使用 Playwright CLI 记录 HAR。

使用 Playwright CLI 打开浏览器，并传递 `--save-har` 选项以生成 HAR 文件。可以选择使用 `--save-har-glob` 仅保存您感兴趣的请求，例如 API 端点。如果 har 文件名以 `.zip` 结尾，则工件作为单独的文件写入并全部压缩成一个 `zip`。

```bash
# Save API requests from example.com as "example.har" archive.

playwright open --save-har=example.har --save-har-glob="**/api/**" https://example.com
```

了解有关 [高级网络](https://playwright.cn/python/docs/network) 的更多信息。

## 模拟 WebSocket

以下代码将拦截 WebSocket 连接并模拟整个 WebSocket 通信，而不是连接到服务器。此示例响应 `"request"` 并带有一个 `"response"`。


```py
def message_handler(ws: WebSocketRoute, message: Union[str, bytes]):
  if message == "request":
    ws.send("response")

page.route_web_socket("wss://example.com/ws", lambda ws: ws.on_message(
    lambda message: message_handler(ws, message)
))
```

或者，您可能希望连接到实际服务器，但在中间拦截消息并修改或阻止它们。这是一个修改页面发送给服务器的一些消息，并保持其余消息不变的示例。


```py
def message_handler(server: WebSocketRoute, message: Union[str, bytes]):
  if message == "request":
    server.send("request2")
  else:
    server.send(message)


def handler(ws: WebSocketRoute):
  server = ws.connect_to_server()
  ws.on_message(lambda message: message_handler(server, message))

page.route_web_socket("wss://example.com/ws", handler)
```

有关更多详细信息，请参阅 [WebSocketRoute](https://playwright.cn/python/docs/api/class-websocketroute)。
