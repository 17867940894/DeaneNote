# 日常同步脚本：把 vault 最新内容同步进 site/content/ 并规范化图片路径
# 用法: powershell -File site\scripts\sync-content.ps1
param(
  [string]$Vault = "D:\HighFrequencyProject\DeaneNote",
  [string]$AiTestFallback = "D:\notes\content\Ai 测试"
)

$ErrorActionPreference = "Stop"
$content = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..\content")).Path

# 1) vault 中存在的三大文件夹：/MIR 镜像（vault 删了的内容站点也删）
$vaultFolders = @("测试笔记", "测试工具", "课外拓展")
foreach ($f in $vaultFolders) {
  $src = Join-Path $Vault $f
  if (-not (Test-Path -LiteralPath $src)) { Write-Warning "missing folder, skipped: $src"; continue }
  robocopy $src (Join-Path $content $f) /MIR /XD .git .obsidian .trash .workbuddy node_modules /NFL /NDL /NJH /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed: $f (code $LASTEXITCODE)" }
  $n = (Get-ChildItem -LiteralPath (Join-Path $content $f) -Recurse -File).Count
  Write-Output ("mirrored from vault: {0} ({1} files)" -f $f, $n)
}

# 2) Ai 测试：vault 中无此文件夹（旧 dean.github.io 遗留），沿用旧 content 的最后状态
if (Test-Path -LiteralPath $AiTestFallback) {
  robocopy $AiTestFallback (Join-Path $content "Ai 测试") /E /NFL /NDL /NJH /NP | Out-Null
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed: Ai 测试 (code $LASTEXITCODE)" }
  Write-Output "copied (fallback): Ai 测试"
}

# 3) 文件夹说明页：vault 中不存在，/MIR 会删掉它们，这里恢复
$old = "D:\notes\content"
foreach ($f in @("Ai 测试", "测试笔记", "测试工具", "课外拓展")) {
  $srcIndex = Join-Path $old "$f\index.md"
  if (Test-Path -LiteralPath $srcIndex) {
    Copy-Item -LiteralPath $srcIndex -Destination (Join-Path $content "$f\index.md") -Force
  }
}

# 4) 根级单篇
$rootMd = "常见警报类型.md"
if (Test-Path -LiteralPath (Join-Path $Vault $rootMd)) {
  Copy-Item -LiteralPath (Join-Path $Vault $rootMd) -Destination (Join-Path $content $rootMd) -Force
  Write-Output "copied: $rootMd"
}

# 5) 图片路径规范化（仓库根相对路径）
Write-Output "--- normalizing image paths ---"
node (Join-Path $PSScriptRoot "normalize-images.mjs") $content

$md = (Get-ChildItem -LiteralPath $content -Recurse -Filter *.md).Count
Write-Output "sync done: $md md files"
