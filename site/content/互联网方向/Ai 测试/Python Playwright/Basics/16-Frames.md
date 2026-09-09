## 简介

一个 [Page](https://playwright.cn/python/docs/api/class-page) 可以包含一个或多个与之关联的 [Frame](https://playwright.cn/python/docs/api/class-frame) 对象。每个页面都有一个主框架，页面级别的交互（如 `click`）默认在主框架中执行。

页面可以使用 `iframe` HTML 标签附加额外的框架。这些框架可以用于框架内部的交互。

```python
# Locate element inside frame
# Get frame using any other selector
username = page.frame_locator('.frame-class').get_by_label('User Name')
username.fill('John')
```

## Frame 对象

可以使用 [page.frame()](https://playwright.cn/python/docs/api/class-page#page-frame) API 访问框架对象

```python
# Get frame using the frame's name attribute
frame = page.frame('frame-login')

# Get frame using frame's URL
frame = page.frame(url=r'.*domain.*')

# Interact with the frame
frame.fill('#username-input', 'John')
```

