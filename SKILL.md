# DeanNote 根技能（路由）

> 本文件是 DeanNote 的任务路由入口：先判断任务类型，再加载 `skill-base/` 下的对应子技能执行。
> 安全底线：`config.md` 含明文凭据，禁止读取、回显、提交；笔记写操作一律走 Obsidian CLI；问答前可查阅 vault 内相关笔记（用 Grep/Read 工具，本机已卸载 RAG，不再依赖本地语义检索）。
> 技能库边界：`skill-base/` 只放定制化、高频技能；额外能力去 Agent Base（`D:\Agent Base\skills\`）查找。obsidian MCP（Local REST API）为 macOS/iOS 专用二进制，Windows 不可用，不引入。

## 触发条件 → 子技能

- 任务涉及**整理笔记**（双链完整性、命名规范、新增/修改/重命名笔记、结构优化、断链检查）→ 读取并使用子技能 `skill-base/note-organizer/SKILL.md`，按其步骤执行。
- 任务涉及**附件目录整理**（assets 迁移、图片去重、断链修复、清理孤儿图）→ 读取并使用子技能 `skill-base/vault-cleanup/SKILL.md`，按其步骤执行。
- 任务涉及**笔记事实审核**（事实订正、笔记校对、联网核验、优化笔记）→ 读取并使用子技能 `skill-base/note-fact-review/SKILL.md`，按其步骤执行。
- 任务涉及**文档转 Markdown**（Office / PDF / EPUB / CSV 等转 md、导入外部文档内容）→ 读取并使用子技能 `skill-base/convert-documents-to-markdown/SKILL.md`，按其步骤执行。
- 任务涉及**查找 / 安装技能**（"有没有技能能…"、"帮我找 / 装个技能"、扩展能力）→ 读取并使用子技能 `skill-base/find-skills/SKILL.md`，按其步骤执行。
- 任务需要**本库未覆盖的额外技能**（定制化高频技能都在上面）→ 到 Agent Base 技能库 `D:\Agent Base\skills/` 查找匹配技能，读取其 SKILL.md 按其步骤执行；Agent Base 也没有时再走 `find-skills` 生态查找。
- 未来新增子技能时，在此追加一行触发条件。

## 使用规则

1. 先完整读取对应子技能文件，再执行。
2. 一个任务涉及多个子技能时，按顺序依次使用。
3. 没有匹配的子技能时，按常规方式处理。
