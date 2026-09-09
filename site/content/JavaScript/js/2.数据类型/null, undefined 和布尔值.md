# null, undefined 和布尔值

## null 和 undefined

### 概述

`null`与`undefined`都可以表示“没有”，含义非常相似。将一个变量赋值为`undefined`或`null`，老实说，语法效果几乎没区别。

```javascript
var a = undefined;
// 或者
var a = null;
```

上面代码中，变量`a`分别被赋值为`undefined`和`null`，这两种写法的效果几乎等价。

在`if`语句中，它们都会被自动转为`false`，相等运算符（`==`）甚至直接报告两者相等。

```javascript
if (!undefined) {
  console.log('undefined is false');
}
// undefined is false
if (!null) {
  console.log('null is false');
}
// 空值和未定义的变量的类型都是object
console.log(typeof null); // object
console.log(typeof undefined); // undefined
console.log(null == undefined); // true
```

从上面代码可见，两者的行为是何等相似！谷歌公司开发的 JavaScript 语言的替代品 Dart 语言，就明确规定只有`null`，没有`undefined`！

既然含义与用法都差不多，为什么要同时设置两个这样的值，这不是无端增加复杂度，令初学者困扰吗？这与历史原因有关。

1995年 JavaScript 诞生时，最初像 Java 一样，只设置了`null`表示“无”。根据 C 语言的传统，`null`可以自动转为`0`。

```javascript
Number(null) // 0
5 + null // 5
```

上面代码中，`null`转为数字时，自动变成0。

但是，JavaScript 的设计者 Brendan Eich，觉得这样做还不够。首先，第一版的 JavaScript 里面，`null`就像在 Java 里一样，被当成一个对象，Brendan Eich 觉得表示“无”的值最好不是对象。其次，那时的 JavaScript 不包括错误处理机制，Brendan Eich 觉得，如果`null`自动转为0，很不容易发现错误。

因此，他又设计了一个`undefined`。区别是这样的：`null`是一个表示“空”的对象，转为数值时为`0`；`undefined`是一个表示“此处无定义”的原始值，转为数值时为`NaN`。

```javascript
Number(undefined) // NaN
5 + undefined // NaN
```

## NaN

`NaN`（Not a Number）就是：**本来应该算出一个数字，但算不出来时，JS 给你的 “无效数字” 结果**。

### 一、类型转换失败

把不能变成数字的东西转成数字：

```JS
Number('abc')        // NaN
Number('123abc')     // NaN
Number(undefined)     // NaN
parseInt('hello')     // NaN
parseFloat('你好')    // NaN
```

注意：`parseInt('123abc')` 会得到 `123`，**只有 “完全不能当数字” 才会 NaN**。

### 无意义的数学运算

#### 0 除以 0

```javascript
0 / 0        // NaN
```

**非 0 / 0 是 Infinity，不是 NaN**：

> Infinity（正无穷）/-Infinity（负无穷）
>
> - 数值太大 / 太小装不下，或者非 0 数除以 0
> - 显式赋值
> - Infinity 的运算
>
> **判断 Infinity**
>
> ```js
> // 正确
> Number.isFinite(Infinity)  // false
> Number.isFinite(123)       // true
>
> // 注意：typeof 还是 number
> typeof Infinity  // 'number'
>
> 5 / 0        // Infinity
> -5 / 0       // -Infinity
> ```

#### 负数开平方、对数负数

```javascript
Math.sqrt(-1)   // NaN
Math.log(-2)    // NaN
Math.acos(2)    // NaN（范围只能 -1~1）
```

#### 无穷大的 “不定式”

```javascript
Infinity - Infinity   // NaN
Infinity / Infinity   // NaN
0 * Infinity           // NaN
```

------

### 运算里混了不能转数字的值

`+ - * /` 时，某个操作数转不成数字：

```javascript
'abc' - 123      // NaN
'5' * 'abc'      // NaN
undefined + 1     // NaN
null * 'hello'    // NaN
```

小例外：`+` 遇到字符串会变成拼接，不会 NaN：

```javascript
'abc' + 123      // 'abc123'
```

### 只要有一个 NaN 参与运算，结果都是 NaN

NaN 具有传染性MDN Web Docs：

```javascript
NaN + 1        // NaN
NaN * 5        // NaN
7 / NaN        // NaN
```

------

### NaN 的怪特性（必考）

```javascript
typeof NaN          // 'number'   （它是数字类型）
NaN === NaN         // false      （自己不等于自己）
```

**判断 NaN 必须用：**

```javascript
Number.isNaN(x)
```

**凡是：转数字失败、数学无意义、操作数脏了、跟 NaN 算 → 结果都是 NaN。**

### 用法和含义

对于`null`和`undefined`，大致可以像下面这样理解。

`null`表示空值，即该处的值现在为空。调用函数时，某个参数未设置任何值，这时就可以传入`null`，表示该参数为空。比如，某个函数接受引擎抛出的错误作为参数，如果运行过程中未出错，那么这个参数就会传入`null`，表示未发生错误。

`undefined`表示“未定义”，下面是返回`undefined`的典型场景。

```javascript
// 变量声明了，但没有赋值
var i;
i // undefined

// 调用函数时，应该提供的参数没有提供，该参数等于 undefined
function f(x) {
  return x;
}
f() // undefined

// 对象没有赋值的属性
var  o = new Object();
o.p // undefined

// 函数没有返回值时，默认返回 undefined
function f() {}
f() // undefined
```

## 布尔值

布尔值代表“真”和“假”两个状态。“真”用关键字`true`表示，“假”用关键字`false`表示。布尔值只有这两个值。

下列运算符会返回布尔值：

- 前置逻辑运算符： `!` (Not)
- 相等运算符：`===`，`!==`，`==`，`!=`

- | 运算符 | 名称       | 规则                                     | 推荐度     |
  | :----- | :--------- | :--------------------------------------- | :--------- |
  | `===`  | 严格相等   | **值 + 类型 全都相等**，不做隐式类型转换 | ✅ 优先使用 |
  | `!==`  | 严格不相等 | **值 或 类型 有一个不同**，不做隐式转换  | ✅ 优先使用 |
  | `==`   | 松散相等   | 先**隐式类型转换**，再比较值             | ❌ 尽量少用 |
  | `!=`   | 松散不相等 | 先**隐式类型转换**，再比较值             | ❌ 尽量少用 |

-

  ```js
  console.log('---------------------------------------');
  console.log(1 === 1? "1 === 1":"1 !== 1");      // true 类型、值都相同
  console.log(1 === "1"? "1 === \"1\"":"1 !== \"1\"");    // false 类型不同（数字 vs 字符串）
  console.log(true === 1? "true === 1":"true !== 1");   // false 布尔 vs 数字
  console.log(1 == true? "1 == true":"1 !== true");      // true 类型不同（数字 vs 布尔）
  console.log(null === undefined? "null === undefined":"null !== undefined");   // false 类型不同
  console.log(null == undefined? "null == undefined":"null !== undefined");   // true 类型不同
  ```

- 比较运算符：`>`，`>=`，`<`，`<=`

如果 JavaScript 预期某个位置应该是布尔值，会将该位置上现有的值自动转为布尔值。转换规则是除了下面六个值被转为`false`，其他值都视为`true`。

下面六个值的表达式结果为  <font style="color:red; font-size:25px; font-weight:bold;">false</font>

- `undefined`
- `null`
- `false`
- `0`
- `NaN`
- `""`或`''`（空字符串）

布尔值往往用于程序流程的控制，请看一个例子。

```javascript
if ('') {
  console.log('true');
}
// 没有任何输出
```

上面代码中，`if`命令后面的判断条件，预期应该是一个布尔值，所以 JavaScript 自动将空字符串，转为布尔值`false`，导致程序不会进入代码块，所以没有任何输出。

注意，空数组（`[]`）和空对象（`{}`）对应的布尔值，都是`true`。

```javascript
if ([]) {
  console.log('true');
}
// true

if ({}) {
  console.log('true');
}
// true
```

更多关于数据类型转换的介绍，参见《数据类型转换》一章。

## 参考链接

- Axel Rauschmayer, [Categorizing values in JavaScript](http://www.2ality.com/2013/01/categorizing-values.html)
