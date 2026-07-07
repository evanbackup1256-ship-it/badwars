import type { Metadata, Viewport } from "next";
import { Inter, JetBrains_Mono, Space_Grotesk } from "next/font/google";
import "./globals.css";
import { Providers } from "@/components/providers";

const inter = Inter({ 
  subsets: ["latin"], 
  variable: "--font-sans",
  display: "swap",
  preload: false,  // disable preload to avoid "preloaded CSS not used" browser warnings; display:swap handles FOUT
});
const spaceGrotesk = Space_Grotesk({ 
  subsets: ["latin"], 
  variable: "--font-display",
  display: "swap",
  preload: false,
});
// mono is only for code blocks, not critical on initial render
const jetbrainsMono = JetBrains_Mono({ 
  subsets: ["latin"], 
  variable: "--font-mono",
  display: "swap",
  preload: false,
});

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || "https://badwars-production.up.railway.app"),
  title: {
    default: "BadWars — Premium Roblox Loader Console",
    template: "%s • BadWars"
  },
  description: "The premium loader console. Live Roblox status, one-click latest loader, full game routing, and professional diagnostics. In-game UI now powered by WindUI (tabs, notifications, seamless module controls).",
  icons: {
    icon: "/logo.svg"
  },
  openGraph: {
    title: "BadWars",
    description: "Copy the newest loader. Know when Roblox updates. Every supported route, instantly.",
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
