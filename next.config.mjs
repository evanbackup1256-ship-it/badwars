import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/** @type {import('next').NextConfig} */
const nextConfig = {
  poweredByHeader: false,
  reactStrictMode: true,
  // Disable optimizeCss experiment as it can sometimes leave non-critical CSS preloads
  // that trigger "preloaded CSS not used within a few seconds" warnings in Chrome.
  // The main CSS is still properly loaded via Next.js chunking.
  // experimental: { optimizeCss: true },
  turbopack: {
    // Explicit root to avoid "inferred workspace root" errors during build
    root: __dirname,
  },
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" }
        ]
      }
    ];
  }
};

export default nextConfig;
