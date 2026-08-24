# RESTful + Swagger + Mock：一条线搞定接口开发

## 这三个东西其实是一条线，别拆开学

> [!quote]
> **RESTful = 怎么设计接口**
> **Swagger = 怎么描述和测试接口**
> **Mock = 后端没写好时，怎么伪造接口**

你以后写 [[Vue3]] + [[Spring Boot]]，基本每天都会碰到这三个。真正掌握它们，不需要学一堆理论，做一个用户管理 API 就够了。接口世界已经够复杂，没必要再人为制造复杂。

> [!tip]
>
> 记忆口诀
> **RESTful 定规则，Swagger 看规则，Mock 假装实现规则。**

## 整体认知：它们在一条流水线上

![image-20260820115632228](./assets/image-20260820115632228.png)

三者不是三个知识点，而是同一件事的三个阶段。一句话概括：**先用 RESTful 定契约 → 用 Swagger 把契约变成可浏览文档 → 用 Mock 在后端没好时先假装实现契约**。

```mermaid
flowchart LR
    A[需求: 用户管理] --> B[RESTful 设计接口契约]
    B --> C[Swagger / Knife4j 文档先行]
    B --> D[Mock 返回假数据]
    C --> E[前端按文档开发]
    D --> E
    E --> F[后端实现 Controller / Service]
    F --> G[联调 + 接口测试]
    G --> H[关闭 Mock 切真实接口]
```

> [!note]
>
> 测试工程师视角
> 这条流水线上，**测试可以比后端更早动手**：契约（RESTful）一定，你就可以用 Mock 造数据、写接口测试用例、在 Swagger 上验契约了。等后端一完成，直接跑用例即可，不用等。

---

## 第一部分：RESTful

REST 是一种 API 设计风格，核心思想是 **围绕资源（Resource）来设计接口**。HTTP 方法表示你要对资源做什么，URL 表示资源是谁。REST 是架构约束集合，不是某个框架。

### URL 看资源，不看动作

比如用户资源用 `/users` 表示，**不要** 写成 `/getUser`、`/addUser`、`/deleteUser`、`/updateUser`。

| 功能         | 错误写法              | RESTful              |
| ------------ | --------------------- | -------------------- |
| 查询用户列表 | `GET /getUser`        | `GET /users`         |
| 查询一个用户 | `GET /getUser?id=1`   | `GET /users/1`       |
| 新增用户     | `POST /addUser`       | `POST /users`        |
| 修改用户     | `POST /updateUser`    | `PUT /users/1`       |
| 删除用户     | `POST /deleteUser?id=1` | `DELETE /users/1`  |

HTTP 方法本身已经表达了动作，URL 只表达资源。这是 RESTful 最重要的思想。

### CRUD 对应关系

![image-20260820115725558](./assets/image-20260820115725558.png)

这是你以后写接口时最常见的一套。

### GET / POST / PUT / DELETE 一眼理解

| 方法   | 作用         | 是否带 Body | 幂等 |
| ------ | ------------ | ----------- | ---- |
| GET    | 查询         | 一般没有    | 是   |
| POST   | 新增         | 有          | 否   |
| PUT    | 整体替换资源 | 有          | 是   |
| PATCH  | 修改部分字段 | 有          | 否   |
| DELETE | 删除         | 一般没有    | 是   |

> [!important]
>
> 幂等是什么
> 幂等 = 同一请求发一次和发 N 次，结果一样。`GET`/`PUT`/`DELETE` 幂等，`POST` 不幂等（发两次会建两条）。**测试时要重点验证 PUT/DELETE 重复调用的安全性**——这是很多 bug 来源。

### PUT 和 PATCH 别混

假设用户：

```json
{ "id": 1, "name": "张三", "age": 18 }
```

**PUT**（整体替换，缺的字段会被清空）：

```json
{ "name": "李四", "age": 20 }
```

**PATCH**（只改传的字段，其余保留）：

```json
{ "age": 20 }
```

> [!warning]
>
> 企业里常见坑
> 很多后端把 "修改" 只实现了 PUT，前端传全量对象没问题；一旦前端用 PATCH 只传部分字段，后端直接报错或覆盖失败。**接口文档里必须写清：改全量用 PUT 还是 PATCH，字段缺省时是忽略还是清空。**

### HTTP 状态码速查（必须背熟）

RESTful 不只看 URL，还看状态码。前端/测试靠状态码判断成败：

| 状态码 | 含义           | 典型场景                   |
| ------ | -------------- | -------------------------- |
| 200    | OK             | 查询、修改、删除成功       |
| 201    | Created        | 新增成功（资源已创建）     |
| 204    | No Content     | 删除成功（无返回体）       |
| 400    | Bad Request    | 参数校验失败               |
| 401    | Unauthorized   | 未登录 / Token 失效        |
| 403    | Forbidden      | 已登录但无权限             |
| 404    | Not Found      | 资源不存在 / 路径拼错      |
| 409    | Conflict       | 新增时唯一键冲突（如用户名重复）|
| 500    | Server Error   | 后端代码异常               |

> [!tip]
>
> 测试口诀
> **2xx 看数据，4xx 看参数和权限，5xx 看后端日志。** 接口测试里 4xx/5xx 的占比往往比 2xx 更能暴露问题。

### 常见反模式（设计评审时直接打回）

- ❌ 用 GET 传密码、用 POST 做删除（`GET /deleteUser?id=1`）
- ❌ URL 里带动词：`/getUserList`、`/createOrder`
- ❌ 用错方法：删除用 POST、查询用 POST
- ❌ 状态码永远返回 200，错误信息塞在 body 里（前端难判断、测试难断言）
- ❌ 单复数混乱：`/user/1` 和 `/users` 混用（**复数资源名统一 `/users`**）

---

## 第二部分：Swagger

> [!note]
>
> 准确叫法
> 现在更该叫 **OpenAPI + Swagger 工具**。OpenAPI 是 API 描述规范，Swagger 是围绕它的一套工具（Swagger UI、Editor）。Spring Boot 项目里现在主流是 **springdoc-openapi**，国内 [[RuoYi]] 默认集成 **Knife4j**（Swagger UI 的增强版，中文更友好）。

简单理解这条线：

```text
Spring Boot Controller
        │
        ▼
OpenAPI 文档（自动生成）
        │
        ▼
Swagger UI / Knife4j（可浏览 + 可调试）
```

它自动生成接口文档，不用手写 Word。

### Swagger / Knife4j 页面长什么样

里面会显示：

- 接口地址、请求方式
- 入参（Path / Query / Body）及类型
- 返回值 JSON 示例
- **Try it out** 在线调试按钮

> 一句话：**前端不用问后端 "接口怎么调"，直接看 Swagger。**

### Spring Boot 中最小的例子

```java
@RestController
@RequestMapping("/users")
@Tag(name = "用户管理")                 // Swagger 分组名
public class UserController {
    @GetMapping("/{id}")
    @Operation(summary = "根据 ID 查询用户")   // Swagger 接口说明
    public User getUser(@PathVariable Long id) {
        return new User(id, "张三", 18);
    }
}
```

启动后，Swagger 自动生成 `GET /users/{id}` 的文档。前端打开就知道：请求 `GET /users/1`，返回：

```json
{ "id": 1, "name": "张三", "age": 18 }
```

### Swagger 里配鉴权（企业必做）

真实项目几乎都有 Token。在 Knife4j / Swagger 配置里声明全局鉴权头后，页面上点一下 **Authorize** 填 Token，所有接口调试自动带上：

```java
@Bean
public OpenAPI openAPI() {
    return new OpenAPI().components(new Components().addSecuritySchemes(
        "Authorization",
        new SecurityScheme().type(SecurityScheme.Type.HTTP)
                            .scheme("bearer").bearerFormat("JWT")));
}
```

> [!warning] 测试点
> 配了鉴权后，**一定要测 "不带 Token 调接口" 是否返回 401**。很多项目只测了正常路径，没测未授权路径，等于没锁门。

### 测试工程师怎么用 Swagger

Swagger 不只是一个文档，它是 **手边最快的接口测试工具**：

1. 用 **Try it out** 直接发请求，省去开 Postman 建请求。
2. 看自动生成的 JSON 示例，核对字段名 / 类型是否与需求一致。
3. 故意填错参数类型，看是否返回 400 和清晰错误。
4. 把 Swagger 当 "契约基准"——后端改了字段而不改文档，一眼就能发现 drift（文档与实现不一致）。

---

## 第三部分：Mock

Mock 最容易理解。假设前端完成 80%，后端完成 20%：

> Mock = **假的接口，返回真的格式。**

例如真实接口未来应返回：

```json
{
  "code": 200,
  "msg": "success",
  "data": { "id": 1, "name": "张三" }
}
```

后端还没写。Mock 直接返回：

```json
{
  "code": 200,
  "msg": "success",
  "data": { "id": 1001, "name": "李四" }
}
```

前端照样开发。

### Mock.js 工作方式

Mock.js 核心是 **拦截 Ajax 请求** 返回模拟数据，还能生成随机姓名、日期、邮箱等：

```javascript
Mock.mock("/api/users", "get", {
  code: 200,
  msg: "success",
  "data|5": [
    {
      id: "@id",
      name: "@cname",
      age: "@integer(18,40)",
    },
  ],
});
```

访问 `GET /api/users` 得到 5 条随机用户。

### 现代项目更常用 MSW

[[Vue3]] / React / Vite 项目里越来越常见 **MSW（Mock Service Worker）**。它不改 axios，而是在 **网络层拦截请求**：

```mermaid
flowchart LR
    A[axios GET /api/users] --> B[MSW 拦截]
    B --> C[返回模拟 JSON]
```

MSW 官方定位就是 "浏览器和 Node.js 的 API Mock 库"，**同一套 Mock 可复用于开发 + 测试环境**（Vitest 单测里也能用）。

```javascript
// src/mocks/handlers.js
import { http, HttpResponse } from "msw";
export const handlers = [
  http.get("/api/users", () =>
    HttpResponse.json({
      code: 200,
      data: [
        { id: 1, name: "张三" },
        { id: 2, name: "李四" },
      ],
    }),
  ),
];
```

| 工具    | 定位                          | 适合场景                     |
| ------- | ----------------------------- | ---------------------------- |
| Mock.js | 随机数据、Ajax 拦截           | 快速原型、老项目             |
| MSW     | 网络层 API Mock，更现代       | Vue3/React 新项目、单测复用  |

> [!tip]
> 学 [[Vue3]] 建议优先认识 MSW，再回头了解 Mock.js。

### Mock 与真实接口的切换（关键）

Mock 的最大价值：**等后端完成，只关掉 Mock，axios 一行不用改。**

```javascript
// 用一个环境变量控制，不要硬编码删 mock
const USE_MOCK = import.meta.env.VITE_USE_MOCK === "true";
if (USE_MOCK) enableMock(); // 开发期 true，联调期 false
```

> [!warning]
>
> 别踩的坑
> 真实项目常见事故：**联调时忘了关 Mock，前端调的是假数据，以为后端好了，一上线全崩。** 切换开关一定要走环境变量，且在上线 checklist 里加一条 "确认 `VITE_USE_MOCK=false`"。

### 测试怎么用 Mock

- **前端自测**：Mock 造正常 / 异常 / 边界数据（空列表、超大分页、错误码），不依赖后端。
- **构造难复现场景**：401/403/500 这类后端不好造的状态，Mock 一行返回，专门测前端错误提示。
- **接口测试初始化**：用 Mock 固定依赖服务的返回，让被测接口稳定可测（测试替身）。

---

## 循序渐进案例推进：用户管理模块

下面用一条主线，把三者串成 **可照做的分阶段流程**。每阶段给出：目标 → 关键产物 → 测试怎么验。

```mermaid
flowchart TD
    S0[阶段0 需求拆解] --> S1[阶段1 设计RESTful契约]
    S1 --> S2[阶段2 Swagger接入]
    S2 --> S3[阶段3 Mock先行]
    S3 --> S4[阶段4 后端实现]
    S4 --> S5[阶段5 联调+接口测试]
    S5 --> S6[阶段6 进阶:统一响应/鉴权/分页]
```

### 阶段 0：需求拆解

> 目标：搞清楚 "用户管理" 要哪些能力。

需求：用户能注册、登录、查列表、查详情、改信息、删账号。

产出一份 **功能清单**（先别写代码）：

| 功能     | 是否需要鉴权 | 备注             |
| -------- | ------------ | ---------------- |
| 注册     | 否           | 用户名唯一       |
| 登录     | 否           | 返回 Token       |
| 用户列表 | 是           | 支持分页、搜索   |
| 用户详情 | 是           | 只能看自己的/管理员|
| 修改     | 是           | 自己的资料       |
| 删除     | 是           | 管理员才行       |

> [!note] 
>
> 测试前置
> 契约没定之前，测试就可以根据这张表 **先写接口测试用例大纲**（正常流 + 异常流 + 权限流），不必等代码。

### 阶段 1：设计 RESTful 接口契约（先定规则）

> 目标：把需求翻译成 URL + 方法 + 字段，这是三人共同的 "契约"。

| 请求   | 地址             | 功能     | 鉴权 |
| ------ | ---------------- | -------- | ---- |
| POST   | `/api/users`     | 注册     | 否   |
| POST   | `/api/login`     | 登录     | 否   |
| GET    | `/api/users`     | 用户列表 | 是   |
| GET    | `/api/users/{id}`| 用户详情 | 是   |
| PUT    | `/api/users/{id}`| 修改     | 是   |
| DELETE | `/api/users/{id}`| 删除     | 是   |

统一响应体（全公司共用，详见进阶章节）：

```json
{ "code": 200, "msg": "success", "data": {} }
```

> [!tip] 
>
> 契约即文档
> 这张表 + 统一响应体，就是 Swagger 之后要渲染的内容，也是 Mock 要返回的格式。**先有契约，后面三步才不会各写各的。**

### 阶段 2：Swagger 接入，文档先行

> 目标：后端把契约变成可浏览、可调试的页面。

Spring Boot 里加注解：

```java
@RestController
@RequestMapping("/api/users")
@Tag(name = "用户管理")
public class UserController {

    @GetMapping
    @Operation(summary = "用户列表（分页）")
    public Result<Page<User>> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size) {
        return Result.success(userService.page(page, size));
    }

    @PostMapping
    @Operation(summary = "注册用户")
    public Result<Long> create(@RequestBody @Valid UserDTO dto) {
        return Result.success(userService.create(dto));
    }
}
```

打开 Knife4j 页面，能看到：每个接口的方法、参数、返回值 JSON、Try it out。

> [!check] 
>
> 测试怎么验（阶段 2）
> 此时后端逻辑可能还是空壳，但 **契约已可见**。测试在 Swagger 上核对：字段名/类型是否和需求一致？缺参时 Swagger 是否标了 required？文档与需求有 drift 立即打回。

### 阶段 3：Mock 先行，前端和测试不阻塞

> 目标：后端没写数据库前，前端照常开发，测试照常造数据。

MSW 按契约返回：

```javascript
// mock/user.js —— 完全对齐阶段1契约
http.post("/api/users", () =>
  HttpResponse.json({ code: 200, msg: "success", data: 1001 }, { status: 201 }),
);

http.get("/api/users", () =>
  HttpResponse.json({
    code: 200,
    msg: "success",
    data: { list: [{ id: 1, name: "张三" }], total: 1 },
  }),
);

// 故意造一个异常场景给前端测错误提示
http.post("/api/login", () =>
  HttpResponse.json({ code: 401, msg: "用户名或密码错误" }, { status: 401 }),
);
```

前端继续写页面，测试继续写用例，**谁都不用等后端**。

> [!check]
>
> 测试怎么验（阶段 3）
> 用 Mock 跑通 "正常 + 异常 + 边界" 三类用例。比如登录失败返回 401 时，前端是否弹 "用户名或密码错误"、是否清掉无效 Token。**这些都不需要真实后端。**

### 阶段 4：后端实现 + 接数据库

> 目标：把空壳 Controller 填上 Service / Mapper 真实逻辑。

```java
@Service
public class UserService {
    public Long create(UserDTO dto) {
        if (userMapper.existsByUsername(dto.getUsername()))
            throw new BizException(409, "用户名已存在");
        User u = new User();
        BeanUtils.copyProperties(dto, u);
        userMapper.insert(u);
        return u.getId();
    }
}
```

此时真实接口开始返回真实数据。

> [!warning] 
>
> 测试关注点
> 后端实现后，**契约不能被偷偷改**——比如把 `/api/users` 改成 `/api/user/list`。一旦改了，Mock 和前端全失效。所以每次后端提测，测试第一件事是 **拿 Swagger 和阶段 1 契约对一遍**。

### 阶段 5：前后端联调 + 接口测试验证

> 目标：关掉 Mock，跑真实链路，执行完整用例。

```javascript
const USE_MOCK = import.meta.env.VITE_USE_MOCK === "true";
if (!USE_MOCK) disableMock(); // 联调期：关 Mock
```

联调时序：

```mermaid
sequenceDiagram
    participant FE as 前端 / 测试
    participant MW as Mock(已关)
    participant BE as 后端 API
    FE->>BE: GET /api/users (带 Token)
    BE-->>FE: 200 + 真实分页数据
```

> [!check] 测试怎么验（阶段 5）
> 执行阶段 0 写的用例大纲：
>
> - **正常流**：注册 → 登录拿 Token→ 带 Token 查列表/详情 → 改 → 删，全 2xx。
> - **异常流**：参数缺/错类型 →400；错账号登录 →401；删别人 →403；查不存在 →404；重复注册 →409。
> - **权限流**：普通用户访问管理员接口 →403。
> 每条用例断言 **状态码 + 响应体字段 + 错误文案**，而不是只看 "通了"。

### 阶段 6：进阶（统一响应 / 鉴权 / 分页 / 校验）

企业项目到这里才完整。逐个补齐：

1. **统一响应体**;
2. **鉴权**：登录返回 JWT，后续请求 `Authorization: Bearer <token>`;
3. **分页**：`/api/users?page=1&size=10`，返回 `{ list, total, page, size }`;
4. **字段校验**：`@Valid` + 注解（`@NotBlank`、`@Email`），校验失败统一返回 400;
5. **错误码表**：业务异常用 `code`（如 409/1001）区分，前端按 code 做提示.

> [!tip] 
>
> 到这里你收获了什么 
> 一个模块从需求 → 契约 → 文档 →Mock→ 实现 → 联调 → 测试的全流程都走通了。**换任何模块（订单、商品、权限）都是这套模板**，只是 URL 和资源名不同。 

---

## 企业项目进阶：必须统一的几件事

### 统一响应体规范

全公司接口返回同一个结构，前端/测试才好写通用断言：

```json
{
  "code": 200, // 业务码：200 成功；非 200 见错误码表
  "msg": "success", // 人类可读提示
  "data": {} // 业务数据，失败时为 null
}
```

> [!warning] 
>
> 反例
> 有的项目把 "失败" 也用 HTTP 200 + `code:500` 表达。这会让测试无法用状态码断言，**强烈建议：HTTP 状态码表达传输层结果，业务 code 表达业务结果，二者分开。**

### HTTP 状态码 vs 业务 code

| 维度     | 表达什么           | 例子                    |
| -------- | ------------------ | ----------------------- |
| 状态码   | 这次请求成没成     | 401 没登录、500 崩了    |
| 业务 code| 业务处理结果       | 1001 用户名重复、1002 余额不足 |

### 鉴权（JWT / Token）

登录拿 Token，后续所有请求带：

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

> [!check] 测试必测四项
>
> 1. 没带 Token → 401
> 2. Token 过期/伪造 → 401
> 3. 有权限的用户访问受限资源 → 200
> 4. 无权限的用户访问 → 403（不是 401！）

### 分页与过滤

```http
GET /api/users?page=1&size=10&keyword=张
```

返回：

```json
{
  "code": 200,
  "data": {
    "list": [
      ...
    ],
    "total": 58,
    "page": 1,
    "size": 10
  }
}
```

> [!tip] 
>
> 分页测试点
> 测 `page` 越界、 `size` 超大、 `keyword` 为空、结果为 0 条时页面是否正常渲染空状态。

### 字段校验与错误返回

```java
public class UserDTO {
    @NotBlank(message = "用户名不能为空")
    private String username;
    @Email(message = "邮箱格式错误")
    private String email;
}
```

校验失败返回：

```json
{ "code": 400, "msg": "用户名不能为空", "data": null }
```

> [!check] 测试点
> 逐个字段放空 / 放错格式，确认都返回 400 且 msg 准确，而不是默默存了脏数据。

### RuoYi 实际目录结构

你以后在 [[RuoYi]] 里基本就是这种结构：

```text
后端
├── controller/UserController.java   ← RESTful 入口
├── service/UserService.java
├── mapper/UserMapper.java
└── domain/User.java
Swagger/Knife4j  ← 自动扫描 Controller

前端
├── api/user.js          ← 调接口（axios）
├── views/user/index.vue  ← 页面
└── mock/user.js         ← 开发期 Mock
```

目录职责非常清晰：**后端管契约实现，前端管调用与展示，Mock 是开发期的替身。**

---

## 测试工程师检查清单（三维度）

每次接口提测，照这张表过一遍：

### RESTful 维度

- [ ] URL 是资源名词复数（`/users`），无动词
- [ ] 方法语义正确（GET 查 / POST 增 / PUT 改 / DELETE 删）
- [ ] PUT 幂等、POST 不幂等行为符合预期
- [ ] 状态码使用规范（成功 2xx，参数错 400，未授权 401，无权限 403，不存在 404）

### Swagger / Knife4j 维度

- [ ] 所有接口有 summary、参数有说明
- [ ] required 字段标注正确
- [ ] 返回值示例与实际一致（无 drift）
- [ ] 鉴权入口可填 Token，Try it out 能调通正常流

### Mock 维度

- [ ] Mock 数据格式与契约一致
- [ ] 能构造正常 / 异常 / 边界三类数据
- [ ] 联调前确认 `VITE_USE_MOCK=false`，未误用假数据
- [ ] Mock 在单测/前端自测中被复用，不是一次性脚本

---

## 30 分钟快速学习路线

> [!tip] 
>
> 分段学，别一口气
>
> ### 第 1 阶段：10 分钟
>
> 只理解 RESTful，记住 CRUD 表（GET 查 / POST 增 / PUT 改 / DELETE 删）。
>
> ### 第 2 阶段：10 分钟
>
> 学会看 Swagger：接口地址、请求参数、返回 JSON、Try it out 四件事。
>
> ### 第 3 阶段：10 分钟
>
> 理解 Mock 一句话：**后端没完成，用 Mock 返回假的 JSON，让前端/测试继续。**
>
> 30 分钟后你已经能看懂绝大多数企业项目接口。

---

## 最后必须记住的三个概念

> [!quote] 口诀
> **RESTful 设计接口，Swagger 查看接口，Mock 模拟接口。**

这三个掌握后，你就可以顺着学：[[Spring Boot]] Controller → Knife4j/Swagger → [[Vue3]] + Axios → Mock(MSW) → 前后端联调 → 接口自动化测试。这基本就是 [[RuoYi]]、Vue3 企业项目最常见的一条开发+测试路线。
