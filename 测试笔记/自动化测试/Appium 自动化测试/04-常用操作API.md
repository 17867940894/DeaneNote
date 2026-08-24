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
> 1. 掌握点击/输入/清空，以及**中文输入的坑与解法**
> 2. 掌握移动端专属：滑动、滚动查找、长按、拖拽、键盘码
> 3. 掌握截图、Toast 获取
> 4. 掌握 **WebView / H5 上下文切换**（混合 App 必会）
> 5. 串起"登录 → 首页"完整可交互流程

相关笔记：[[02-元素定位策略]]、[[03-等待机制]]、[[Selenium 全栈笔记/01-基础笔记/04-基础操作|Selenium 基础操作]]

---

## 一、基础操作（点击 / 输入 / 清空）

封装在 `BasePage` 里（见 [[01-环境搭建与工程初始化]]、`[[05-PO模式与页面封装]]`）：

```python
# 点击
driver.find_element(AppiumBy.ID, "...").click()

# 输入（Appium 的 send_keys 等价于 Web 的 send_keys）
el = driver.find_element(AppiumBy.ID, "com.tal.kaoyan:id/login_account_edittext")
el.clear()                  # 清空
el.send_keys("13800000001")
```

### 1.1 中文输入法坑（必看）

Android 默认输入法常常**吞掉中文**，`send_keys("验证码")` 会变成空或乱码。

**解法**：在 `config.yaml` 的 capabilities 打开 Appium 的自带 Unicode 键盘：

```yaml
capabilities:
  # ...
  unicodeKeyboard: true     # 用 Appium 输入法，支持中文/特殊字符
  resetKeyboard: true       # 测试结束还原系统输入法
```

> [!tip] 打开后模拟器输入法会变成 "Unicode IME"，手动输入会不方便——这正是自动化要的。CI 结束后 `resetKeyboard` 会还原。

---

## 二、手势操作（移动端核心差异点）

### 2.1 滑动 `driver.swipe`

```python
# 从 (500,1200) 滑到 (500,400)，耗时 800ms（上滑翻页/下拉刷新同理）
driver.swipe(start_x=500, start_y=1200, end_x=500, end_y=400, duration=800)
```

### 2.2 滚动查找（UiScrollable，最稳的"找到再操作"）

列表很长时，用原生 UiScrollable 把元素滚到视野内再返回：

```python
from appium.webdriver.common.appiumby import AppiumBy

locator = (AppiumBy.ANDROID_UIAUTOMATOR,
           'new UiScrollable(new UiSelector().scrollable(true))'
           '.scrollIntoView(new UiSelector().text("设置"))')
driver.find_element(*locator).click()
```

### 2.3 长按（W3C ActionChains，Appium 2 推荐）

> [!warning] TouchAction 已废弃
> Appium 2 / Python Client 3 中 `TouchAction` 已废弃，改用标准 **W3C Actions**。

```python
from selenium.webdriver.common.action_chains import ActionChains

def long_press(driver, x, y, duration=2):
    actions = ActionChains(driver)
    actions.w3c_actions.pointer_action.move_to_location(x, y)
    actions.w3c_actions.pointer_action.pointer_down()
    actions.w3c_actions.pointer_action.pause(duration)   # 按住时长（秒）
    actions.w3c_actions.pointer_action.pointer_up()
    actions.perform()

long_press(driver, 540, 900, duration=2)   # 长按 2 秒
```

### 2.4 拖拽 `driver.drag_and_drop`

```python
src = driver.find_element(AppiumBy.ID, "drag_source")
dst = driver.find_element(AppiumBy.ID, "drag_target")
driver.drag_and_drop(src, dst)
```

### 2.5 双指缩放（W3C 多指针）

```python
from selenium.webdriver.common.actions.action_builder import ActionBuilder
from selenium.webdriver.common.actions.pointer_input import PointerInput
from selenium.webdriver.common.actions import interaction

# 以地图/图片缩放为例：两指向外张开
builder = ActionBuilder(driver)
finger1 = PointerInput(interaction.POINTER_TOUCH, "finger1")
finger2 = PointerInput(interaction.POINTER_TOUCH, "finger2")
# ... pinch out 动作略，按需用 ActionBuilder 构造双指轨迹
```

---

## 三、设备按键与系统交互

```python
# 返回键（等价物理返回）
driver.back()

# 键盘码：66 = KEYCODE_ENTER，3 = HOME，4 = BACK
driver.press_keycode(66)

# 直接拉起某 Activity（跳过启动页，省时间）
driver.start_activity("com.tal.kaoyan", "com.kaoyan.kylogin.ui.login.LoginKActivity")

# 重置 App（清数据并重开）
driver.reset()
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

```python
import os, time

# 截图（失败自动截图见 [[07-日志与Allure报告与CI]]）
os.makedirs("screenshots", exist_ok=True)
driver.save_screenshot(f"screenshots/{int(time.time())}.png")

# 获取安卓 Toast（短提示，几秒消失）
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
toast = WebDriverWait(driver, 5).until(
    EC.presence_of_element_located(
        (AppiumBy.XPATH, '//android.widget.Toast[@text="密码错误"]')
    )
)
print(toast.text)
```

---

## 五、WebView / H5 上下文切换（混合 App 必会）

很多 App 内嵌 H5 页面（如活动页、客服页）。这类页面在 `NATIVE_APP` 上下文下**无法用普通方式定位**，必须先切到 `WEBVIEW_xxx` 上下文。

```python
# 1) 查看当前有哪些上下文
print(driver.contexts)        # ['NATIVE_APP', 'WEBVIEW_com.tal.kaoyan']

# 2) 切到 WebView（H5 页面已在前台时）
driver.switch_to.context("WEBVIEW_com.tal.kaoyan")

# 3) 此刻可用 CSS / XPath 定位 H5 元素（和 Web 自动化一模一样）
driver.find_element(AppiumBy.CSS_SELECTOR, ".activity-title").click()

# 4) 切回原生
driver.switch_to.context("NATIVE_APP")
```

> [!warning] 切 WebView 前必须满足条件
> - App 已打开 H5 页面（前台可见）
> - 该 WebView 需开启 **WebView 调试**（开发需在 App 代码里 `WebView.setWebContentsDebuggingEnabled(true)`），否则 `WEBVIEW_xxx` 不会出现
> - 真机/模拟器需能 `adb shell cat /proc/net/unix | grep webview` 看到调试通道

---

## 六、实战：登录 → 首页完整流程

```python
import pytest
from appium.webdriver.common.appiumby import AppiumBy
from pages.login_page import LoginPage
from pages.home_page import HomePage


class TestLoginFlow:
    def test_login_then_enter_home(self, driver):
        # 1) 登录页：输入并登录
        login = LoginPage(driver)
        login.login("13800000001", "Test@123")

        # 2) 等待首页 Activity（App 专属等待，见 [[03-等待机制]]）
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

---

## 七、运行前提与执行命令

### 运行前提

1. 同 [[01-环境搭建与工程初始化]]
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
| `save_screenshot` 路径报错 | 目录不存在 | `os.makedirs("screenshots", exist_ok=True)` |

> [!tip] 取屏幕坐标的通用写法
> ```python
> size = driver.get_window_size()
> w, h = size["width"], size["height"]
> driver.swipe(w//2, int(h*0.8), w//2, int(h*0.2), 800)   # 上滑，自适应分辨率
> ```

---

> 下一节：[[05-PO模式与页面封装]]
