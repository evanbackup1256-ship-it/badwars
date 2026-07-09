import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono, Space_Grotesk } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/providers";

const inter = Inter({ 
  subsets: ["latin"], 
  variable: "--font-sans",
  display: "swap",
  preload: false,
});
const spaceGrotesk = Space_Grotesk({ 
  subsets: ["latin"], 
  variable: "--font-display",
  display: "swap",
  preload: false,
});
const jetbrainsMono = JetBrains_Mono({ 
  subsets: ["latin"], 
  variable: "--font-mono",
  display: "swap",
  preload: false,
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "https://badwars-production.up.railway.app"),
  title: {
    default: "BadWars — Roblox Loader Console",
    template: "%s — BadWars"
  },
  description: "Loader console for Roblox. Route-aware module bundles, executor fingerprinting, and a WindUI interface. Live status, one-click deploy, full game routing.",
  icons: {
    icon: "/logo.svg"
  },
  openGraph: {
    title: "BadWars",
    description: "Loader console for Roblox. Route-aware module bundles, executor fingerprinting, and a WindUI interface.",
    images: [{ url: "/logo.svg" }],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  themeColor: "#07111f"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${inter.variable} ${spaceGrotesk.variable} ${jetbrainsMono.variable} antialiased`}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
