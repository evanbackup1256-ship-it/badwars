# Deployment Guide

## Local

```bash
npm install
npm run dev
```

## Production

```bash
npm run build
npm start
```

## Railway

Railway should use Nixpacks with:

- Build command: `npm run build`
- Start command: `npm start`

Environment variables:

- `DISCORD_WEBHOOK_URL`: private Discord webhook for Roblox update alerts.
- `NEXT_PUBLIC_SITE_URL`: optional canonical public URL.
