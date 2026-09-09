# Fiddler

> [!info] 笔记说明
> 2026-08-31 由两篇笔记（CSDN 教程 + 博客园教程）合并为单一信息源：重叠内容取详细版，独有内容全保留。
> 相关笔记：[[Web协议和测试]]、[[移动APP测试]]、[[练习计划]]

## 一、Fiddler 是什么

Fiddler 是一个 HTTP(S) 协议调试代理工具，能记录所有客户端和服务器之间的 http/https 请求，允许监视、设置断点，查看所有"进出" Fiddler 的数据（cookie、HTML、js、CSS 等文件）。它以用户友好的格式暴露 http 通讯，比其他网络调试器更简单。

### 我用 Fiddler 做什么

- **接口测试**：发送自定义请求，模拟小型接口测试
- **定位前后端 bug**：抓取协议包，进行前后端联调
- **弱网测试**：模拟限速、断网
- **构建模拟测试场景**：数据篡改、重定向
- **前端性能分析及优化**

## 二、工作原理

Fiddler 以**代理 Web 服务器**的形式工作：本地应用与服务器之间所有的请求（request）和响应（response）都由 Fiddler 转发——接收客户端请求 → 处理后发给服务器 → 服务器返回结果给 Fiddler → 再返回给客户端。代理地址 `127.0.0.1`，默认端口 `8888`。因为所有网络数据都要经过 Fiddler，所以它能截取数据、实现抓包。

![工作原理](assets/14c349f796f4eef4e9fddbfc7f394ba4.png)

![工作原理-代理转发](../assets/1897069-20220304010500134-1503332004.png)

> [!warning]
>
> 常见坑
> Fiddler 开启状态下电脑意外重启/关机，重启后无法正常上网——直接重启 Fiddler 即可恢复。

## 三、下载与安装

- 官网下载：<https://www.telerik.com/fiddler>
- Fiddler 4 直达：<https://www.telerik.com/download/fiddler/fiddler4>

![下载页](assets/bb92b99c1bb9af306426dccd7d0cf31f.png)

安装步骤：双击安装包 → I Agree → 选择安装路径 → Install → Close。

![双击安装包](assets/502214cc028d1d59c4ce178765e3454c.png)

![I Agree](assets/88cabcc4c6314c2fa0cdc94ba85f9990.png)

![安装路径](assets/9dadaca9c0a94af2d6340a3670940f0d.png)

![Close](assets/02590e9f480d2d006c91784f06e6c831.png)

打开方式：

- 方式一：到安装目录找到 Fiddler.exe 双击打开
- 方式二：把 Fiddler.exe 发送到桌面快捷方式再打开

![启动界面](../assets/1897069-20220208143608248-773051015.png)

## 四、初始配置（Tools → Options）

鼠标选中 Tools → Options：

![Tools-Options](../assets/1897069-20220208143629462-581112547.png)

### 1. Connections（抓 APP 包必设）

1. 默认监听端口：8888
2. 勾选 **Allow remote computers to connect**——允许远程连接（别的机器把 HTTP/HTTPS 请求发到 Fiddler 上来）

![Connections 设置](../assets/1897069-20220208143638224-1132102904.png)

### 2. HTTPS（抓 HTTPS 包必设）

HTTPS 标签页中勾选 **Decrypt HTTPS traffic**，弹出的证书及安全提示均点击同意。配置完成后重启 Fiddler 即可正常抓包。

![HTTPS Decrypt](../assets/1897069-20220304010607763-1895885513.png)

![HTTPS 设置步骤1](assets/8c57315d850c08676ddeee64e0db8de8.png)

![HTTPS 设置步骤2](assets/f00ac237b0274fb671b22a324aeb2631.png)

![HTTPS 设置步骤3](assets/69d4d7ce5082f92cebb7e108f6ab28ad.png)

![HTTPS 设置步骤4](assets/ab9fd435d939420b9bfbea3784167f54.png)

![HTTPS 设置步骤5](assets/d6322f52fd953c83505163dcfd9ec395.png)

![HTTPS 设置步骤6](assets/83e9200a94f862fd4d25059509a6c554.png)

![HTTPS 设置步骤7](assets/31ac01d64393f29046d0e09c43d658c8.png)

## 五、界面与基础操作

### 1. 菜单栏

Fiddler 默认不显示菜单栏，可手动调出：

![显示菜单栏](assets/20d02f80f54f8f1588afda8ed95dd8fb.png)

![菜单栏功能介绍](assets/d2714730dff006b5acb2e7d163c5f3c1.png)

### 2. 工具栏功能概要

![工具功能概要](../assets/1897069-20220304010621160-27449125.png)

### 3. 导包

File → Load Archive 可导入 .saz 会话文件：

![导包](assets/845e0a5d57555c720ab87c809670a7a3.png)

### 4. 清除会话列表

- 命令行输入 `clear`
- 快捷键 `Ctrl+X`

![清除会话](../assets/1897069-20220304010636944-1518155331.png)

### 5. 请求与响应面板

![请求与响应](../assets/1897069-20220304010721221-396502093.png)

1. Request 是客户端发出去的数据，Response 是服务端返回的数据，两块区域功能差不多
2. **headers**：请求头，包含 client、cookies、transport 等
3. **webforms**：请求参数表格化展示，更直观，可以直接修改该区域的参数
4. **Auth**：授权相关。显示 "No Proxy-Authorization Header is present / No Authorization Header is present" 两行说明不需要授权，不用关注（现在很少见）
5. **cookies**：查看 cookie 详情
6. **raw**：查看完整请求内容，可直接复制
7. **json**：查看 json 数据
8. **xml**：查看 xml 文件信息

### 6. decode 解码

1. 如果 response 的 TextView 区域出现乱码，直接点下方黄色区域解码：

![decode-1](../assets/614655-20170901220931983-1395846660.png)

1. 也可以选中上方快捷菜单 decode，之后所有请求都会自动解码：

![decode-2](../assets/614655-20170901221015233-868710583.png)

### 7. 图标与区域解释

![解释1](../assets/1897069-20220304010738080-1800420742.png)

![解释2](../assets/1897069-20220304010746075-289478387.png)

![解释3](../assets/1897069-20220304010756323-306104058.png)

## 六、过滤请求

### 1. Filters 过滤器

![过滤器1](assets/ea0419aeb7e4c2627cd3007a1984acc9.png)

![过滤器2](assets/91cddbd831a4f62aa1b0229d2ea490c8.png)

![过滤器3](assets/700bc4c0dd19f7e54213b5908de56f93.png)

### 2. 按 hosts 过滤

只查看填写的 host 请求；需要过滤多个时用 `;` 分割。

![hosts过滤1](../assets/1897069-20220304010647022-1607133256.png)

![hosts过滤2](../assets/1897069-20220304010708527-335148930.png)

### 3. Rules 隐藏噪音包

Rules 菜单勾选 **Hide CONNECTs** 和 **Hide 304s**，隐藏不需要的数据包：

![Hide CONNECTs 和 Hide 304s](assets/aacd6f94b8438bf55b5c075b36f617fa.png)

## 七、手机/APP 抓包

前置条件：Tools → Options → Connections 勾选 **Allow remote computers to connect**（见第四节），并确认 Fiddler 主机 IP 和端口（8888）。

![主机IP和端口1](assets/cede86992f77892b5a05757efb425a8c.png)

![主机IP和端口2](assets/db733590028b1e0e52c271bc265ddf3b.png)

### 步骤

1. **保持手机和电脑在同一网段**（建议同一 wifi）。PC 的 IP 可在 cmd 运行 `ipconfig` 获取：

![ipconfig](../assets/1897069-20220208143656042-1146410889.png)

1. **手机 wifi 设置代理**：手动代理 → 服务器填 PC 的 IP，端口填 8888

![wifi代理设置](../assets/1897069-20220208143701809-277291803.png)

![手机代理设置](assets/bff55550bfa7be6b26c810539c905856.png)

1. **手机浏览器访问 `http://PC的IP:8888`，下载并安装证书**（打不开的话，重启 Fiddler 再试）

![证书下载页](../assets/1897069-20220304010813110-250096766.png)

![证书安装1](assets/8f94df0bcdc3b7b5c878df3c2d1877a8.png)

![证书安装2](assets/86bb9682f601082155492173ef7ddb25.png)

1. **iOS 额外步骤**：设置 → 通用 → 安装描述文件；再到 通用 → 关于本机 → 证书信任设置 中开启信任

![安装描述文件](../assets/1897069-20220304010822998-820419828.png)

![证书信任开启](../assets/1897069-20220304010834227-716012746.png)

![证书信任1](assets/fce9abd48d87358d997949d37360761c.png)

![证书信任2](assets/ba2fc0210e4ef877bb83f9a24c351081.png)

1. 访问 APP，Fiddler 即可抓到手机上所有网络请求

![抓包效果](../assets/1897069-20220208143720585-654878650.png)

## 八、模拟 HTTP 请求（小接口测试）

在 Composer 中手工构造并发送请求：

![模拟http请求](../assets/1897069-20220304010855406-415549822.png)

## 九、会话管理

### 1. 为什么要保存会话

场景：在上海测试发现接口 bug，而开发该接口的合作开发在北京。光截图描述不清，不如把整个会话保存成文件发给对方——专业且让对方心服口服。

### 2. 保存方式

- **File → Save → All Sessions**：保存所有会话（.saz 文件）
- **File → Save → Selected Sessions**：
  - in ArchiveZIP：保存为 saz 文件
  - as Text：以 txt 保存整个会话（含 Request 和 Response）
  - as Text (Headers only)：仅保存头部
- **Request**：Entire Request（headers+body）/ Request Body（只保存 body）
- **Response**：Entire Response / Response Body / and Open as Local File（保存并打开文件）

![保存为文本](../assets/614655-20170901222145280-907526967.png)

![文本结果](../assets/614655-20170901222154265-196398975.png)

### 3. 导入会话

把保存的 .saz 文件直接拖进 Fiddler，或 File → Load Archive 导入。

![拖入会话文件](../assets/614655-20170901222243280-379583314.png)

![Load Archive](../assets/614655-20170901222255343-503420149.png)

### 4. Replay（录制回放）

1. 导入请求后，选中某个请求点 **Replay** 按钮，重新发送请求
2. `Ctrl+A` 全选后点 Replay，一次性批量请求

保存会话 + Replay 相当于"录制和回放"。

![Replay](../assets/614655-20170901222327093-512989273.png)

### 5. 自定义会话框列

**添加列**：右键会话框菜单 → Customize columns → Collection 选 Miscellaneous → Field Name 选 RequestMethod → Add

![自定义列1](../assets/614655-20170901222351202-1522484997.png)

![自定义列2](../assets/614655-20170901222401968-270837959.png)

![自定义列3](../assets/614655-20170901222424030-136415011.png)

![自定义列4](../assets/614655-20170901222439593-1267859681.png)

![自定义列5](../assets/614655-20170901222505780-573200134.png)

**隐藏列**：右键要隐藏的列 → Hide this column；恢复：Ensure all columns are visible

![隐藏列](../assets/614655-20170901222515265-2011860615.png)

![恢复列](../assets/614655-20170901222526358-156329247.png)

**调整顺序**：按住列头拖动即可（如把 Content-Type 拖到前面）

![调整顺序](../assets/614655-20170901222536608-2003268002.png)

**会话排序**：点击会话框上的列头即按该列排序（上箭头正序/下箭头倒序）。排序不能取消，重启 Fiddler 即可恢复。

![会话排序](../assets/614655-20170901222546546-1467307173.png)

## 十、断点调试

### 断点能干什么

- **绕过前端验证测后端**：例——登录账号限制 11 位手机号，前后端同时校验，前端不合法就不发请求。所以要抓接口、改请求参数，绕过前端验证，发一个大于或小于 11 位的数给后端，验证后端是否校验
- 修改 HTTP 请求头信息：Cookie、User-Agent 等
- 修改请求数据突破表单限制：充值最大 100 可以改成 10000
- 拦截响应数据修改响应体：修改服务端返回的页面数据
- 发送请求前可重新发送，测试不同正例、反例；多次调试可以摸清哪些参数必带、哪些可删

### 两种断点

- **before requests（请求前）**：打在 request 时、未到达服务器之前
- **after responses（响应后）**：服务器响应之后、Fiddler 把响应传回客户端之前

![before requests](../assets/1226393-20171026180347648-1719634991.png)

![after responses](../assets/1226393-20171026180437148-536320425.png)

### 全局断点

1. Rules → Automatic Breakpoints → **Before Requests**：

![Automatic Breakpoints 菜单](assets/505d2d10809b6b4f7113dccdc2d67a65.png)

![全局断点设置](../assets/614655-20170901221942015-503689400.png)

1. 之后所有请求都会被拦截（会话左侧出现 **T** 标记），点 **Go** 放行下一步：

![T标记](../assets/614655-20170901221953749-1556450496.png)

![Go按钮](../assets/614655-20170901222005265-516686738.png)

1. 选中目标会话，右侧 WebForms 里的参数都可修改，改完点 **Run to Completion** 提交：

![WebForms修改参数](../assets/614655-20170901222016077-755580047.png)

1. 全局断点期间无法正常上网，用完记得清：Rules → Automatic Breakpoints → **Disabled**

### 命令断点（只拦指定接口）

| 命令 | 作用 | 取消 |
|---|---|---|
| `bpu <接口地址>` | 请求前断点 | 命令行输入 `bpu` 回车 |
| `bpafter <接口地址>` | 响应后断点 | 命令行输入 `bpafter` 回车 |
| `bpu <域名>` | 拦截该站点所有请求（其他站正常） | 同上 |

例：`bpu https://passport.cnblogs.com/user/signin`，请求登录接口时只拦截这一条，可修改任意请求参数。

![bpu命令](../assets/614655-20170901222031921-1470109987.png)

### 完整示例：登录接口改参数

1. 访问登录页，输入正确的手机号和密码，通过 Fiddler 查看请求参数信息：

![登录请求参数](assets/52160b0fd79acb7f05e8f6d082de134f.png)

1. Rules → Automatic Breakpoints → Before Requests 打断点：

![Before Requests](assets/d096461f41fa73a9f09420958593d5ec.png)

1. Replay → 选中要调试的包 → 修改参数信息 → Run to Completion：

![修改参数1](assets/bb71cdb5a559f85a0360ba61455c8075.png)

![修改参数2](assets/aa3bef7932bb361b3f0de007e40d4cb6.png)

1. 查看响应结果，验证后端逻辑：

![响应结果](assets/fde42e5d2c808325999353cfe73f4a16.png)

## 十一、弱网测试

### 1. 开关

Rules → Performance → **Simulate Modem Speeds** 勾选开启，再点一次关闭。

![Performance 菜单](assets/e5094c62dee2724d33e8ec85a73056bd.png)

![Simulate Modem Speeds](assets/92eb7354642d107bf4a6eaebcd6f48df.png)

### 2. 自定义速率（模拟 2G/3G/4G）

Rules → Customize Rules 打开脚本编辑器，`Ctrl+F` 搜索 `simulate`，找到 OnBeforeRequest 里的这段：

![Customize Rules](../assets/1897069-20220208143727197-1601587831.png)

![simulate代码段](../assets/1897069-20220208143733792-274714348.png)

```js
if (m_SimulateModem) {
    // Delay sends by 300ms per KB uploaded.
    oSession["request-trickle-delay"] = "300";
    // Delay receives by 150ms per KB downloaded.
    oSession["response-trickle-delay"] = "150";
}
```

- `request-trickle-delay`：请求延迟（ms/KB）
- `response-trickle-delay`：响应延迟（ms/KB）
- 默认 300/150，改成目标值后 `Ctrl+S` 保存，再勾选 Simulate Modem Speeds 生效

参考速率表（上传/下载，ms per KB）：

| 网络 | 上传 | 下载 |
| --- | --- | --- |
| 2G | 500 | 400 |
| 3G | 100 | 100 |
| 4G | 15 | 10 |

![网络传输值设置](assets/026dff369664667c1d19b4758c33b98b.png)

### 3. 随机弱网（更贴近真实）

测试中往往需要随机强弱网络而非恒定弱网，把代码改成：

```js
static function randInt(min, max) {
    return Math.round(Math.random()*(max-min)+min);
}
if (m_SimulateModem) {
    // 1-2000ms 之间的随机延迟
    oSession["request-trickle-delay"] = ""+randInt(1,2000);
    oSession["response-trickle-delay"] = ""+randInt(1,2000);
}
```

偶尔延迟偶尔正常，比恒定弱网更贴近真实网络。

## 十二、线上调试（AutoResponder）

场景：不改代码，直接用 Fiddler 把某个响应替换成本地文件，调试网页任意内容。

1. 先抓包获取响应信息：

![抓取响应](assets/f89c59af6aaafd3cb923c9c224d256d1.png)

1. 把响应信息复制到 `.html` 文件中，修改需要的内容
2. 切到 **AutoResponder** 标签页，添加规则：原 URL → 本地 .HTML 文件：

![AutoResponder1](assets/e287f6fe68f57ec583e08be58ac3c5c7.png)

![AutoResponder2](assets/b340697b0a02e15fb5710e2f5f931bfa.png)

1. 回到访问页面，`Shift+F5` 强制刷新，会显示修改后的数据

> [!warning]
>
> 注意
> 一定要勾选规则启用和本地文件相关选项，不勾选本地文件映射就会失效。

![必须勾选的选项](assets/979b985dd94b299c4f23ba0bb52471d1.png)

## 十三、定位前后端 bug

- **理论上**：
  - 请求参数有问题 → 前端问题
  - 请求参数没问题但返回数据有问题 → 后端问题
- **实际上**：对比响应结果和页面错误信息（结合需求文档和日志，比如出现异常类信息：100% 后端问题）

> 通过 Fiddler 抓取请求和响应参数，分析参数可定位前后端问题。例：测试登录接口，输入正确的手机号和密码，前端却提示"请输入正确的用户名和密码"——界面提示只能描述 bug 表象，抓包发现是前端参数名错误或参数值为空导致后台报错，bug 指向前端，并把参数数据和接口文档报文作为附件上传，可显著提高解决效率。另一方面，通过响应数据也能判断问题所在：如前端报"服务器故障"，抓包发现响应 502，可手动或联系运维重启服务。

## 十四、Fiddler vs 浏览器 F12

- **相同点**：都可以对 http 和 https 进行抓取分析
- **不同点**：
  - F12 无法抓 APP 端的 http 请求，Fiddler 可以
  - F12 无法修改篡改请求数据，Fiddler 可以（断点/重放）
  - F12 的优势：console 中可输入命令方便查看前端数据；application 面板可查看请求数据，尤其涉及登录、邀请相关的信息

## 相关笔记

- 2026-07-09
- [[Web协议和测试]]
- [[移动APP测试]]
- [[练习计划]]
