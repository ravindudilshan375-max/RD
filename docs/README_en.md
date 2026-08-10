# AI Influencer Studio — English Documentation

A local-first web app for designing, managing, and generating AI influencers.
The frontend is React + Vite; image and video generation runs through your own
Higgsfield account (OAuth), and all of your data stays in your browser's
localStorage — nothing is stored on a server.

This file is the English documentation entry point for the `docs/` folder.
For the quick-start setup guide, see the [root README](../README.md).

---

## What the app does

- **Create influencers** with a multi-step wizard (`src/pages/Create.jsx`):
  identity, look, wardrobe, vibe, and backstory.
- **Content Studio & Video Studio** (`src/pages/Influencers.jsx`): generate
  on-brand photos and videos for each influencer.
- **Photo Studio** (`src/pages/PhotoStudio.jsx`): reference-driven editing —
  the influencer's identity photo (and optionally a wardrobe card) are passed
  as reference images and the prompt directs the edit.
- **Inspiration boards** and **Brand Deals** pages for planning content.
- **Settings**: connect your Higgsfield account (OAuth PKCE) and optionally
  supply an Anthropic API key for Claude-powered features.

## Supported generation models

| Model | Type | Notes |
|---|---|---|
| `soul_2` | Image | Uses a simplified pose set (`POSES_SOUL`) — struggles with detailed spatial pose instructions |
| `gpt_image_2` | Image | Main photorealism engine; resolution and quality parameters are both passed intentionally |
| `nano_banana_2` | Image | Fast image generation |
| `nano_banana_flash` | Image | Fastest image generation |
| `seedance_2_0` | Video | Talking, movement, and presence — see the Seedance guide below |

## Guides in this folder

| File | What it covers |
|---|---|
| [`gpt-image-2-engine.md`](./gpt-image-2-engine.md) | Prompt engineering for photorealistic influencer images on GPT Image 2 — skin realism, anti-beauty-filter framing, sectioned prompt format |
| [`photo-studio-influencer-guide.md`](./photo-studio-influencer-guide.md) | Photo Studio prompt strategy — reference-driven editing with `@image1` (identity) and `@image2` (outfit) |
| [`seedance-influencer-guide.md`](./seedance-influencer-guide.md) | Seedance 2.0 video prompting — dialogue, oners vs. multi-cut, camera headers, style anchors |

## Architecture overview

```
src/
  pages/           Routes: Landing, Influencers, Inspiration, BrandDeals,
                   Create, PhotoStudio, Settings, AuthCallback
  components/      Reusable UI: Nav, ImageGrid, MasonryGrid, Lightbox,
                   WardrobeDrawer
  context/         React contexts (theme — data-theme="dark|light" on <html>)
  utils/           Higgsfield API + OAuth, prompt builders, image helpers
  store.jsx        localStorage-backed React contexts + generateId()
api/               Vercel serverless functions:
                     hf/[...path].js  Higgsfield MCP proxy (forwards SSE)
                     claude.js        Anthropic proxy (caller supplies x-api-key)
                     img-proxy.js     Image proxy
docs/              Prompt engineering reference docs (this folder)
```

Key implementation files:

- `src/utils/higgsfieldAuth.js` — OAuth PKCE flow against `mcp.higgsfield.ai`
- `src/utils/higgsfieldGenerate.js` — generation requests, polling, media
  uploads; set `HF_DEBUG = true` at the top for verbose logs
- `src/utils/systemPrompt.js` — prompt templates: poses, wardrobe library,
  vibe palettes, Soul vs. GPT Image 2 variants

## Development

```bash
npm install
npm run dev          # http://localhost:5173
npm run build        # production build
npm run preview      # preview the production build locally
```

Requires Node.js 18 or newer. `vite.config.js` mirrors the `api/*` functions
as local dev proxies, so the dev server behaves the same as production on
Vercel.

## Deployment

The repo is Vercel-ready: connect it at vercel.com and it auto-detects Vite
plus the `api/` folder. No build-time API keys are needed — end users connect
their own Higgsfield account, and the Claude proxy expects the caller's own
`x-api-key` header.

---

Made by Dan Kieft.
