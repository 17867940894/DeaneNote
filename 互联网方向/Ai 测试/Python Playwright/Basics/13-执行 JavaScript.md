## 简介

Playwright 脚本在您的 Playwright 环境中运行。您的页面脚本在浏览器页面环境中运行。这些环境不会交叉，它们在不同的虚拟机中、不同的进程中，甚至可能在不同的计算机上运行。

[page.evaluate()](https://playwright.cn/python/docs/api/class-page#page-evaluate) API 可以在网页上下文中运行 JavaScript 函数，并将结果返回给 Playwright 环境。像 `window` 和 `document` 这样的浏览器全局变量可以在 `evaluate` 中使用。

```python
href = page.evaluate('() => document.location.href')
```

如果结果是 Promise 或者函数是异步的，evaluate 将自动等待其解析。

```python
status = page.evaluate("""async () => {
  response = await fetch(location.href)
  return response.status
}""")
```

## 不同环境

评估脚本在浏览器环境中运行，而您的测试在测试环境中运行。这意味着您不能在页面中使用测试中的变量，反之亦然。相反，您应该将它们显式地作为参数传递。

> [!FAILURE]  
>
> 以下代码片段是**错误**的，因为它直接使用了变量

```python
data = "some data"
result = page.evaluate("""() => {
  // WRONG: there is no "data" in the web page.
  window.myApp.use(data)
}""")
```

> [!SUCCESS]
>
> 以下代码片段是**正确**的，因为它将值显式地作为参数传递

```python
data = "some data"
# Pass |data| as a parameter.
result = page.evaluate("""data => {
  window.myApp.use(data)
}""", data)
```

## 评估参数

Playwright 的评估方法（例如 [page.evaluate()](https://playwright.cn/python/docs/api/class-page#page-evaluate)）接受单个可选参数。此参数可以是 [可序列化](https://mdn.org.cn/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify#Description) 值和 [JSHandle](https://playwright.cn/python/docs/api/class-jshandle) 实例的组合。句柄会自动转换为它们所代表的值。

```python
# A primitive value.
page.evaluate('num => num', 42)

# An array.
page.evaluate('array => array.length', [1, 2, 3])

# An object.
page.evaluate('object => object.foo', { 'foo': 'bar' })

# A single handle.
button = page.evaluate_handle('window.button')
page.evaluate('button => button.textContent', button)

# Alternative notation using JSHandle.evaluate.
button.evaluate('(button, from) => button.textContent.substring(from)', 5)

# Object with multiple handles.
button1 = page.evaluate_handle('window.button1')
button2 = page.evaluate_handle('.button2')
page.evaluate("""o => o.button1.textContent + o.button2.textContent""",
    { 'button1': button1, 'button2': button2 })

# Object destructuring works. Note that property names must match
# between the destructured object and the argument.
# Also note the required parenthesis.
page.evaluate("""
    ({ button1, button2 }) => button1.textContent + button2.textContent""",
    { 'button1': button1, 'button2': button2 })

# Array works as well. Arbitrary names can be used for destructuring.
# Note the required parenthesis.
page.evaluate("""
    ([b1, b2]) => b1.textContent + b2.textContent""",
    [button1, button2])

# Any mix of serializables and handles works.
page.evaluate("""
    x => x.button1.textContent + x.list[0].textContent + String(x.foo)""",
    { 'button1': button1, 'list': [button2], 'foo': None })
```

## 初始化脚本

有时，在页面开始加载之前在页面中评估某些内容很方便。例如，您可能想要设置一些模拟数据或测试数据。

在这种情况下，请使用 [page.add_init_script()](https://playwright.cn/python/docs/api/class-page#page-add-init-script) 或 [browser_context.add_init_script()](https://playwright.cn/python/docs/api/class-browsercontext#browser-context-add-init-script)。在下面的示例中，我们将用常量值替换 `Math.random()`。

首先，创建一个包含模拟数据的 `preload.js` 文件。

```python
// preload.js
Math.random = () => 42;
```

接下来，将初始化脚本添加到页面。

```python
# In your test, assuming the "preload.js" file is in the "mocks" directory.
page.add_init_script(path="mocks/preload.js")
```

