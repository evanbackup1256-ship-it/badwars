"use client";

import Link from "next/link";
import Image from "next/image";
import { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import { useTheme } from "next-themes";
import { Activity, ArrowRight, CheckCircle2, ChevronRight, Copy, Download, GitBranch, Menu, Moon, Sun, X, Zap, Terminal, Shield, Cpu } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { buildLoader } from "@/lib/loader";
import { changelog, features, games, navItems, releases } from "@/lib/site-data";
import { formatRelativeTime } from "@/lib/utils";

type RobloxStatus = {
  ok: boolean;
  changed: boolean;
  version?: string;
  channel?: string;
  warning?: string;
  lastCheckedAt?: string;
};

type GitHubCommitInfo = {
  sha: string;
  shortSha: string;
  message: string;
  fallback: boolean;
};

function buildPageLoader(ref?: string) {
  const base = typeof window === "undefined" ? "https://badwars-production.up.railway.app" : window.location.origin;
  return ref ? buildLoader(base, ref) : buildLoader(base);
}

async function fetchRobloxStatus(): Promise<RobloxStatus> {
  const response = await fetch("/api/roblox/status", { cache: "no-store" });
  if (!response.ok) throw new Error("Unable to reach status service");
  return response.json();
}

async function fetchLatestCommit() {
  const response = await fetch("/api/github/latest", { cache: "no-store" });
  if (!response.ok) throw new Error("GitHub sync unavailable");
  return response.json() as Promise<GitHubCommitInfo>;
}

function copyLoader(loader: string, description = "Paste it once and read the status label.") {
  navigator.clipboard?.writeText(loader)
    .then(() => toast.success("Loader copied", { description }))
    .catch(() => toast.warning("Clipboard blocked", { description: "Select the loader text manually from the download center." }));
}

async function fetchLatestLoader() {
  const response = await fetch("/api/download/latest", { cache: "no-store" });
  if (!response.ok) throw new Error("Loader sync failed");
  return response.text();
}

async function copyLatestLoader() {
  try {
    copyLoader(await fetchLatestLoader(), "Synced from the latest GitHub commit.");
  } catch {
    copyLoader(buildPageLoader(), "GitHub sync fallback was copied.");
  }
}

export function SiteNav() {
  const [open, setOpen] = useState(false);
  const { theme, setTheme } = useTheme();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <header className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? "py-2" : "py-4"}`}>
      <div className="site-wrap">
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className={`flex h-14 items-center justify-between rounded-lg border border-primary/20 bg-card/90 px-6 backdrop-blur-xl transition-all ${scrolled ? "shadow-lg shadow-primary/10" : ""}`}
        >
          <Link className="flex items-center gap-3 group" href="/">
            <motion.div
              whileHover={{ rotate: 180, scale: 1.1 }}
              transition={{ duration: 0.6 }}
            >
              <Image src="/logo.svg" alt="BadWars" width={28} height={28} priority />
            </motion.div>
            <span className="font-display text-xl font-black tracking-tight">
              <span className="text-primary">BAD</span>
              <span className="text-foreground">WARS</span>
            </span>
          </Link>

          <nav className="hidden items-center gap-1 text-sm lg:flex">
            {navItems.slice(0, 5).map((item) => (
              <motion.div
                key={item.href}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <Link
                  href={item.href}
                  className="relative px-4 py-2 rounded-md text-muted-foreground hover:text-primary transition-colors group font-mono text-xs uppercase tracking-wider"
                >
                  <span className="relative z-10">{item.label}</span>
                  <div className="absolute inset-0 bg-primary/5 rounded-md opacity-0 group-hover:opacity-100 transition-opacity" />
                </Link>
              </motion.div>
            ))}
          </nav>

          <div className="flex items-center gap-3">
            <motion.button
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              className="p-2 rounded-md hover:bg-primary/10 transition-colors"
            >
              {theme === "dark" ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
            </motion.button>

            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
              <Button
                size="sm"
                className="hidden sm:flex gap-2 bg-primary hover:bg-primary/90 text-primary-foreground font-mono text-xs"
                onClick={copyLatestLoader}
              >
                <Copy className="h-3 w-3" />
                <span className="hidden md:inline">COPY LOADER</span>
              </Button>
            </motion.div>

            <button
              className="lg:hidden p-2 rounded-md hover:bg-primary/10 transition-colors"
              onClick={() => setOpen(!open)}
            >
              {open ? <X className="h-4 w-4" /> : <Menu className="h-4 w-4" />}
            </button>
          </div>
        </motion.div>

        <AnimatePresence>
          {open && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="mt-2 rounded-lg border border-primary/20 bg-card/95 backdrop-blur-xl p-4 lg:hidden"
            >
              <nav className="flex flex-col gap-2">
                {navItems.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className="flex items-center gap-3 rounded-md px-4 py-3 hover:bg-primary/10 transition-colors font-mono text-xs uppercase"
                    onClick={() => setOpen(false)}
                  >
                    {item.label}
                  </Link>
                ))}
              </nav>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </header>
  );
}

export function Footer() {
  return (
    <footer className="mt-24 border-t border-border">
      <div className="site-wrap py-12">
        <div className="grid gap-8 md:grid-cols-4">
          <div className="md:col-span-2">
            <Link href="/" className="flex items-center gap-3 mb-4">
              <Image src="/logo.svg" alt="BadWars" width={24} height={24} />
              <span className="font-display text-lg font-black">
                <span className="text-primary">BAD</span>
                <span className="text-foreground">WARS</span>
              </span>
            </Link>
              <p className="text-sm text-muted-foreground max-w-md font-mono">
              The Roblox loader console. Live status, one-click deployment, and full diagnostics.
            </p>
          </div>

          <div>
            <h3 className="font-semibold mb-4 font-mono text-xs uppercase tracking-wider text-primary">Navigation</h3>
            <ul className="space-y-2 text-sm text-muted-foreground">
              {navItems.map((item) => (
                <li key={item.href}>
                  <Link href={item.href} className="hover:text-primary transition-colors font-mono text-xs">
                    {item.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="font-semibold mb-4 font-mono text-xs uppercase tracking-wider text-primary">Resources</h3>
            <ul className="space-y-2 text-sm text-muted-foreground">
              <li>
                <a href="https://github.com/evanbackup1256-ship-it/badwars" target="_blank" rel="noopener noreferrer" className="hover:text-primary transition-colors flex items-center gap-2 font-mono text-xs">
                  <GitBranch className="h-3 w-3" /> GitHub
                </a>
              </li>
              <li>
                <Link href="/changelog" className="hover:text-primary transition-colors font-mono text-xs">
                  Changelog
                </Link>
              </li>
              <li>
                <Link href="/features" className="hover:text-primary transition-colors font-mono text-xs">
                  Features
                </Link>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-8 pt-8 border-t border-border flex flex-col sm:flex-row justify-between items-center gap-4 text-xs text-muted-foreground font-mono">
          <p>&copy; 2026 BadWars. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <span className="status-live">All systems operational</span>
          </div>
        </div>
      </div>
    </footer>
  );
}

export function LandingPage() {
  const roblox = useQuery({ queryKey: ["landing-roblox"], queryFn: fetchRobloxStatus, refetchInterval: 120_000 });
  const commit = useQuery({ queryKey: ["landing-commit"], queryFn: fetchLatestCommit, refetchInterval: 60_000 });

  return (
    <>
      <SiteNav />

      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center justify-center pt-20 pb-16 overflow-hidden hex-bg">
        <div className="site-wrap relative z-10">
          <div className="max-w-5xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="text-center mb-12"
            >
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-md border border-primary/30 bg-primary/5 mb-8 font-mono text-xs uppercase tracking-wider">
                <div className="h-2 w-2 rounded-full bg-primary animate-pulse" />
                <span className="text-primary">v19.0 Obsidian Overhaul</span>
              </div>

              <h1 className="font-display text-6xl md:text-7xl lg:text-8xl font-black tracking-tight mb-6">
                <span className="glitch-text text-primary" data-text="BADWARS">BADWARS</span>
              </h1>

              <p className="text-xl md:text-2xl text-muted-foreground mb-12 max-w-2xl mx-auto font-mono">
                The loader console for Roblox.
                <br />
                <span className="text-primary">Live status. One-click deploy. Full diagnostics.</span>
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="flex flex-col sm:flex-row gap-4 justify-center mb-16"
            >
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button
                  size="lg"
                  className="gap-2 px-8 py-6 text-base bg-primary hover:bg-primary/90 text-primary-foreground font-mono uppercase tracking-wider"
                  onClick={copyLatestLoader}
                >
                  <Copy className="h-4 w-4" />
                  Copy Loader
                  <ArrowRight className="h-4 w-4" />
                </Button>
              </motion.div>

              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button
                  size="lg"
                  variant="outline"
                  className="gap-2 px-8 py-6 text-base border-primary/30 hover:border-primary font-mono uppercase tracking-wider"
                  asChild
                >
                  <Link href="/downloads">
                    <Download className="h-4 w-4" />
                    Downloads
                  </Link>
                </Button>
              </motion.div>
            </motion.div>

            {/* Terminal-style status display */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="max-w-2xl mx-auto"
            >
              <div className="terminal">
                <div className="terminal-header">
                  <div className="terminal-dot red" />
                  <div className="terminal-dot yellow" />
                  <div className="terminal-dot green" />
                  <span className="ml-2 text-xs text-muted-foreground font-mono">badwars://status</span>
                </div>
                <div className="p-4 font-mono text-xs space-y-2">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">$ roblox_status</span>
                    <span className={roblox.data?.ok ? "text-success" : "text-warning"}>
                      {roblox.data?.ok ? "OPERATIONAL" : "CHECKING..."}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">$ latest_commit</span>
                    <span className="text-primary">{commit.data?.shortSha || "v19.0"}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">$ supported_games</span>
                    <span className="text-foreground">{games.length} routes active</span>
                  </div>
                  <div className="typing-cursor">
                    <span className="text-muted-foreground">$ </span>
                    <span className="text-primary">ready</span>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-24">
        <div className="site-wrap">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-md border border-primary/30 bg-primary/5 mb-6 font-mono text-xs uppercase tracking-wider">
              <Terminal className="h-3 w-3 text-primary" />
              <span className="text-primary">Architecture</span>
            </div>
            <h2 className="font-display text-4xl md:text-5xl font-black mb-4">
              How it works
            </h2>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto font-mono">
              Six subsystems handle execution, isolation, routing, diagnostics, detection, and interface.
            </p>
          </motion.div>

          <div className="grid gap-6 md:grid-cols-3">
            {[
              { icon: Zap, label: "One-Click Deploy", description: "Copy and paste the loader directly into your executor", color: "text-primary" },
              { icon: Activity, label: "Live Status", description: "Real-time Roblox update monitoring and alerts", color: "text-success" },
              { icon: Shield, label: "WindUI Interface", description: "Tabbed interface with seamless module controls and notification pipeline", color: "text-primary" },
            ].map((feature, i) => {
              const Icon = feature.icon;
              return (
                <motion.div
                  key={feature.label}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.1 }}
                >
                  <div className="neon-border rounded-lg p-6 h-full bg-card/50">
                    <div className={`inline-flex h-12 w-12 items-center justify-center rounded-md bg-primary/10 mb-4 ${feature.color}`}>
                      <Icon className="h-6 w-6" />
                    </div>
                    <h3 className="text-xl font-bold mb-2 font-display">{feature.label}</h3>
                    <p className="text-muted-foreground font-mono text-sm">{feature.description}</p>
                  </div>
                </motion.div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Games Section */}
      <section className="py-24 bg-card/30">
        <div className="site-wrap">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-md border border-primary/30 bg-primary/5 mb-6 font-mono text-xs uppercase tracking-wider">
              <Cpu className="h-3 w-3 text-primary" />
              <span className="text-primary">Route Inventory</span>
            </div>
            <h2 className="font-display text-4xl md:text-5xl font-black mb-4">
              {games.length} Games Mapped
            </h2>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto font-mono">
              Place ID resolution routes to nested module bundles.
            </p>
          </motion.div>

          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {games.slice(0, 6).map((game, i) => (
              <motion.div
                key={game.name}
                initial={{ opacity: 0, scale: 0.9 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.05 }}
              >
                <div className="neon-border rounded-lg p-6 bg-card/50">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <h3 className="font-bold text-lg mb-1 font-display">{game.name}</h3>
                      <p className="text-xs text-muted-foreground font-mono">{game.ids[0]}</p>
                    </div>
                    <Badge variant={game.status === "working" ? "success" : "warning"} className="font-mono text-xs">
                      {game.status}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground font-mono">
                    <ChevronRight className="h-3 w-3" />
                    <span>{game.description || "Full module support"}</span>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>

          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mt-12"
          >
            <Button variant="outline" size="lg" asChild className="border-primary/30 hover:border-primary font-mono uppercase">
              <Link href="/features">
                View All Features
                <ArrowRight className="h-4 w-4 ml-2" />
              </Link>
            </Button>
          </motion.div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24">
        <div className="site-wrap">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="relative overflow-hidden rounded-lg border border-primary/30 bg-card p-12 md:p-16 text-center neon-border"
          >
            <div className="relative z-10">
              <h2 className="font-display text-4xl md:text-5xl font-black mb-4">
                One Line. That's It.
              </h2>
              <p className="text-lg text-muted-foreground mb-8 max-w-xl mx-auto font-mono">
                Paste the loader into your executor. Cache, diagnostics, module bundles, and UI — handled.
                <br />
                <span className="text-primary">No accounts. No downloads. No setup.</span>
              </p>

              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button
                  size="lg"
                  className="gap-2 px-8 py-6 text-base bg-primary hover:bg-primary/90 text-primary-foreground font-mono uppercase tracking-wider"
                  onClick={copyLatestLoader}
                >
                  <Copy className="h-4 w-4" />
                  Copy Loader
                  <ArrowRight className="h-4 w-4" />
                </Button>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </section>

      <Footer />
    </>
  );
}
