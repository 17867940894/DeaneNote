// 将 content/ 下 Markdown 中的相对图片路径规范化为“仓库根相对路径”，
// 使 Quartz（shortest 链接策略）能正确解析任意层级的图片；源笔记仓库不受影响。
// 用法: node scripts/normalize-images.mjs [contentDir]
import { readFileSync, writeFileSync, readdirSync, statSync } from "node:fs"
import { join, dirname, relative, resolve, sep } from "node:path"

const root = resolve(process.argv[2] ?? "content")
const IMG_EXT = new Set([".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"])

function walk(dir) {
  const out = []
  for (const entry of readdirSync(dir)) {
    const p = join(dir, entry)
    if (statSync(p).isDirectory()) out.push(...walk(p))
    else out.push(p)
  }
  return out
}

function toPosix(p) {
  return p.split(sep).join("/")
}

function vaultPath(abs) {
  return toPosix(relative(root, abs))
}

function fileExists(abs) {
  try {
    return statSync(abs).isFile()
  } catch {
    return false
  }
}

const all = walk(root)
const mdFiles = all.filter((p) => p.endsWith(".md"))
const imageFiles = all.filter((p) => IMG_EXT.has(extname(p)))
const byName = new Map()
for (const p of imageFiles) {
  const name = p.split(sep).pop()
  if (!byName.has(name)) byName.set(name, [])
  byName.get(name).push(p)
}

function extname(p) {
  const i = p.lastIndexOf(".")
  return i < 0 ? "" : p.slice(i).toLowerCase()
}

function resolveRelative(fromDir, url) {
  const clean = url.split(/[?#]/)[0]
  if (!clean) return null
  // url 可能以 ./ ../ 开头或直接是文件名
  return resolve(fromDir, clean)
}

function rewriteFile(mdPath) {
  const dir = dirname(mdPath)
  const lines = readFileSync(mdPath, "utf8").split("\n")
  let inFence = false
  let changed = false

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    if (/^\s*(```|~~~)/.test(line)) {
      inFence = !inFence
      continue
    }
    if (inFence) continue

    // 1) Markdown 图片: ![alt](path)
    const newLine = line.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, (m, alt, url) => {
      const u = url.trim()
      if (/^(https?:|data:|#)/i.test(u)) return m
      const abs = resolveRelative(dir, u)
      if (!abs || !fileExists(abs) || !IMG_EXT.has(extname(abs))) return m
      const vp = vaultPath(abs)
      if (vp === u) return m
      changed = true
      return `![${alt}](${vp})`
    })

    // 2) Obsidian 图片 wikilink: ![[img.png]] / ![[img.png|alt]]
    const newLine2 = newLine.replace(/!\[\[([^\]|]+\.(?:png|jpe?g|gif|webp|svg))(?:\|([^\]]*))?\]\]/gi, (m, name, alt) => {
      const matches = byName.get(name)
      if (!matches || matches.length !== 1) return m
      const vp = vaultPath(matches[0])
      changed = true
      return alt ? `![[${vp}|${alt}]]` : `![[${vp}]]`
    })

    lines[i] = newLine2
  }

  if (changed) {
    writeFileSync(mdPath, lines.join("\n"))
    return true
  }
  return false
}

let rewritten = 0
for (const md of mdFiles) {
  if (rewriteFile(md)) rewritten++
}
console.log(`normalized images in ${rewritten}/${mdFiles.length} markdown files`)
