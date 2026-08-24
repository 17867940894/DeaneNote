## 简介

注意

扩展程序仅在使用持久化上下文启动 Chromium 时才起作用。使用自定义浏览器参数需自行承担风险，因为其中某些参数可能会破坏 Playwright 的功能。

Google Chrome 和 Microsoft Edge [移除了侧载扩展所需的命令行标志](https://groups.google.com/a/chromium.org/g/chromium-extensions/c/FxMU1TvxWWg/m/daZVTYNlBQAJ)，因此请使用 Playwright 自带的 Chromium。

下面的代码片段获取了源码位于 `./my-extension` 的 [service worker](https://developer.chrome.com/docs/extensions/develop/concepts/service-workers)，该扩展为 [Manifest v3](https://developer.chrome.com/docs/extensions/develop/migrate) 扩展。

请注意，这里使用了允许在无头模式下运行扩展的 `chromium` 通道。或者，你也可以以有头模式启动浏览器。

```python
from playwright.sync_api import sync_playwright, Playwright

path_to_extension = "./my-extension"
user_data_dir = "/tmp/test-user-data-dir"

def run(playwright: Playwright):
    context = playwright.chromium.launch_persistent_context(
        user_data_dir,
        channel="chromium",
        args=[
            f"--disable-extensions-except={path_to_extension}",
            f"--load-extension={path_to_extension}",
        ],
    )
    if len(context.service_workers) == 0:
        service_worker = context.wait_for_event('serviceworker')
    else:
        service_worker = context.service_workers[0]

    # Test the service worker as you would any other worker.
    context.close()


with sync_playwright() as playwright:
    run(playwright)
```

## Service Worker 空闲挂起 (MV3)

Chrome MV3 service worker 在不活动约 30 秒后会自动挂起，并在需要时重新启动。发生这种情况时，Playwright 会保持 **相同的 [Worker](https://playwright.cn/python/docs/api/class-worker) 对象处于活动状态** — 不会触发新的 `'serviceworker'` 事件。在重新启动窗口期间发出的新的 `evaluate()` 调用将被暂停，直到新上下文准备就绪后自动恢复。

```python
sw = context.wait_for_event('serviceworker')

# ... SW suspends after 30 s of inactivity and is restarted by the browser ...

# The existing handle is transparent across the restart.
sw.evaluate("sendMessage({ type: 'ping' })")  # just works
```

注意

在恰好挂起的时刻已经在执行中的 `evaluate()` 调用将抛出 `"Service worker restarted"` 错误，这与页面在传输中导航的行为相匹配。

## 测试

要在运行测试时加载扩展，可以使用测试夹具（fixture）来设置上下文。你还可以动态获取扩展 ID，并使用它来加载和测试弹出页面等。

请注意，这里使用了允许在无头模式下运行扩展的 `chromium` 通道。或者，你也可以以有头模式启动浏览器。

首先，添加将加载扩展的测试夹具

```python
from typing import Generator
from pathlib import Path
from playwright.sync_api import Playwright, BrowserContext
import pytest


@pytest.fixture()
def context(playwright: Playwright) -> Generator[BrowserContext, None, None]:
    path_to_extension = Path(__file__).parent.joinpath("my-extension")
    context = playwright.chromium.launch_persistent_context(
        "",
        channel="chromium",
        args=[
            f"--disable-extensions-except={path_to_extension}",
            f"--load-extension={path_to_extension}",
        ],
    )
    yield context
    context.close()


@pytest.fixture()
def extension_id(context) -> Generator[str, None, None]:
    # for manifest v3:
    service_worker = context.service_workers[0]
    if not service_worker:
        service_worker = context.wait_for_event("serviceworker")

    extension_id = service_worker.url.split("/")[2]
    yield extension_id
```

然后在测试中使用这些测试夹具

```python
from playwright.sync_api import expect, Page


def test_example_test(page: Page) -> None:
    page.goto("https://example.com")
    expect(page.locator("body")).to_contain_text("Changed by my-extension")


def test_popup_page(page: Page, extension_id: str) -> None:
    page.goto(f"chrome-extension://{extension_id}/popup.html")
    expect(page.locator("body")).to_have_text("my-extension popup")
```

