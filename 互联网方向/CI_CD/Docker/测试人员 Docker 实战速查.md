> 定位：给测试同学用的 Docker 速查手册，不讲原理推导，只讲**怎么用、怎么查、怎么排障**。
> 完整原理见 [[第一章 Docker 简介/1.0 Docker 简介|第一章]] ~ [[第六章 访问仓库/6.0 访问仓库|第六章]]。

---

## 一、测试为什么要懂 Docker

| 场景 | 没 Docker 的痛 | 有 Docker 后 |
|------|--------------|-------------|
| 依赖服务（MySQL/Redis/MQ） | 本机装一堆，污染开发环境、版本冲突 | 一条命令起停，用完即焚 |
| 环境一致性 | "我本机好的呀" —— 测试环境/生产对不上 | 镜像即环境，随处运行 |
| 缺陷复现 | 现场难还原，依赖版本对不上 | 指定镜像 tag 精确复现 |
| 并行测试 | 一套环境多人抢 | 每套用例独立容器，互不干扰 |

> [!tip]
>
> 一句话记忆
> **镜像 = 程序 + 运行环境的快照；容器 = 快照跑起来的实例；仓库 = 放快照的地方。**
> 对应知识库：[[第二章 基本概念/2.1 镜像|2.1 镜像]] / [[第二章 基本概念/2.2 容器|2.2 容器]] / [[第二章 基本概念/2.3 仓库|2.3 仓库]]

---

## 二、测试环境搭建（最高频）

### 2.1 起一个数据库服务

```bash
# 起 MySQL 8，root 密码 123456，数据存到命名卷（容器删了数据不丢）
docker run -d --name mysql-test \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -p 3306:3306 \
  -v mysql-data:/var/lib/mysql \
  mysql:8.0

# 起 Redis
docker run -d --name redis-test -p 6379:6379 redis:7
```

### 2.2 端口映射说明

```bash
-p 3306:3306    # 宿主机端口:容器端口，外部用 宿主机IP:3306 访问
-p 3307:3306    # 宿主机端口冲突时换一个
-p 127.0.0.1:3306:3306  # 只允许本机访问，不暴露局域网
```

> [!warning]
>
> 端口冲突
> 启动报 `port is already allocated` = 宿主机端口被占。换端口或先 `docker ps` 看谁占了。

### 2.3 起被测应用（依赖 Dockerfile）

```bash
# 在项目目录（有 Dockerfile）构建并运行
docker build -t myapp:v1.0.0 .
docker run -d --name app-test -p 8080:8080 --link mysql-test myapp:v1.0.0
```

对应知识库：[[第一章 Docker 简介/1.1 快速上手|1.1 快速上手]]、[[第四章 使用镜像/4.1 获取镜像|4.1 获取镜像]]

---

## 三、日常操作速查表

| 想做什么 | 命令 |
|---------|------|
| 看所有运行中容器 | `docker ps` |
| 看所有容器（含已停止） | `docker ps -a` |
| 看某个容器日志 | `docker logs 容器名` |
| 实时跟踪日志 | `docker logs -f 容器名` |
| 只看最近 100 行 | `docker logs --tail 100 容器名` |
| 启动/停止/重启 | `docker start 容器名` / `docker stop 容器名` / `docker restart 容器名` |
| 进容器排查 | `docker exec -it 容器名 bash`（镜像里没有 bash 用 `sh`） |
| 在容器外执行单条命令 | `docker exec 容器名 cat /etc/hosts` |
| 拷文件出容器 | `docker cp 容器名:/app/logs/error.log ./error.log` |
| 拷文件进容器 | `docker cp ./config.yaml 容器名:/app/config.yaml` |
| 删容器 | `docker rm 容器名`（先停；`-f` 强删） |
| 删镜像 | `docker rmi 镜像名` |
| 查镜像列表 | `docker images` |
| 环境总览 | `docker stats`（实时 CPU/内存） |

> 详细操作见 [[第五章 操作容器/5.1 启动|5.1 启动]] ~ [[第五章 操作容器/5.6 删除|5.6 删除]]。

---

## 四、测试排障三板斧

### 4.1 容器起不来 / 秒退

```bash
# 1. 看日志（第一现场）
docker logs 容器名

# 2. 前台跑一次，直接看报错
docker run --rm 镜像名   # 去掉 -d，输出会直接打在终端

# 3. 进容器看状态
docker exec -it 容器名 bash
ps aux          # 看进程
cat /etc/os-release  # 确认系统
```

> [!important]
>
> 容器秒退的真相
> 容器生命周期绑着**主进程**。主进程退出 = 容器退出。`docker run -d nginx` 能一直跑是因为 nginx 前台运行；`docker run -d ubuntu` 秒退是因为 ubuntu 没有常驻进程。
> 排障时给测试应用加个前台命令：`CMD ["tail", "-f", "/dev/null"]`（仅调试用）。

### 4.2 连不上容器里的服务

```bash
docker ps                      # 看端口映射生效没
docker port 容器名              # 看映射关系
# 常见原因：没加 -p、容器内部监听 127.0.0.1、防火墙
```

### 4.3 数据 / 配置不对

```bash
docker exec 容器名 env          # 看环境变量注入
docker inspect 容器名           # 完整配置（挂载、网络、entrypoint）
docker logs --tail 50 容器名    # 找启动报错
```

---

## 五、数据持久化：测试数据别丢

| 方式 | 命令 | 适用 |
|------|------|------|
| 命名卷（推荐） | `-v mysql-data:/var/lib/mysql` | 数据要留，容器可删 |
| 绑定挂载 | `-v /宿主机路径:/容器路径` | 想直接看/改宿主机文件 |
| 只读挂载 | `-v 卷:/路径:ro` | 防止容器改配置 |

```bash
# 测试数据备份（拷出卷）
docker run --rm -v mysql-test-data:/data -v $(pwd):/backup ubuntu cp -r /data /backup/mysql-backup
```

> [!warning] 
>
> 不挂卷 = 数据一次性
> 容器删除后，容器层写入的数据**全部消失**，没有恢复途径。
> 详见 [[第二章 基本概念/2.2 容器|2.2 容器 - 容器的存储层]]。

---

## 六、环境清理（用完就撤）

```bash
docker ps -a                    # 先看有什么
docker stop $(docker ps -q)     # 停掉所有
docker container prune -f       # 删所有已停止容器
docker image prune -f           # 删悬空镜像
docker system df                # 看占了多少空间
docker system prune -a -f       # 一键全清（慎用！连没用过的镜像一起删）
```

> 详细见 [[第四章 使用镜像/4.3 删除本地镜像|4.3 删除本地镜像]]、[[第五章 操作容器/5.6 删除|5.6 删除]]。

---

## 七、性能测试配合

```bash
# 压测时限制被测容器资源，制造瓶颈场景
docker run -d --name app-loadtest \
  --cpus=1 --memory=512m \
  myapp:v1.0.0

# 实时观察资源占用
docker stats --no-stream

# 单次采样
docker stats --no-stream 容器名
```

> [!note]
>
> 资源限制的意义
> 用 `--cpus` / `--memory` 限制后，可以在低配环境复现"线上资源紧张导致超时/报错"的缺陷，比直接跑满机器更接近真实问题。

---

## 八、测试人员高频坑

| 坑 | 现象 | 解法 |
|----|------|------|
| 容器时区是 UTC | 日志时间差 8 小时 | `-e TZ=Asia/Shanghai` 或挂 `/etc/localtime` |
| 镜像 `latest` 不可控 | 每次拉到的版本可能不同 | 明确 tag：`mysql:8.0` 而非 `mysql:latest` |
| 端口被占 | `port is already allocated` | `docker ps` 查占用，换端口 |
| 中文乱码 | 容器内无中文字体/编码 | 挂字体或 `-e LANG=C.UTF-8` |
| 忘挂卷删容器 | 测试数据没了 | 先 `docker cp` 备份再删 |
| 改了代码没生效 | 还在跑旧镜像 | `docker build` 重建 + `docker restart` |

---

## 九、与 CI/CD 的关系（一句话）

Docker 是 CI/CD 流水线的"运载工具"：**同一镜像从测试环境一路跑到生产**，测试环境验证过的东西，生产环境理论上完全一致。这也是"环境一致性"最大的价值 —— 对应 [[第一章 Docker 简介/1.3 为什么要用 Docker|1.3 为什么要用 Docker]]。

---

## 相关笔记导航

- [[第一章 Docker 简介/1.0 Docker 简介|第一章 Docker 简介]]
- [[第二章 基本概念/2.0 基本概念|第二章 基本概念]]
- [[第三章 安装 Docker/3.1 Ubuntu|第三章 安装 Docker]]
- [[第四章 使用镜像/4.0 使用镜像|第四章 使用镜像]]
- [[第五章 操作容器/5.0 操作容器|第五章 操作容器]]
- [[第六章 访问仓库/6.0 访问仓库|第六章 访问仓库]]
