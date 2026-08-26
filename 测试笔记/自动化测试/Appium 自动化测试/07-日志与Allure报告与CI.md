---
title: 07 日志与 Allure 报告与 CI
tags:
  - appium
  - 日志
  - Allure
  - 报告
  - CI
date created: 2026-08-24
---

# 07 日志与 Allure 报告与 CI

> [!info] 本节目标
> 1. 统一日志输出（带时间戳、级别、模块名）
> 2. 失败自动截图并随报告展示
> 3. 用 **Allure** 产出可分享的测试报告
> 4. 用 **GitHub Actions** 跑移动端测试（模拟器/云真机）
> 5. 产出 `logger.py` / `screenshot.py` / CI 工作流

相关笔记：[[Selenium全栈笔记/02-进阶笔记/05-截图日志#二、截图工具封装|Selenium 截图日志]]、[[互联网方向/Ai 测试/Python Playwright/入门指南/06-设置CI#设置 GitHub Actions|Playwright CI]]（**日志/截图/CI 思路完全一致**）

> [!tip] 你已会这些，本节做"迁移到 Appium"
> 日志用标准 `logging`、截图用 `driver.save_screenshot`、CI 用 GitHub Actions——都和你已有的 Web 自动化一致。移动端 CI 的唯一特殊点是**需要 Android 模拟器或云真机**，本节给出可运行的 workflow。

---

## 一、日志封装 `utils/logger.py`

```python title="utils/logger.py"
import logging
import os

def get_logger(name: str = "appium"):
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger  # 避免重复添加 handler
    logger.setLevel(logging.DEBUG)

    os.makedirs("logs", exist_ok=True)
    fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s")

    fh = logging.FileHandler("logs/appium.log", encoding="utf-8")
    fh.setFormatter(fmt)
    fh.setLevel(logging.DEBUG)

    sh = logging.StreamHandler()
    sh.setFormatter(fmt)
    sh.setLevel(logging.INFO)

    logger.addHandler(fh)
    logger.addHandler(sh)
    return logger

logger = get_logger()
```

在页面/用例里：`from utils.logger import logger; logger.info("登录成功")`

---

## 二、失败自动截图 `utils/screenshot.py`

```python title="utils/screenshot.py"
import os
import time


def screenshot_on_failure(driver, name: str = None) -> str:
    name = name or f"fail_{int(time.time())}"
    os.makedirs("screenshots", exist_ok=True)
    path = os.path.join("screenshots", f"{name}.png")
    try:
        driver.save_screenshot(path)
    except Exception as e:
        return f"截图失败: {e}"
    return path
```

在 `conftest.py` 里失败自动调用（见 [[01-环境搭建与工程初始化#3.7 pytest 配置 pytest.ini + 夹具 conftest.py]] 的 `pytest_runtest_makereport` 钩子）。

---

## 三、Allure 报告

### 3.1 安装与运行

```bash
pip install allure-pytest -i https://pypi.tuna.tsinghua.edu.cn/simple
# 生成原始结果
pytest --alluredir=reports/allure -v
# 本地起服务查看（需 Java 运行 allure CLI）
allure serve reports/allure
```

> 若没装 allure CLI，可用 `pip install allure-commandline` 或下载 <https://github.com/allure-framework/allure2/releases>。

### 3.2 在用例里加 Allure 标注（让报告可读）

```python title="testcases/test_login_allure.py"
import allure
from pages.login_page import LoginPage
from pages.home_page import HomePage
from utils.screenshot import screenshot_on_failure


@allure.feature("登录模块")
@allure.story("账号密码登录")
class TestLoginAllure:
    @allure.title("正常登录并跳转首页")
    def test_login_success(self, driver):
        with allure.step("输入账号密码并登录"):
            LoginPage(driver).load().login("13800000001", "Test@123")
        with allure.step("等待首页加载"):
            from selenium.webdriver.support.ui import WebDriverWait
            from selenium.webdriver.support import expected_conditions as EC
            WebDriverWait(driver, 10).until(
                EC.activity_started("com.tal.kaoyan", "com.tal.kaoyan.ui.activity.HomeTabActivity")
            )
        with allure.step("断言首页可见"):
            assert HomePage(driver).is_loaded()
            # 失败截图随报告展示
            allure.attach.file(
                screenshot_on_failure(driver, "login_ok"),
                name="首页截图",
                attachment_type=allure.attachment_type.PNG,
            )
```

### 3.3 HTML 报告（零依赖备选）

`pytest.ini` 里加 `--html=reports/report.html --self-contained-html`，无需 Java 即可产出单文件 HTML 报告。

---

## 四、CI：GitHub Actions 跑移动端测试

> [!warning] 移动端 CI 的特殊性
> 和 Web/Playwright 不同，Appium 测试**必须有一个 Android 运行环境**（模拟器或真机）。GitHub 的 `ubuntu-latest` 不自带模拟器，需用 `reactivecircus/android-emulator-runner` 拉起模拟器，或接云真机（BrowserStack / Sauce Labs / 阿里云真机）。

```yaml title=".github/workflows/appium.yml"
name: Appium Android Tests

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  appium-test:
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.13'

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Appium 2 + UiAutomator2 driver
        run: |
          npm install -g appium@2
          appium driver install uiautomator2

      - name: Install Python deps
        run: pip install -r requirements.txt

      - name: Run tests on Android emulator
        uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 33
          target: google_apis
          arch: x86_64
          profile: pixel_5
          script: |
            appium --relaxed-security --log appium.log &
            sleep 15
            pytest --alluredir=reports/allure -v

      - name: Upload Allure report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: allure-report
          path: reports/allure

      - name: Upload Appium log (排查用)
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: appium-log
          path: appium.log
```

> [!note] 云真机方案
> 模拟器在 CI 上较慢且偶有兼容问题。生产团队常用云真机：在 workflow 里把 `appium:udid` 指向云真机提供的设备 ID，并把 `server_url` 指向云厂商的 Appium Hub（如 BrowserStack `https://<user>:<key>@hub-cloud.browserstack.com/wd/hub`）。其余代码不变。

---

## 五、运行前提与执行命令

```bash
# 本地
pytest --alluredir=reports/allure -v
allure serve reports/allure

# CI
git push   # 自动触发 GitHub Actions
```

### 预期结果

- `reports/allure/` 生成 Allure 原始数据
- `allure serve` 打开交互式报告：用例树、步骤、失败截图、日志
- CI 面板显示 passed/failed，失败时可在 Artifacts 下载 Appium 日志

---

## 六、常见报错与排查点

| 报错 / 现象 | 原因 | 解决 |
| --- | --- | --- |
| `allure: command not found` | 没装 allure CLI | 装 allure CLI；或用 `--html` 单文件报告替代 |
| 报告里没有截图 | 没调 `allure.attach.file` | 在失败分支/step 里 attach 截图路径 |
| 日志重复打印 | handler 被加多次 | `logger` 用单例（见 `get_logger` 的 `if logger.handlers` 判断） |
| CI 一直卡在启动模拟器 | 模拟器拉起慢/资源不足 | 加大 `timeout-minutes`；或改用云真机 |
| CI 报 `device not found` | Runner 里 udid 没设 | workflow 里 `config.yaml` 的 udid 留空，让 Appium 自动选默认模拟器 |
| 产物太大上传失败 | 截图/日志过多 | 只上传 `reports/` 和 `appium.log`，忽略 `screenshots/` |

---

> 完整可运行工程见 **`03-实战项目/`**：`README.md` 有目录树与一键运行说明，`报错解决方案.md` 有更全的 FAQ。

> 返回总索引：[[README]]
