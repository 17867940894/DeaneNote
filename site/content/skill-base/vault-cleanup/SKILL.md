---
name: vault-cleanup
description: 维护 Obsidian 知识库的附件目录与图片引用：统一附件目录为 assets、修复/校验图片引用、同名图片去重、清理未引用孤儿图、迁移后验证。当任务涉及整理图片附件目录（.assets→assets）、修复图片断链、图片去重、清理未引用图片、Obsidian 附件设置调整时使用。触发词：附件目录、assets 迁移、图片去重、断链修复、孤儿图、Obsidian 图片。
---

# Vault Cleanup（知识库附件整理）

## 为什么（核心事实）
1. Obsidian 不索引以 `.` 开头的隐藏目录（如 `.assets`），图片无法显示，还会被“自动删除未链接附件”误删。
2. 图片引用统一用 `![](./assets/文件名)`，**必须带 `./` 前缀**，否则 Obsidian 按 vault 根路径解析而报失效。
3. Obsidian 设置 `deleteUnlinkedAttachments` 必须为 `none`，否则脚本导入的图片会被当“未链接”自动删除。
4. 删除图片前必须先做“精确路径引用解析”（md 目录 + 引用路径），只删未被引用的；删除前出清单、断言，并确保有 git 快照可回退。

## 操作步骤
1. 盘点：列出所有附件目录（`assets`、`.assets`、`*.assets`），按父目录分组；统计 md 中的 `.assets/` 引用数量。
2. 统一目录：每个父目录下把同级的附件目录合并/重命名为一个 `assets`（如 Fiddler.assets + Wireshark.assets → assets）；根目录空附件目录删除。
3. 更新引用（按此顺序替换，避免误伤）：
   - URL 编码路径（如 `%E5%8E%9F...%BE.assets/`）→ `assets/`
   - 可见后缀引用（`X.assets/`）→ `assets/`
   - `.assets/` → `assets/`
   - 裸 `assets/`（无 `./`）→ `./assets/`
4. 同步设置与约定：`.obsidian/app.json` 的 `attachmentFolderPath` = `./assets`；更新 SKILL.md / CLAUDE.md / 子技能模板里对 `.assets` 的描述。
5. 校验：`obsidian reload` → 引用完整性检查（相对路径解析，缺失 = 0）→ `obsidian unresolved` 无新增断链 → 抽查含图笔记图片可显示。
6. 去重：同名图片先按 md5 分组，内容一致才可去重；被引用的副本先改引用（正确计算相对路径）再删，未引用的直接删；删除前输出清单并断言“无一被引用”。
7. 收尾：`git status` 复核；建议 git 提交快照。

## 约束
- 批量维护例外：转换 / 迁移 / 删除可批量直接操作，但完成后必须用 obsidian CLI 校验 + reload。
- 写操作优先走 Obsidian CLI（rename / move / create / append / property:set / eval，需客户端运行）。
- 删除前必须有 git 快照或确认可回退；本环境回收站可能不生效，按永久删除处理。
- 不读取、不修改 config.md（凭据文件）。
- 有 `![[...]]` 嵌入引用的图片必须保留（嵌入不参与路径解析，容易被误判为未引用）。