"use client";

import Link from "next/link";
import Image from "next/image";
import { useMemo, useState, useEffect } from "react";
import Fuse from "fuse.js";
import { motion, AnimatePresence } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import { useTheme } from "next-themes";
import { Activity, ArrowRight, CheckCircle2, ChevronRight, Copy, Download, GitBranch, Menu, Moon, Sparkles, Sun, X, Zap } from "lucide-react";
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
          className={`glass flex h-16 items-center justify-between rounded-2xl px-6 transition-all ${scrolled ? "shadow-2xl shadow-primary/10" : ""}`}
        >
          <Link className="flex items-center gap-3 group" href="/">
            <motion.div
              whileHover={{ rotate: 180, scale: 1.1 }}
              transition={{ duration: 0.6 }}
            >
              <Image src="/logo.svg" alt="BadWars" width={36} height={36} priority />
            </motion.div>
            <span className="font-display text-2xl font-black tracking-tight">
              <span className="gradient-text">BadWars</span>
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
                  className="relative px-4 py-2 rounded-xl text-muted-foreground hover:text-foreground transition-colors group"
                >
                  <span className="relative z-10">{item.label}</span>
                  <div className="absolute inset-0 bg-primary/10 rounded-xl opacity-0 group-hover:opacity-100 transition-opacity" />
                </Link>
              </motion.div>
            ))}
          </nav>

          <div className="flex items-center gap-3">
            <motion.button
              whileHover={{ scale: 1.1, rotate: 180 }}
              whileTap={{ scale: 0.9 }}
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
              className="p-2 rounded-xl hover:bg-primary/10 transition-colors"
            >
              {theme === "dark" ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
            </motion.button>

            <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
              <Button 
                size="sm" 
                className="hidden sm:flex gap-2 bg-gradient-to-r from-primary to-secondary hover:from-primary/90 hover:to-secondary/90"
                onClick={copyLatestLoader}
              >
                <Copy className="h-4 w-4" />
                <span className="hidden md:inline">Copy Loader</span>
              </Button>
            </motion.div>

            <button
              className="lg:hidden p-2 rounded-xl hover:bg-primary/10 transition-colors"
              onClick={() => setOpen(!open)}
            >
              {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
            </button>
          </div>
        </motion.div>

        <AnimatePresence>
          {open && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="glass mt-2 rounded-2xl p-4 lg:hidden"
            >
              <nav className="flex flex-col gap-2">
                {navItems.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className="flex items-center gap-3 rounded-xl px-4 py-3 hover:bg-primary/10 transition-colors"
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
    <footer className="mt-24 border-t border-border/50">
      <div className="site-wrap py-12">
        <div className="grid gap-8 md:grid-cols-4">
          <div className="md:col-span-2">
            <Link href="/" className="flex items-center gap-3 mb-4">
              <Image src="/logo.svg" alt="BadWars" width={32} height={32} />
              <span className="font-display text-xl font-black gradient-text">BadWars</span>
            </Link>
            <p className="text-sm text-muted-foreground max-w-md">
              The premium Roblox loader console. Live status, one-click deployment, and professional diagnostics.
            </p>
          </div>

          <div>
            <h3 className="font-semibold mb-4">Navigation</h3>
            <ul className="space-y-2 text-sm text-muted-foreground">
              {navItems.map((item) => (
                <li key={item.href}>
                  <Link href={item.href} className="hover:text-foreground transition-colors">
                    {item.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="font-semibold mb-4">Resources</h3>
            <ul className="space-y-2 text-sm text-muted-foreground">
              <li>
                <a href="https://github.com/evanbackup1256-ship-it/badwars" target="_blank" rel="noopener noreferrer" className="hover:text-foreground transition-colors flex items-center gap-2">
                  <GitBranch className="h-4 w-4" /> GitHub
                </a>
              </li>
              <li>
                <Link href="/changelog" className="hover:text-foreground transition-colors">
                  Changelog
                </Link>
              </li>
              <li>
                <Link href="/features" className="hover:text-foreground transition-colors">
                  Features
                </Link>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-8 pt-8 border-t border-border/50 flex flex-col sm:flex-row justify-between items-center gap-4 text-sm text-muted-foreground">
          <p>&copy; 2026 BadWars. All rights reserved.</p>
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-2">
              <div className="h-2 w-2 rounded-full bg-success animate-pulse" />
              All systems operational
            </span>
          </div>
        </div>
      </div>
    </footer>
  );
}

export function LandingPage() {
  const roblox = useQuery({ queryKey: ["landing-roblox"], queryFn: fetchRobloxStatus, refetchInterval: 120_000 });
  const commit = useQuery({ queryKey: ["landing-commit"], queryFn: fetchLatestCommit, refetchInterval: 60_000 });

  const heroFeatures = [
    { icon: Zap, label: "One-Click Deploy", description: "Copy and paste the loader directly into your executor" },
    { icon: Activity, label: "Live Status", description: "Real-time Roblox update monitoring and alerts" },
    { icon: CheckCircle2, label: "Premium UI", description: "WindUI-powered interface with seamless module controls" },
  ];

  return (
    <>
      <SiteNav />

      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center justify-center pt-24 pb-16 overflow-hidden">
        {/* Animated orbs */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <motion.div
            animate={{
              x: [0, 100, 0],
              y: [0, -50, 0],
            }}
            transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
            className="absolute top-1/4 left-1/4 w-96 h-96 bg-primary/20 rounded-full blur-3xl"
          />
          <motion.div
            animate={{
              x: [0, -100, 0],
              y: [0, 100, 0],
            }}
            transition={{ duration: 25, repeat: Infinity, ease: "linear" }}
            className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-secondary/20 rounded-full blur-3xl"
          />
        </div>

        <div className="site-wrap relative z-10">
          <div className="max-w-4xl mx-auto text-center">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
            >
              <Badge className="mb-6 px-4 py-2 text-sm bg-primary/10 border-primary/30 text-primary">
                <Sparkles className="h-4 w-4 mr-2" />
                v19.0 Obsidian Overhaul
              </Badge>
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.1 }}
              className="font-display text-6xl md:text-7xl lg:text-8xl font-black tracking-tight mb-6"
            >
              The Premium
              <br />
              <span className="gradient-text">Loader Console</span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="text-xl md:text-2xl text-muted-foreground mb-12 max-w-2xl mx-auto"
            >
              Live Roblox status, one-click deployment, and professional diagnostics. 
              Powered by WindUI for seamless in-game control.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.3 }}
              className="flex flex-col sm:flex-row gap-4 justify-center"
            >
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button 
                  size="lg" 
                  className="gap-2 px-8 py-6 text-lg bg-gradient-to-r from-primary to-secondary hover:from-primary/90 hover:to-secondary/90 shadow-2xl shadow-primary/25"
                  onClick={copyLatestLoader}
                >
                  <Copy className="h-5 w-5" />
                  Copy Loader
                  <ArrowRight className="h-5 w-5" />
                </Button>
              </motion.div>

              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button 
                  size="lg" 
                  variant="outline" 
                  className="gap-2 px-8 py-6 text-lg border-2"
                  asChild
                >
                  <Link href="/downloads">
                    <Download className="h-5 w-5" />
                    Download Center
                  </Link>
                </Button>
              </motion.div>
            </motion.div>

            {/* Status indicators */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ duration: 0.6, delay: 0.5 }}
              className="mt-16 flex flex-wrap justify-center gap-6 text-sm"
            >
              <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-card/50 border border-border/50">
                <div className={`h-2 w-2 rounded-full ${roblox.data?.ok ? "bg-success" : "bg-warning"} animate-pulse`} />
                <span className="text-muted-foreground">Roblox:</span>
                <span className="font-semibold">{roblox.data?.ok ? "Operational" : "Checking"}</span>
              </div>

              <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-card/50 border border-border/50">
                <div className="h-2 w-2 rounded-full bg-primary animate-pulse" />
                <span className="text-muted-foreground">Latest:</span>
                <span className="font-semibold font-mono">{commit.data?.shortSha || "v19.0"}</span>
              </div>

              <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-card/50 border border-border/50">
                <div className="h-2 w-2 rounded-full bg-accent animate-pulse" />
                <span className="text-muted-foreground">Games:</span>
                <span className="font-semibold">{games.length} Supported</span>
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
            <Badge className="mb-4">Why BadWars</Badge>
            <h2 className="font-display text-4xl md:text-5xl font-black mb-4">
              Everything You Need
            </h2>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              A complete loader solution with live monitoring, premium UI, and seamless deployment.
            </p>
          </motion.div>

          <div className="grid gap-6 md:grid-cols-3">
            {heroFeatures.map((feature, i) => {
              const Icon = feature.icon;
              return (
                <motion.div
                  key={feature.label}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.1 }}
                >
                  <Card className="premium-card h-full p-6">
                    <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-primary/20 to-secondary/20 mb-4">
                      <Icon className="h-6 w-6 text-primary" />
                    </div>
                    <h3 className="text-xl font-bold mb-2">{feature.label}</h3>
                    <p className="text-muted-foreground">{feature.description}</p>
                  </Card>
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
            <Badge className="mb-4">Supported Games</Badge>
            <h2 className="font-display text-4xl md:text-5xl font-black mb-4">
              {games.length} Games Ready
            </h2>
            <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
              Full compatibility with the most popular Roblox experiences.
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
                <Card className="premium-card p-6">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <h3 className="font-bold text-lg mb-1">{game.name}</h3>
                      <p className="text-sm text-muted-foreground font-mono">{game.ids[0]}</p>
                    </div>
                    <Badge variant={game.status === "working" ? "success" : "warning"}>
                      {game.status}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <ChevronRight className="h-4 w-4" />
                    <span>{game.description || "Full module support"}</span>
                  </div>
                </Card>
              </motion.div>
            ))}
          </div>

          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            viewport={{ once: true }}
            className="text-center mt-12"
          >
            <Button variant="outline" size="lg" asChild>
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
            className="relative overflow-hidden rounded-3xl border border-primary/30 bg-gradient-to-br from-primary/10 via-card to-secondary/10 p-12 md:p-16 text-center"
          >
            <div className="absolute inset-0 bg-grid-white/5 [mask-image:radial-gradient(ellipse_at_center,black_50%,transparent_100%)]" />
            
            <div className="relative z-10">
              <h2 className="font-display text-4xl md:text-5xl font-black mb-4">
                Ready to Deploy?
              </h2>
              <p className="text-lg text-muted-foreground mb-8 max-w-xl mx-auto">
                Copy the loader now and get started in seconds. No accounts, no downloads, no hassle.
              </p>
              
              <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
                <Button 
                  size="lg" 
                  className="gap-2 px-8 py-6 text-lg bg-gradient-to-r from-primary to-secondary hover:from-primary/90 hover:to-secondary/90 shadow-2xl shadow-primary/25"
                  onClick={copyLatestLoader}
                >
                  <Copy className="h-5 w-5" />
                  Copy Loader Now
                  <ArrowRight className="h-5 w-5" />
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
