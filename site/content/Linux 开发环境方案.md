根据前面的定位，你这台机器：

- **机械革命无界 15X Pro**
- **AMD Ryzen AI 9 HX 365**
- **32GB RAM**
- **1TB SSD**

目标：

- Linux 开发环境
- Docker
- AI 应用开发
- RAG 小项目
- BGE 类 embedding 模型
- Agent 编程辅助
- 调用云端 LLM（DeepSeek / OpenAI / Claude 等）

不跑大模型训练，不折腾 ROCm。

下面整理一套从 **安装 → 系统配置 → 软件安装 → RAG 环境 → 运行项目** 的完整方案。

------

# 一、最终架构

整体环境：

```json
机械革命无界15X Pro
│
├── Ubuntu 24.04 LTS
│
├── 开发工具
│   ├── VS Code
│   ├── Git
│   ├── Python 3.12
│   ├── uv
│   └── Node.js
│
├── Docker
│   ├── PostgreSQL
│   │      └── pgvector
│   │
│   ├── Qdrant
│   │
│   ├── Redis
│   │
│   └── RAG API
│
├── AI工具
│   ├── LangChain
│   ├── LlamaIndex
│   ├── BGE-M3
│   └── Agent
│
└── LLM接口
    ├── DeepSeek API
    ├── OpenAI API
    └── Claude API
```

------

# 二、安装 Linux

## 1. 制作启动U盘

准备：

- 16GB U盘
- Ubuntu 24.04 LTS ISO

工具：

Windows：

- Rufus

写入：

```json
GPT
UEFI
FAT32
```

------

## 2. BIOS设置

开机：

```json
F2
```

进入 BIOS。

设置：

### 开启

```json
UEFI Boot
```

### 关闭（如果双系统）

```json
Secure Boot
```

------

## 3. 磁盘规划

你的 1TB SSD：

建议：

```json
EFI
512MB

/
120GB
ext4

/home
剩余

swap
16GB
```

原因：

AI开发大量文件：

```json
Docker镜像
Python环境
模型缓存
数据集
```

放 `/home` 更方便。

------

# 三、Ubuntu基础配置

更新：

```bash
sudo apt update
sudo apt upgrade -y
```

安装基础工具：

```bash
sudo apt install -y \
git \
curl \
wget \
vim \
htop \
tree \
ripgrep \
build-essential
```

------

# 四、AMD笔记本优化

## 查看硬件

```bash
lspci
```

查看CPU：

```bash
lscpu
```

查看显卡：

```bash
lspci | grep VGA
```

------

## 安装微码

AMD：

```bash
sudo apt install amd64-microcode
```

------

## 电源管理

安装：

```bash
sudo apt install power-profiles-daemon
```

查看：

```bash
powerprofilesctl
```

模式：

性能：

```bash
powerprofilesctl set performance
```

省电：

```bash
powerprofilesctl set power-saver
```

------

# 五、安装开发环境

## 1. Git

```bash
sudo apt install git
```

配置：

```bash
git config --global user.name "你的名字"

git config --global user.email "你的邮箱"
```

------

# 2. Python 3.12

Ubuntu 24.04 默认：

```bash
python3 --version
```

应该：

```json
Python 3.12.x
```

安装：

```bash
sudo apt install python3-pip python3-venv
```

------

# 3. 安装 uv（推荐）

比 pip 快很多。

安装：

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

重新加载：

```bash
source ~/.bashrc
```

测试：

```bash
uv --version
```

------

# 4. Node.js

Agent工具很多需要 Node。

安装：

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -

sudo apt install nodejs
```

检查：

```bash
node -v
npm -v
```

------

# 六、安装 VS Code

官方方式：

```bash
sudo snap install code --classic
```

插件：

推荐：

```json
Python
Pylance
Docker
GitLens
Remote SSH
Jupyter
Continue
```

------

# 七、安装 Docker

## 安装

```bash
sudo apt install docker.io docker-compose-v2
```

启动：

```bash
sudo systemctl enable docker

sudo systemctl start docker
```

------

## 当前用户加入docker组

否则每次sudo，人类又要重复输入密码这种古老仪式：

```bash
sudo usermod -aG docker $USER
```

重新登录。

测试：

```bash
docker run hello-world
```

------

# 八、安装 AI 开发环境

创建工作目录：

```bash
mkdir ~/workspace

cd ~/workspace
```

------

## 创建RAG项目

例如：

```json
rag-demo
```

结构：

```json
rag-demo

├── app
│
├── data
│
├── models
│
├── docker-compose.yml
│
├── pyproject.toml
│
└── README.md
```

------

# 九、Python RAG环境

进入：

```bash
cd rag-demo
```

初始化：

```bash
uv init
```

安装：

```bash
uv add \
langchain \
langchain-community \
sentence-transformers \
qdrant-client \
fastapi \
uvicorn
```

------

# 十、安装Embedding模型

推荐：

## BGE-M3

适合中文：

```json
BAAI/bge-m3
```

安装：

```bash
uv add sentence-transformers
```

测试：

```python
from sentence_transformers import SentenceTransformer

model = SentenceTransformer(
    "BAAI/bge-m3"
)

vectors = model.encode(
    [
        "机械革命无界15XPro安装Linux"
    ]
)

print(vectors.shape)
```

输出：

类似：

```json
(1,1024)
```

说明成功。

------

# 十一、部署向量数据库

推荐 Qdrant。

docker-compose.yml：

```yaml
services:

  qdrant:
    image: qdrant/qdrant
    ports:
      - "6333:6333"
    volumes:
      - ./qdrant:/qdrant/storage
```

启动：

```bash
docker compose up -d
```

访问：

```json
http://localhost:6333
```

------

# 十二、加入 PostgreSQL + pgvector（项目需要时）

compose：

```yaml
postgres:

 image: pgvector/pgvector

 environment:

   POSTGRES_PASSWORD: password

 ports:

   - 5432:5432
```

用途：

保存：

- 用户数据
- 文档
- 向量

------

# 十三、接入大模型API

你的方案：

```json
BGE-M3
负责搜索

DeepSeek API
负责回答
```

安装：

```bash
uv add openai
```

代码：

```python
from openai import OpenAI

client = OpenAI(
    api_key="你的key",
    base_url="https://api.deepseek.com"
)

response = client.chat.completions.create(

    model="deepseek-chat",

    messages=[
        {
        "role":"user",
        "content":"解释RAG"
        }
    ]
)

print(response.choices[0].message.content)
```

------

# 十四、Agent工具

推荐安装：

## Claude Code

适合终端：

```bash
npm install -g @anthropic-ai/claude-code
```

------

## Aider

Python：

```bash
uv tool install aider-chat
```

运行：

```bash
aider
```

------

## Continue

VS Code插件：

用途：

- 本地/云模型
- 代码补全
- Agent修改代码

------

# 十五、日常开发流程

以后你的流程：

```json
打开电脑

↓

VS Code

↓

docker compose up

↓

启动：

PostgreSQL
Qdrant
Redis

↓

运行:

uv run python app.py

↓

Agent辅助开发

↓

提交Git
```

------

# 十六、建议安装的软件清单

最终：

## 系统

```json
Ubuntu 24.04 LTS
KDE/GNOME
```

## 开发

```json
VS Code
Git
Python 3.12
uv
Node.js
Docker
```

## AI

```json
LangChain
LlamaIndex
Sentence Transformers
BGE-M3
Qdrant
pgvector
DeepSeek API
```

## 工具

```json
tmux
ripgrep
jq
htop
```

------

# 十七、这台机器的定位

你的 HX365 + 32GB：

最适合：

✅ RAG知识库
✅ 企业文档问答
✅ Agent工作流
✅ 自动化脚本
✅ AI应用开发
✅ Docker微服务

不适合：

❌ 本地训练LLM
❌ 大模型微调
❌ GPU推理集群

你的路线其实是现在 AI 开发里更主流的一条：

**本地负责工程环境，模型能力通过 API 调用。**

这台机器不用追求“AI算力怪兽”，重点是把开发环境打磨成一个稳定的 AI 应用实验平台。你买的硬件方向和这个用途基本吻合。
