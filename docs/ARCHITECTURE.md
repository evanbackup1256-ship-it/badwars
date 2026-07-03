# BadWars Website Architecture

BadWars is now a Next.js App Router application with React, TypeScript, Tailwind CSS, Framer Motion, React Query, Zod, React Hook Form, next-themes, shadcn-style components, and Lucide icons.

## Structure

- `app/` contains pages, layouts, API route handlers, and error surfaces.
- `components/` contains shared UI primitives and product pages.
- `lib/` contains data, utilities, and Roblox status integration.
- `public/` contains static assets such as the logo.

## Runtime

Railway runs `npm start`, which serves the production Next app after `npm run build`.

## APIs

- `/api/health` returns service health.
- `/api/roblox/status` returns cached Roblox client status.
- `/api/roblox/check` forces a fresh Roblox check and dispatches the Discord webhook when the version changes.

The Discord webhook is read from `DISCORD_WEBHOOK_URL` and must stay server-side.
