---
title: 04 常用操作 API
tags:
  - appium
  - 操作API
  - 手势
  - 上下文切换
  - 移动端自动化
date created: 2026-08-24
---

# 04 常用操作 API

> [!info] 本节目标
>
> 1. 掌握点击/输入/清空，以及 **中文输入的坑与解法**
> 2. 掌握移动端专属：滑动、滚动查找、长按、拖拽、键盘码
> 3. 掌握截图、Toast 获取
> 4. 掌握 **WebView / H5 上下文切换**（混合 App 必会）
> 5. 串起 "登录 → 首页" 完整可交互流程

相关笔记：[[02-元素定位策略]]、[[03-等待机制]]、[[Selenium全栈笔记/01-基础笔记/04-基础操作#一、元素操作|Selenium 基础操作]]

> [!note]
>
> 代码归属说明（先读这个）
>
> 本节代码都来自 [[01-环境搭建与工程初始化#三、第一个工程骨架（工程化优先，拒绝零散脚本）]] 的工程骨架，代码块标题统一为 **语言 + title = "文件路径"**：
>
> | title | 对应文件 |
> | --- | --- |
> | `pages/base_page.py` | 页面基类（01 最小版 / [[05-PO模式与页面封装#二、PO 分层结构]] 完整版） |
> | `utils/wait_helper.py` | 显式等待封装（[[03-等待机制#三、WaitHelper 强化版（移动端专属）]] 完整版） |
> | `config/config.yaml` | 全局配置（01 已建） |
> | `testcases/test_*.py` | 用例层 |
>
> 2.2~2.5 的手势方法标 `pages/base_page.py`，表示 **按需追加进 `BasePage` 的新方法**（01/05 的 BasePage 里还没有）；`testcases/test_xxx.py` 表示在用例中的调用方式。

---

## 一、基础操作（点击 / 输入 / 清空）

封装在 `BasePage` 里（见 [[01-环境搭建与工程初始化#3.6 页面基类 pages/base_page.py（先放最小版）]]、`[[05-PO模式与页面封装#三、BasePage（Appium 版）]]`）：

```python title="pages/base_page.py"
def click(self, locator, timeout=None):
    self.wait.element_clickable(locator, timeout).click()
    return self


def type(self, locator, text, timeout=None):
    el = self.wait.element_visible(locator, timeout)
    el.clear()                     # 清空
    el.send_keys(text)             # 输入（Appium 的 send_keys 等价于 Web 的 send_keys）
    return self
```

```python title="testcases/test_xxx.py"
base = BasePage(driver)
base.type((AppiumBy.ID, "com.tal.kaoyan:id/login_account_edittext"), "13800000001")
base.click((AppiumBy.ID, "com.tal.kaoyan:id/login_login_btn"))
```

> 底层就是 `driver.find_element(AppiumBy.ID, "...")` 找到元素再调 `.click()` / `.clear()` / `.send_keys()`。工程上不裸调，统一走 `BasePage` 封装（复用 + 自带显式等待）。

### 1.1 中文输入法坑（必看）

Android 默认输入法常常 **吞掉中文**，`send_keys("验证码")` 会变成空或乱码。

**解法**：在 `config.yaml` 的 capabilities 打开 Appium 的自带 Unicode 键盘（01 里默认注释掉了这两行）：

```yaml title="config/config.yaml"
capabilities:
  # ...
  unicodeKeyboard: true # 用 Appium 输入法，支持中文/特殊字符
  resetKeyboard: true # 测试结束还原系统输入法
```

> [!tip]
>
> 打开后模拟器输入法会变成 "Unicode IME"，手动输入会不方便——这正是自动化要的。CI 结束后 `resetKeyboard` 会还原。

---

## 二、手势操作（移动端核心差异点）

> [!note]
>
> 本节代码的归宿
>
> 2.1 的 `swipe_up` 已在 [[05-PO模式与页面封装#三、BasePage（Appium 版）]] 的 `BasePage` 里落地；2.2~2.5 是 **追加进 `pages/base_page.py` 的扩展方法**（都加在类体内，import 放到文件顶部）。

### 2.1 滑动 `driver.swipe`

```python title="pages/base_page.py"
def swipe_up(self, duration=800):
    size = self.driver.get_window_size()
    w, h = size["width"], size["height"]
    # 从 (w/2, 0.8h) 滑到 (w/2, 0.2h)，耗时 duration 毫秒（上滑翻页/下拉刷新同理）
    self.driver.swipe(w // 2, int(h * 0.8), w // 2, int(h * 0.2), duration)
    return self
```

> 底层 API：`driver.swipe(start_x=500, start_y=1200, end_x=500, end_y=400, duration=800)`——四个坐标 + 时长（毫秒）。**坐标按 `get_window_size()` 算，别写死**（见文末 tip）。

### 2.2 滚动查找（UiScrollable，最稳的 "找到再操作"）

列表很长时，用原生 UiScrollable 把元素滚到视野内再返回：

```python title="pages/base_page.py"
from appium.webdriver.common.appiumby import AppiumBy   # 文件顶部 import


def scroll_to_text(self, text):
    """滚动查找：把指定文本的元素滚进视野并返回，找不到抛 NoSuchElementException"""
    locator = (
        AppiumBy.ANDROID_UIAUTOMATOR,
        'new UiScrollable(new UiSelector().scrollable(true))'
        f'.scrollIntoView(new UiSelector().text("{text}"))'
    )
    return self.driver.find_element(*locator)
```

```python title="testcases/test_xxx.py"
base.scroll_to_text("设置").click()
```

### 2.3 长按（W3C ActionChains，Appium 2 推荐）

> [!warning]
>
> TouchAction 已废弃
> Appium 2 / Python Client 3 中 `TouchAction` 已废弃，改用标准 **W3C Actions**。

```python title="pages/base_page.py"
from selenium.webdriver.common.action_chains import ActionChains   # 文件顶部 import


def long_press(self, x, y, duration=2):
    """长按坐标 (x, y)，duration 单位：秒"""
    actions = ActionChains(self.driver)
    actions.w3c_actions.pointer_action.move_to_location(x, y)
    actions.w3c_actions.pointer_action.pointer_down()
    actions.w3c_actions.pointer_action.pause(duration)   # 按住时长（秒）
    actions.w3c_actions.pointer_action.pointer_up()
    actions.perform()
    return self
```

```python title="testcases/test_xxx.py"
base.long_press(540, 900, duration=2)   # 长按 2 秒
```

### 2.4 拖拽 `driver.drag_and_drop`

```python title="pages/base_page.py"
def drag(self, src_locator, dst_locator):
    """把 src 元素拖到 dst 元素（传入定位器，内部先各自 find）"""
    src = self.driver.find_element(*src_locator)
    dst = self.driver.find_element(*dst_locator)
    self.driver.drag_and_drop(src, dst)
    return self
```

```python title="testcases/test_xxx.py"
base.drag((AppiumBy.ID, "drag_source"), (AppiumBy.ID, "drag_target"))
```

### 2.5 双指缩放（W3C 多指针）

```python title="pages/base_page.py"
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.actions.pointer_input import PointerInput
from selenium.webdriver.common.actions import interaction   # 文件顶部 import


def pinch(self, center_x, center_y, distance=150, duration=1, zoom_in=True):
    """双指缩放（以地图/图片缩放为例）
    zoom_in=True  → 两指向外张开（放大）
    zoom_in=False → 两指向内收拢（缩小）
    要点：两指必须用独立的 PointerInput；各指动作先构造完，perform() 时并行执行
    """
    half = distance // 2
    start_off = half if zoom_in else distance   # 起始偏移
    end_off   = distance if zoom_in else half   # 结束偏移
    actions = ActionBuilder(self.driver)
    finger1 = PointerInput(interaction.POINTER_TOUCH, "finger1")
    finger2 = PointerInput(interaction.POINTER_TOUCH, "finger2")

    # 指 1（左侧）：add 之后 pointer_action 才指向它，动作构造完整再 add 指 2
    actions.add_pointer_input(finger1)
    actions.pointer_action.move_to_location(center_x - start_off, center_y)
    actions.pointer_action.pointer_down()
    actions.pointer_action.move_to_location(center_x - end_off, center_y, duration=duration)
    actions.pointer_action.pointer_up()

    # 指 2（右侧）：两条指针轨道相互独立，perform() 时并行执行
    actions.add_pointer_input(finger2)
    actions.pointer_action.move_to_location(center_x + start_off, center_y)
    actions.pointer_action.pointer_down()
    actions.pointer_action.move_to_location(center_x + end_off, center_y, duration=duration)
    actions.pointer_action.pointer_up()
    actions.perform()
```

```python title="testcases/test_xxx.py"
def test_gesture_demo(self, driver):
    """手势演示：长按 + 双指缩放（放大/缩小）。"""
    base = BasePage(driver)
    base.long_press(540, 900, duration=2)
    size = driver.get_window_size()
    cx, cy = size["width"] // 2, size["height"] // 2
    base.pinch(cx, cy, distance=150, duration=1, zoom_in=True)  # 放大
    base.pinch(cx, cy, distance=150, duration=1, zoom_in=False)
```

---

## 三、设备按键与系统交互

```python title="pages/base_page.py"
def back(self):
    self.driver.back()          # 返回键（等价物理返回）
    return self
```

```python title="testcases/test_xxx.py"
    def test_gesture_demo(self, driver):
        # 键盘码：66 = KEYCODE_ENTER，3 = HOME，4 = BACK
        driver.press_keycode(66)

        # 直接拉起某 Activity（跳过启动页，省时间）
        # 注意：LoginKActivity 未导出（not exported），无法通过 am start 拉起，需用 launcher Activity；
        #       appium-python-client 3.x 已移除 driver.start_activity()，改用 mobile: startActivity 脚本命令
        driver.execute_script(
            "mobile: startActivity",
            {"intent": "com.tal.kaoyan/com.tal.kaoyan.ui.activity.SplashActivity"},
        )

        # 重置 App：Appium 2 已移除 driver.reset()，用"关 + 开"代替
        driver.terminate_app("com.tal.kaoyan")      # 关闭
        driver.activate_app("com.tal.kaoyan")       # 重新打开
        # 彻底清数据：adb shell pm clear com.tal.kaoyan
```

按键码速查（部分）：

| 键码 | 含义 |
| --- | --- |
| 3 | HOME |
| 4 | BACK |
| 26 | POWER |
| 66 | ENTER |
| 82 | MENU |

---

## 四、截图与 Toast

```python title="pages/base_page.py"
def screenshot(self, name=None):
    import os
    name = name or f"screenshot_{int(time.time())}"
    os.makedirs("screenshots", exist_ok=True)
    path = f"screenshots/{name}.png"
    self.driver.save_screenshot(path)
    return path
```

```python title="utils/wait_helper.py"
def toast_visible(self, text: str, timeout=5):
    """等待 Android Toast（如"登录成功""密码错误"），返回该元素"""
    locator = (AppiumBy.XPATH, f'//android.widget.Toast[@text="{text}"]')
    return WebDriverWait(self.driver, timeout).until(
        EC.presence_of_element_located(locator)
    )
```

```python title="testcases/test_xxx.py"
base.screenshot("login_success")      # 截图（失败自动截图见 [[07-日志与Allure报告与CI#二、失败自动截图 utils/screenshot.py]]）
toast = base.wait.toast_visible("密码错误")   # 等 Toast 出现（几秒就消失，立即取文本）
print(toast.text)
```

---

## 五、WebView / H5 上下文切换（混合 App 必会）

很多 App 内嵌 H5 页面（如活动页、客服页）。这类页面在 `NATIVE_APP` 上下文下 **无法用普通方式定位**，必须先切到 `WEBVIEW_xxx` 上下文。

```python title="testcases/test_webview.py"
# 1) 查看当前有哪些上下文
print(driver.contexts)        # ['NATIVE_APP', 'WEBVIEW_com.tal.kaoyan']
# 2) 切到 WebView（H5 页面已在前台时）
driver.switch_to.context("WEBVIEW_com.tal.kaoyan")
# 3) 此刻可用 CSS / XPath 定位 H5 元素（和 Web 自动化一模一样）
driver.find_element(AppiumBy.CSS_SELECTOR, ".activity-title").click()
# 4) 切回原生
driver.switch_to.context("NATIVE_APP")
```

> [!warning] 
>
> 切 WebView 前必须满足条件
>
> - App 已打开 H5 页面（前台可见）
> - 该 WebView 需开启 **WebView 调试**（开发需在 App 代码里 `WebView.setWebContentsDebuggingEnabled(true)`），否则 `WEBVIEW_xxx` 不会出现
> - 真机/模拟器需能 `adb shell cat /proc/net/unix | grep webview` 看到调试通道

---

## 六、实战：登录 → 首页完整流程

```python title="testcases/test_login_flow.py"
import pytest
from appium.webdriver.common.appiumby import AppiumBy
from pages.login_page import LoginPage
from pages.home_page import HomePage


class TestLoginFlow:
    def test_login_then_enter_home(self, driver):
        # 1) 登录页：输入并登录
        login = LoginPage(driver)
        login.login("13800000001", "Test@123")

        # 2) 等待首页 Activity（App 专属等待，见 [[03-等待机制#三、WaitHelper 强化版（移动端专属）]]）
        from selenium.webdriver.support.ui import WebDriverWait
        from selenium.webdriver.support import expected_conditions as EC
        WebDriverWait(driver, 10).until(
            EC.activity_started("com.tal.kaoyan", "com.tal.kaoyan.ui.activity.HomeTabActivity")
        )

        # 3) 首页：断言欢迎/用户名可见
        home = HomePage(driver)
        assert home.is_loaded(), "首页未加载"
        print("✅ 登录→首页流程跑通")
```

> 用到的 `LoginPage` / `HomePage` 定义见 [[05-PO模式与页面封装#四、业务页面对象]] 的 `pages/login_page.py`、`pages/home_page.py`。

---

## 七、运行前提与执行命令

### 运行前提

1. 同 [[01-环境搭建与工程初始化#三、第一个工程骨架（工程化优先，拒绝零散脚本）]]
2. 考研帮有可用测试账号
3. 若测中文输入，确认 `config.yaml` 已开 `unicodeKeyboard`

### 执行命令

```bash
pytest testcases/test_login_flow.py -v
```

### 预期结果

```text
test_login_flow.py::TestLoginFlow::test_login_then_enter_home PASSED
✅ 登录→首页流程跑通
===== 1 passed =====
```

模拟器上自动完成：输入账号密码 → 点登录 → 跳首页 → 断言成功。

---

## 八、常见报错与排查点

| 报错 / 现象 | 原因 | 解决 |
| --- | --- | --- |
| 中文 `send_keys` 变空/乱码 | 默认输入法不认 | 开 `unicodeKeyboard: true`（见 1.1） |
| `swipe` 滑动无反应 | 坐标超出屏幕 / duration 太小 | 用 `driver.get_window_size()` 取真实尺寸算坐标；duration ≥ 500ms |
| 长按不生效 | 仍用 `TouchAction` | 改用 W3C `ActionChains`（见 2.3） |
| 找不到 H5 元素 | 没切上下文 / WebView 未开调试 | 先 `switch_to.context("WEBVIEW_xxx")`；确认 App 开启调试 |
| `driver.contexts` 只有 `NATIVE_APP` | H5 页没在前台 / 未开调试 | 先手动进 H5 页再切；让开发开 WebView 调试 |
| `press_keycode` 报非法码 | 码值错 | 用标准 AndroidKeyCode（3/4/26/66/82…） |
| `save_screenshot` 路径报错 | 目录不存在 | `os.makedirs("screenshots", exist_ok=True)`（封装在 `BasePage.screenshot` 里） |
| `driver.reset()` 报 `not implemented` | Appium 2 已移除该方法 | 改用 `terminate_app` + `activate_app`（见第三章） |

> [!tip] 
>
> 取屏幕坐标的通用写法
>
> ```python title="testcases/test_xxx.py"
> size = driver.get_window_size()
> w, h = size["width"], size["height"]
> driver.swipe(w//2, int(h*0.8), w//2, int(h*0.2), 800)   # 上滑，自适应分辨率
> ```

---

> 下一节：[[05-PO模式与页面封装]]
