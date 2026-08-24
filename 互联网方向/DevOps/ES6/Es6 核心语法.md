## ES6 核心语法

### 1. `let` / `const`

替代老的 `var`。

```js
let name = "Tom";
name = "Jack";

const age = 18;
// age = 20 // 报错
```

核心区别：

|            | `var` | `let`        | `const`      |
| ---------- | ----- | ------------ | ------------ |
| 块级作用域 | ❌     | ✅            | ✅            |
| 可重新赋值 | ✅     | ✅            | ❌            |
| 变量提升   | ✅     | 有暂时性死区 | 有暂时性死区 |
| 推荐使用   | ❌     | ✅            | ✅            |

实际开发：

```js
const user = {
  name: "Tom",
};

user.name = "Jack"; // ✅
```

`const` 限制的是 **变量绑定不能重新指向其他对象**，不是对象内部不能修改。

------

## 2. 箭头函数 `=>`

```js
const add = (a, b) => {
  return a + b;
};
```

简写：

```js
const add = (a, b) => a + b;
```

一个参数可以省略括号：

```js
const double = (x) => x * 2;
```

### 最大重点：`this`

箭头函数 **没有自己的 `this`**。

```js
const obj = {
  name: "Tom",

  say() {
    const fn = () => {
      console.log(this.name);
    };
    fn();
  },
};
```

这里箭头函数继承 `say()` 的 `this`。

这也是 Vue、Promise、回调函数里非常常见的东西。

------

## 3. 模板字符串

以前：

```js
const message = "你好，" + name + "，今年" + age + "岁";
```

ES6：

```js
const message = `你好，${name}，今年${age}岁`;
```

还能写表达式：

```js
const result = `结果：${a + b}`;
```

多行字符串：

```js
const html = `
  <div>
    <span>Hello</span>
  </div>
`;
```

------

## 4. 解构赋值

这是现代 JavaScript **极高频** 语法。

### 对象解构

```js
const user = {
  name: "Tom",
  age: 18,
};

const { name, age } = user;
```

相当于：

```js
const name = user.name;
const age = user.age;
```

改变量名：

```js
const { name: userName } = user;

console.log(userName);
```

默认值：

```js
const { name, age = 18 } = user;
```

------

### 数组解构

```js
const arr = [10, 20, 30];

const [a, b, c] = arr;
```

跳过元素：

```js
const [a, , c] = arr;
```

交换变量：

```js
let a = 10;
let b = ((20)[(a, b)] = [b, a]);
```

这个在算法和前端代码里都很常见。

------

## 5. 默认参数

```js
function createUser(name = "Tom") {
  console.log(name);
}

createUser();
```

也可以：

```js
function request(url, method = "GET") {
  // ...
}
```

------

## 6. Rest 参数 `...`

把多个参数收集成数组：

```js
function sum(...numbers) {
  return numbers.reduce((a, b) => a + b, 0);
}

sum(1, 2, 3, 4);
```

这里：

```js
...numbers
```

得到：

```js
[1, 2, 3, 4];
```

------

## 7. Spread 展开运算符 `...`

和 Rest 长得一样，但用途相反。

### 数组展开

```js
const a = [1, 2];
const b = [3, 4];

const c = [...a, ...b];
```

结果：

```js
[1, 2, 3, 4];
```

复制数组：

```js
const copy = [...arr];
```

------

### 对象展开

```js
const user = {
  name: "Tom",
  age: 18,
};

const newUser = {
  ...user,
  age: 20,
};
```

结果：

```js
{
  name: 'Tom',
  age: 20
}
```

Vue / React 开发里非常高频。

------

## 8. 对象简写

以前：

```js
const name = "Tom";
const age = 18;

const user = {
  name: name,
  age: age,
};
```

ES6：

```js
const user = {
  name,
  age,
};
```

方法也可以简写：

```js
const user = {
  say() {
    console.log("Hello");
  },
};
```

------

## 9. `for...of`

遍历数组等 **可迭代对象**：

```js
const arr = [10, 20, 30];

for (const item of arr) {
  console.log(item);
}
```

和：

```js
for (const index in arr)
```

不要混淆。

### `for...in`

遍历键：

```js
for (const key in user) {
  console.log(key);
}
```

#### `for...of`

遍历值：

```js
for (const value of arr) {
  console.log(value);
}
```

记忆：

```text
in  → key
of  → value
```

------

## 10. `class`

ES6 引入了更接近传统面向对象写法的 `class`。

```js
class Person {
  constructor(name) {
    this.name = name;
  }

  sayHello() {
    console.log(`Hello ${this.name}`);
  }
}

const person = new Person("Tom");

person.sayHello();
```

继承：

```js
class Student extends Person {
  constructor(name, score) {
    super(name);
    this.score = score;
  }
}
```

------

## 11. 模块 `import / export`

现代前端最重要的 ES6 特性之一。

### 导出

```js
export const name = "Tom";

export function add(a, b) {
  return a + b;
}
```

或者：

```js
export default function add(a, b) {
  return a + b;
}
```

### 导入

```js
import { name, add } from "./utils.js";
```

默认导入：

```js
import add from "./utils.js";
```

全部导入：

```js
import * as utils from "./utils.js";
```

Vue3 项目里你每天都在用它。

------

## 12. Promise

ES6 非常重要的异步基础。

```js
const promise = new Promise((resolve, reject) => {
  setTimeout(() => {
    resolve("成功");
  }, 1000);
});

promise.then((result) => {
  console.log(result);
});
```

失败：

```js
promise
  .then((result) => {
    console.log(result);
  })
  .catch((error) => {
    console.error(error);
  });
```

不过现代开发通常进一步使用：

```js
async function getUser() {
  try {
    const result = await request();
    console.log(result);
  } catch (error) {
    console.error(error);
  }
}
```

`async/await` 本身是在 ES2017 引入的，不属于严格意义上的 ES6，但学习 ES6 异步时最好一起掌握。

------

## 13. `Map`

传统对象：

```js
const user = {
  name: "Tom",
};
```

`Map`：

```js
const map = new Map();

map.set("name", "Tom");
map.set("age", 18);

console.log(map.get("name"));
```

判断：

```js
map.has("name");
```

删除：

```js
map.delete("name");
```

遍历：

```js
for (const [key, value] of map) {
  console.log(key, value);
}
```

------

## 14. `Set`

自动去重。

```js
const set = new Set([1, 2, 2, 3, 3]);

console.log(set);
```

转数组：

```js
const arr = [...new Set([1, 2, 2, 3])];
```

结果：

```js
[1, 2, 3];
```

前端处理数组去重时非常方便。

------

## 15. `Symbol`

创建唯一标识：

```js
const id = Symbol("id");

const user = {
  [id]: 123,
};
```

即使：

```js
Symbol("id") === Symbol("id");
```

结果也是：

```js
false;
```

日常业务开发频率不如前面的语法高，但理解 JavaScript 的对象属性机制时有用。

------

## 16. `Proxy`

这个对 **Vue3** 特别重要。

```js
const user = {
  name: "Tom",
};

const proxy = new Proxy(user, {
  get(target, property) {
    console.log("读取:", property);
    return target[property];
  },

  set(target, property, value) {
    console.log("修改:", property, value);
    target[property] = value;
    return true;
  },
});
```

Vue3 的响应式系统核心就是基于：

```text
Proxy
 +
依赖追踪
 +
触发更新
```

所以如果你学 Vue3，`Proxy` 值得认真理解。

------

## 17. `Symbol.iterator` / Iterator

这个属于稍微深入一点的 ES6。

例如：

```js
const arr = [1, 2, 3];

const iterator = arr[Symbol.iterator]();

iterator.next();
```

得到：

```js
{
  value: 1,
  done: false
}
```

这套机制就是：

```text
for...of
   ↓
Iterator
   ↓
Symbol.iterator
```

一般业务开发不需要手写 Iterator，但理解它有助于理解 JS 的迭代机制。

------

## 18. Generator

语法：

```js
function* generator() {
  yield 1;
  yield 2;
  yield 3;
}

const g = generator();

console.log(g.next());
console.log(g.next());
```

结果依次：

```js
{ value: 1, done: false }
{ value: 2, done: false }
```

Generator 在现代前端业务代码中的使用频率已经明显低于 Promise / async-await。
