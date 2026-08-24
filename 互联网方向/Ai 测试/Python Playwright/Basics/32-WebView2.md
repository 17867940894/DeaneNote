## 简介

以下将解释如何将 Playwright 与 [Microsoft Edge WebView2](https://docs.microsoft.com/en-us/microsoft-edge/webview2/) 配合使用。WebView2 是一个 WinForms 控件，它底层使用 Microsoft Edge 来渲染网页内容。它是 Microsoft Edge 浏览器的一部分，在 Windows 10 和 Windows 11 上可用。Playwright 可用于自动化 WebView2 应用程序，并可用于测试 WebView2 中的网页内容。为了连接到 WebView2，Playwright 使用 [browser_type.connect_over_cdp()](https://playwright.cn/python/docs/api/class-browsertype#browser-type-connect-over-cdp)，该方法通过 Chrome 开发者工具协议 (CDP) 连接到它。

## 概述

可以通过设置 `WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS` 环境变量并包含 `--remote-debugging-port=9222`，或者调用带有 `--remote-debugging-port=9222` 参数的 [EnsureCoreWebView2Async](https://docs.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.wpf.webview2.ensurecorewebview2async?view=webview2-dotnet-1.0.1343.22) 方法，来指示 WebView2 控件监听传入的 CDP 连接。这将启动启用了 Chrome 调试协议的 WebView2 进程，从而允许 Playwright 进行自动化操作。此处的 9222 仅为示例端口，也可使用任何其他未被占用的端口。

```python
await this.webView.EnsureCoreWebView2Async(
    await CoreWebView2Environment.CreateAsync(
        null,
        null,
        new CoreWebView2EnvironmentOptions(){
            AdditionalBrowserArguments = "--remote-debugging-port=9222",
        }
    )
).ConfigureAwait(false);
```

一旦您的应用程序与 WebView2 控件一起运行，您就可以通过 Playwright 连接到它

```py
browser = playwright.chromium.connect_over_cdp("https://:9222")
context = browser.contexts[0]
page = context.pages[0]
```

为了确保 WebView2 控件已就绪，您可以等待 [`CoreWebView2InitializationCompleted`](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.wpf.webview2.corewebview2initializationcompleted?view=webview2-dotnet-1.0.1343.22) 事件。

```csharp
this.webView.CoreWebView2InitializationCompleted += (_, e) =>
{
    if (e.IsSuccess)
    {
        Console.WriteLine("WebView2 initialized");
    }
};
```

## 编写并运行测试

默认情况下，WebView2 控件会对所有实例使用相同的用户数据目录。这意味着如果您并行运行多个测试，它们会相互干扰。为避免这种情况，您应该为每个测试将 `WEBVIEW2_USER_DATA_FOLDER` 环境变量（或使用 [WebView2.EnsureCoreWebView2Async 方法](https://docs.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.wpf.webview2.ensurecorewebview2async?view=webview2-dotnet-1.0.1343.22)）设置为不同的文件夹。这将确保每个测试都在其自己的用户数据目录中运行。

通过以下方式，Playwright 将把你的 WebView2 应用程序作为子进程运行，为其分配一个独立的用户数据目录，并向你的测试提供 [Page](https://playwright.cn/python/docs/api/class-page) 实例

conftest.py

```python
import os
import socket
import tempfile
from pathlib import Path
import subprocess

import pytest
from playwright.sync_api import Playwright, Browser, BrowserContext
EXECUTABLE_PATH = (
    Path(__file__).parent
    / ".."
    / "webview2-app"
    / "bin"
    / "Debug"
    / "net8.0-windows"
    / "webview2.exe"
)


@pytest.fixture(scope="session")
def data_dir():
    with tempfile.TemporaryDirectory(
        prefix="playwright-webview2-tests", ignore_cleanup_errors=True
    ) as tmpdirname:
        yield tmpdirname


@pytest.fixture(scope="session")
def webview2_process_cdp_port(data_dir: str):
    cdp_port = _find_free_port()
    process = subprocess.Popen(
        [EXECUTABLE_PATH],
        env={
            **dict(os.environ),
            "WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS": f"--remote-debugging-port={cdp_port}",
            "WEBVIEW2_USER_DATA_FOLDER": data_dir,
        },
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        universal_newlines=True,
    )
    while True:
        line = process.stdout.readline()
        if "WebView2 initialized" in line:
            break
    yield cdp_port
    process.terminate()


@pytest.fixture(scope="session")
def browser(playwright: Playwright, webview2_process_cdp_port: int):
    browser = playwright.chromium.connect_over_cdp(
        f"http://127.0.0.1:{webview2_process_cdp_port}"
    )
    yield browser


@pytest.fixture(scope="function")
def context(browser: Browser):
    context = browser.contexts[0]
    yield context


@pytest.fixture(scope="function")
def page(context: BrowserContext):
    page = context.pages[0]
    yield page


def _find_free_port(port=9000, max_port=65535):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    while port <= max_port:
        try:
            sock.bind(("", port))
            sock.close()
            return port
        except OSError:
            port += 1
    raise IOError("no free ports")
```

test_webview2.py

```python
from playwright.sync_api import Page, expect


def test_webview2(page: Page):
    page.goto("https://playwright.cn")
    get_started = page.get_by_text("Get Started")
    expect(get_started).to_be_visible()
```

## 调试

在 WebView2 控件内部，您可以直接右键点击并选择“检查 (Inspect)”以打开 DevTools，或者按 F12 键。您也可以使用 [WebView2.CoreWebView2.OpenDevToolsWindow](https://learn.microsoft.com/en-us/dotnet/api/microsoft.web.webview2.core.corewebview2.opendevtoolswindow?view=webview2-dotnet-1.0.1462.37) 方法以编程方式打开 DevTools。

有关调试测试的信息，请参阅 Playwright [调试指南](https://playwright.cn/python/docs/debug)。
