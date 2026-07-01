---
title: "Hugo Premium Project Skeleton"
date: 2026-06-15T15:20:00+08:00
draft: false
description: "基於 Hugo v0.163.3 打造的現代化、極簡且美觀的靜態網站空殼專案"
---

## 歡迎使用您的 Hugo 專案

這個專案空殼已經為您準備好了所有的基本設定，您可以立即開始撰寫內容。

### 專案特色

1. **環境自動設定**：不需要手動安裝設定 Go 環境與下載 Hugo 執行檔，直接執行 `bash setup.sh` 即可一鍵完成。
2. **精美的視覺系統**：預設採用深色科技風設計，整合毛玻璃效果（Glassmorphism）、漸層色彩與流暢的微動畫，為使用者帶來極佳的第一印象。
3. **CDN 部署友好**：配置了 `relativeURLs = true`，使生成的所有靜態檔案在部署到任何 CDN（如 Netlify, Cloudflare Pages, GitHub Pages 或 AWS S3）時都能完美運作，不會因為域名配置而導致 CSS 或 JS 路徑錯誤。
4. **專案獨立化**：Hugo 執行檔會下載至專案根目錄的 `bin/` 底下，不會污染您的全域環境，並在 `package.json` 中配置好了 npm scripts 便於您的工作流整合。

### 撰寫新內容

要建立新的文章，可以使用以下命令：

```bash
./bin/hugo new posts/my-first-post.md
```

這會在 `content/posts/` 目錄下建立一個包含預設前言（Front Matter）的 Markdown 檔案。
