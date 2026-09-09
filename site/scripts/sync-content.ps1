# 日常同步脚本：按 vault 真实目录结构同步内容到 site/content/
# 用法: powershell -ExecutionPolicy Bypass -File site\scripts\sync-content.ps1
param(
  [string]$Vault = "D:\HighFrequencyProject\DeaneNote"
)

$ErrorActionPreference = "Stop"
$content = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\content")).Path

# 1) 内容文件夹清单（与 vault 根目录一致；排除 site/ 与 assets/）
$folders = @(
  "JavaScript",
  "javaEE",
  "skill-base",
  "互联网方向",
  "测试工具",
  "测试笔记",
  "知识体系和分析",
  "课外拓展",
  "面试"
)

# 文件夹说明页（vault 中不存在，/MIR 会删掉，同步后自动恢复）
$folderIndex = @{
  "JavaScript"      = "JS 基础、BOM/DOM、标准库、异步与浏览器对象等。"
  "javaEE"          = "Java 后端：JDBC、Servlet、SSM、Spring Boot 等。"
  "skill-base"      = "技能基础知识与学习路径。"
  "互联网方向"      = "软件测试（互联网方向）求职学习笔记：测试理论、实战与面试向。"
  "测试工具"        = "常用测试工具使用手册：GitKraken 等。"
  "测试笔记"        = "数据库、Linux、接口、自动化、移动端与软件测试基础等。"
  "知识体系和分析"  = "知识体系梳理与分析。"
  "课外拓展"        = "软技能与学习方法拓展。"
  "面试"            = "面试准备与复盘。"
}

# 2) 镜像同步各文件夹
foreach ($f in $folders) {
  $src = Join-Path $Vault $f
  if (-not (Test-Path -LiteralPath $src)) { Write-Warning "missing folder, skipped: $src"; continue }
  robocopy $src (Join-Path $content $f) /MIR /XD .git .obsidian .trash .workbuddy node_modules /NFL /NDL /NJH /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed: $f (code $LASTEXITCODE)" }
  $n = (Get-ChildItem -LiteralPath (Join-Path $content $f) -Recurse -File).Count
  Write-Output ("mirrored: {0} ({1} files)" -f $f, $n)
  # 恢复/生成文件夹说明页
  $idx = Join-Path $content "$f\index.md"
  if (-not (Test-Path -LiteralPath $idx)) {
    $desc = if ($folderIndex.ContainsKey($f)) { $folderIndex[$f] } else { "" }
    @("---`ntitle: $f`n---`n`n$desc`n") | Out-File -LiteralPath $idx -Encoding utf8
  }
}

# 3) 根级图片资产（笔记里的 ../../assets/ 引用依赖它）
if (Test-Path -LiteralPath (Join-Path $Vault "assets")) {
  robocopy (Join-Path $Vault "assets") (Join-Path $content "assets") /MIR /NFL /NDL /NJH /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed: assets (code $LASTEXITCODE)" }
  Write-Output "mirrored: assets/"
}

# 4) 根级内容笔记（排除 AGENTS.md / SKILL.md / temp.md 等元文件）
$rootNotes = @("常见警报类型.md", "每日一问.md", "Linux 开发环境方案.md")
foreach ($md in $rootNotes) {
  if (Test-Path -LiteralPath (Join-Path $Vault $md)) {
    Copy-Item -LiteralPath (Join-Path $Vault $md) -Destination (Join-Path $content $md) -Force
    Write-Output "copied: $md"
  }
}

# 5) 图片路径规范化（仓库根相对路径）
Write-Output "--- normalizing image paths ---"
node (Join-Path $PSScriptRoot "normalize-images.mjs") $content

$mdCount = (Get-ChildItem -LiteralPath $content -Recurse -Filter *.md).Count
Write-Output "sync done: $mdCount md files"
