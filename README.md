# BadWars

BadWars is a premium Next.js website and runtime status console for the BadWars loader.

## Stack

- Next.js App Router
- React + TypeScript
- Tailwind CSS
- Framer Motion
- GSAP-ready motion layer
- shadcn-style UI primitives
- Lucide Icons
- React Query
- Zod + React Hook Form
- next-themes

## Local Development

```bash
npm install
npm run dev
```

## Production

```bash
npm run build
npm start
```

## Environment

`DISCORD_WEBHOOK_URL` is used server-side by the Roblox status API to notify when Roblox client versions change.

## Key Routes

- `/` landing page
- `/dashboard` authenticated dashboard shell
- `/profile` profile shell
- `/downloads` download center
- `/changelog` changelog
- `/features` feature showcase
- `/settings` settings and validation demo
- `/admin` admin dashboard shell
- `/api/roblox/status` Roblox status API
- `/api/roblox/check` forced Roblox check
