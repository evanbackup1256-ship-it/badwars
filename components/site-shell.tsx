"use client";

import Link from "next/link";
import Image from "next/image";
import { useMemo, useState } from "react";
import Fuse from "fuse.js";
import { motion } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import { useTheme } from "next-themes";
import { Activity, Copy, Download, Menu, Moon, Sun, X } from "lucide-react";
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

  return (
    <header className="sticky top-4 z-50 site-wrap">
      <div className="glass flex h-16 items-center justify-between rounded-2xl border border-white/10 bg-card/95 px-4 backdrop-blur-2xl">
        <Link className="flex items-center gap-3 rounded-xl px-1 py-1 font-display text-2xl font-black tracking-[-1.5px]" href="/">
          <Image src="/logo.svg" alt="BadWars" width={36} height={36} priority />
          <span className="bg-gradient-to-r from-white to-white/80 bg-clip-text text-transparent">BadWars</span>
        </Link>

        <nav className="hidden items-center gap-1 text-sm lg:flex">
          {navItems.slice(0, 5).map((item) => (
            <Link 
              key={item.href} 
              href={item.href} 
              className="rounded-xl px-4 py-2 text-muted-foreground transition-colors hover:bg-white/5 hover:text-foreground"
            >
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <Button 
            aria-label="Toggle theme" 
            size="icon" 
            variant="ghost" 
            className="hidden md:inline-flex" 
            onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
          >
            <Sun className="h-4 w-4 dark:hidden" />
            <Moon className="hidden h-4 w-4 dark:block" />
          </Button>
          
          <Button asChild variant="ghost" className="hidden md:inline-flex text-sm">
            <Link href="/dashboard">Console</Link>
          </Button>

          <Button 
            onClick={() => void copyLatestLoader()} 
            className="bg-white text-black hover:bg-white/90 font-semibold px-5"
          >
            <Copy className="h-4 w-4 mr-1.5" /> Copy Loader
          </Button>

          <Button 
            aria-label="Open menu" 
            size="icon" 
            variant="ghost" 
            className="lg:hidden" 
            onClick={() => setOpen(!open)}
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </Button>
        </div>
      </div>

      {open && (
        <div className="glass mt-2 rounded-2xl border p-2 lg:hidden">
          {navItems.map((item) => (
            <Link 
              key={item.href} 
              href={item.href} 
              className="block rounded-xl px-4 py-2.5 text-sm text-muted-foreground hover:bg-white/5 hover:text-foreground" 
              onClick={() => setOpen(false)}
            >
              {item.label}
            </Link>
          ))}
          <Link href="/dashboard" className="block rounded-xl px-4 py-2.5 text-sm text-muted-foreground hover:bg-white/5 hover:text-foreground" onClick={() => setOpen(false)}>
            Dashboard
          </Link>
        </div>
      )}
    </header>
  );
}

export function LandingPage() {
  const status = useQuery({ queryKey: ["roblox-status"], queryFn: fetchRobloxStatus, refetchInterval: 120_000 });
  const commit = useQuery({ queryKey: ["latest-commit"], queryFn: fetchLatestCommit, retry: 1 });
  const loader = buildPageLoader(commit.data?.sha);

  return (
    <>
      <SiteNav />
      <main>
        {/* HERO - Premium redesign */}
        <section className="site-wrap pt-12 pb-16 lg:pt-16 lg:pb-20">
          <div className="grid items-center gap-12 lg:grid-cols-2">
            <div className="space-y-8">
              <div>
                <Badge className="mb-4" variant="secondary">
                  <Activity className="h-3.5 w-3.5 mr-1.5" /> Live since 2025
                </Badge>
                <h1 className="font-display text-6xl md:text-7xl lg:text-[82px] font-black tracking-[-3.5px] leading-[.9] text-balance">
                  The only<br />loader console<br />you&apos;ll ever need.
                </h1>
              </div>

              <p className="max-w-lg text-xl text-muted-foreground">
                Instant access to the freshest loader. Real-time Roblox version monitoring. 
                Every supported game route at your fingertips.
              </p>

              <div className="flex flex-wrap gap-3">
                <Button 
                  size="lg" 
                  className="h-12 px-8 text-base font-semibold"
                  onClick={() => copyLoader(loader, commit.data?.fallback ? "GitHub sync fallback was copied." : "Synced from the latest GitHub commit.")}
                >
                  <Copy className="h-4 w-4 mr-2" /> Copy Latest Loader
                </Button>
                <Button asChild size="lg" variant="outline" className="h-12 px-8 text-base">
                  <Link href="/downloads">
                    <Download className="h-4 w-4 mr-2" /> Downloads
                  </Link>
                </Button>
              </div>

              <div className="flex items-center gap-8 pt-2 text-sm">
                <div className="flex items-center gap-2 text-muted-foreground">
                  <div className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                  {status.data?.ok ? "Roblox stable" : "Checking Roblox"}
                </div>
                <div className="text-muted-foreground">Trusted by thousands of players</div>
              </div>
            </div>

            {/* Hero visual */}
            <div className="relative">
              <HeroConsole loader={loader} status={status.data} />
            </div>
          </div>
        </section>

        {/* Trust / Quick Stats */}
        <section className="site-wrap border-y py-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            <div>
              <div className="font-display text-4xl font-black tracking-tight text-primary">{games.length}</div>
              <div className="text-xs uppercase tracking-[1px] text-muted-foreground mt-1">Supported Games</div>
            </div>
            <div>
              <div className="font-display text-4xl font-black tracking-tight text-primary">300+</div>
              <div className="text-xs uppercase tracking-[1px] text-muted-foreground mt-1">Active Modules</div>
            </div>
            <div>
              <div className="font-display text-4xl font-black tracking-tight text-primary">99.9%</div>
              <div className="text-xs uppercase tracking-[1px] text-muted-foreground mt-1">Uptime</div>
            </div>
            <div>
              <div className="font-display text-4xl font-black tracking-tight text-primary">{commit.data?.shortSha || "LIVE"}</div>
              <div className="text-xs uppercase tracking-[1px] text-muted-foreground mt-1">Latest Commit</div>
            </div>
          </div>
        </section>

        <SearchSection />
        <HowItWorksSection />
        <GamesSection />
        <FeatureSection />
        <FAQSection />
      </main>
      <Footer />
    </>
  );
}

function HeroConsole({ loader, status }: { loader: string; status?: RobloxStatus }) {
  return (
    <div className="relative">
      <div className="rounded-3xl border bg-card/70 p-1 shadow-2xl backdrop-blur-xl">
        <Card className="border-0 bg-zinc-950 overflow-hidden">
          <CardHeader className="pb-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Badge variant={status?.changed ? "warning" : "success"}>
                  {status?.changed ? "Update detected" : "All systems nominal"}
                </Badge>
              </div>
              <span className="text-[10px] text-muted-foreground font-mono tabular-nums">
                {formatRelativeTime(status?.lastCheckedAt)}
              </span>
            </div>
            <CardTitle className="text-2xl tracking-tight">Live Loader</CardTitle>
            <CardDescription className="text-sm">
              {status?.warning || "Synced and ready. Paste into your executor."}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="mb-3 flex gap-3">
              <div className="rounded-lg border bg-black/60 px-3 py-1.5 text-xs">
                <div className="text-muted-foreground">Version</div>
                <div className="font-mono text-emerald-400 font-medium">{status?.version || "—"}</div>
              </div>
              <div className="rounded-lg border bg-black/60 px-3 py-1.5 text-xs">
                <div className="text-muted-foreground">Channel</div>
                <div className="font-mono font-medium">{status?.channel || "LIVE"}</div>
              </div>
            </div>

            <div className="rounded-xl border border-white/10 bg-black p-4 font-mono text-[11px] leading-relaxed text-emerald-300/90 overflow-auto max-h-[168px] shadow-inner">
              <pre className="whitespace-pre-wrap break-all select-all">{loader}</pre>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function SearchSection() {
  const [query, setQuery] = useState("");
  const items = useMemo(() => [
    ...features.map((item) => ({ type: "Feature", title: item.title, description: item.description })),
    ...games.map((item) => ({ type: "Game", title: item.name, description: `${item.description} ${item.ids.join(" ")}` })),
    ...releases.map((item) => ({ type: "Release", title: item.version, description: item.notes.join(" ") })),
    ...changelog.map((item) => ({ type: "Changelog", title: item.title, description: item.description }))
  ], []);
  const fuse = useMemo(() => new Fuse(items, { keys: ["title", "description", "type"], threshold: 0.34 }), [items]);
  const results = query ? fuse.search(query).slice(0, 5).map((entry) => entry.item) : items.slice(0, 4);

  return (
    <section className="site-wrap py-16" id="support">
      <div className="mb-8">
        <Badge variant="secondary">Universal Search</Badge>
        <h2 className="mt-4 font-display text-5xl font-black tracking-[-1.5px]">Find anything instantly.</h2>
        <p className="mt-2 max-w-md text-muted-foreground">Search games, features, releases, and support answers in one place.</p>
      </div>

      <div className="glass rounded-3xl border p-8">
        <Input 
          value={query} 
          onChange={(e) => setQuery(e.target.value)} 
          placeholder="Search BedWars, Roblox update, modules, 6872274481..." 
          className="h-14 text-lg mb-6 bg-background/50"
        />
        <div className="grid gap-3 md:grid-cols-2">
          {results.map((item, i) => (
            <div key={i} className="group rounded-2xl border bg-background/50 p-5 transition hover:border-primary/40 hover:bg-card">
              <div className="flex items-center justify-between">
                <Badge variant="muted" className="text-[10px]">{item.type}</Badge>
              </div>
              <div className="mt-3 font-display text-xl font-semibold tracking-tight group-hover:text-primary transition">{item.title}</div>
              <p className="mt-1.5 text-sm text-muted-foreground line-clamp-2">{item.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

function HowItWorksSection() {
  const steps = [
    { num: "01", title: "Copy the loader", desc: "Hit the big Copy button. The latest build is always pinned from GitHub." },
    { num: "02", title: "Paste & execute", desc: "Run it in your executor. The loader auto-detects your game and loads the right modules." },
    { num: "03", title: "Stay informed", desc: "The website and loader both watch Roblox versions so you never get surprised by an update." },
  ];

  return (
    <section className="site-wrap py-16 border-t" id="features">
      <div className="mb-10">
        <Badge>How it works</Badge>
        <h2 className="mt-4 font-display text-5xl font-black tracking-[-1.5px]">Three steps. Zero friction.</h2>
      </div>
      <div className="grid md:grid-cols-3 gap-6">
        {steps.map((step, index) => (
          <div key={index} className="group rounded-3xl border bg-card p-8 hover:border-primary/40 transition">
            <div className="font-mono text-sm text-primary/70 mb-3 tracking-[2px]">{step.num}</div>
            <div className="font-display text-3xl font-semibold tracking-tight mb-3">{step.title}</div>
            <p className="text-muted-foreground">{step.desc}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function FeatureSection() {
  return (
    <section className="site-wrap py-16" id="features">
      <div className="mb-8">
        <Badge>Why players choose BadWars</Badge>
        <h2 className="mt-4 font-display text-5xl font-black tracking-tight">Built for power users who hate friction.</h2>
      </div>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {features.map((feature, index) => {
          const Icon = feature.icon;
          return (
            <motion.div 
              initial={{ opacity: 0, y: 18 }} 
              whileInView={{ opacity: 1, y: 0 }} 
              viewport={{ once: true }} 
              transition={{ delay: index * 0.03 }} 
              key={feature.title}
            >
              <Card className="h-full border-white/10 hover:border-primary/30 transition group">
                <CardHeader className="pb-4">
                  <div className="h-11 w-11 rounded-2xl bg-primary/10 flex items-center justify-center mb-5 text-primary group-hover:bg-primary/15 transition">
                    <Icon className="h-5 w-5" />
                  </div>
                  <CardTitle className="text-2xl tracking-tight">{feature.title}</CardTitle>
                  <CardDescription className="text-[15px] leading-relaxed mt-1.5">{feature.description}</CardDescription>
                </CardHeader>
              </Card>
            </motion.div>
          );
        })}
      </div>
    </section>
  );
}

function GamesSection() {
  return (
    <section className="site-wrap py-16" id="games">
      <div className="flex items-end justify-between mb-8">
        <div>
          <Badge>Game Routes</Badge>
          <h2 className="mt-3 font-display text-5xl font-black tracking-[-1.5px]">Full coverage across the games you actually play.</h2>
        </div>
        <Button asChild variant="outline" className="hidden md:flex">
          <Link href="/downloads">Browse all</Link>
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {games.map((game, index) => (
          <GameCard game={game} key={index} />
        ))}
      </div>
    </section>
  );
}

function GameCard({ game }: { game: (typeof games)[number] }) {
  return (
    <div className="group rounded-3xl border bg-card p-7 transition hover:border-primary/40 flex flex-col">
      <div className="flex justify-between items-start">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <div className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: game.tone }} />
            <Badge variant={game.status === "testing" ? "warning" : "success"} className="uppercase text-[10px] tracking-widest">
              {game.status}
            </Badge>
          </div>
          <h3 className="font-display text-3xl font-semibold tracking-tight">{game.name}</h3>
        </div>
        <div className="text-right">
          <div className="font-mono text-3xl font-black text-primary/80">{game.modules}</div>
          <div className="text-[10px] text-muted-foreground -mt-1">MODULES</div>
        </div>
      </div>

      <p className="mt-4 text-muted-foreground flex-1 text-[15px] leading-snug">{game.description}</p>

      <div className="mt-6 pt-6 border-t flex flex-wrap gap-2 text-xs">
        {game.ids.slice(0, 2).map(id => (
          <div key={id} className="px-2.5 py-1 rounded bg-muted font-mono text-muted-foreground">{id}</div>
        ))}
        <Button size="sm" variant="ghost" className="ml-auto h-7 px-3 text-xs" onClick={() => void copyLatestLoader()}>
          <Copy className="h-3.5 w-3.5 mr-1" /> Copy Route
        </Button>
      </div>
    </div>
  );
}



function FAQSection() {
  const faqs = [
    { q: "Which loader should I copy?", a: "Always use the latest commit. It includes the freshest modules and real-time Roblox status integration." },
    { q: "What happens on a Roblox update?", a: "The status page turns yellow. Your loader will usually still work, but test game-specific features immediately." },
    { q: "What should I send when something breaks?", a: "Send the visible status label from the loader + the Place ID + any error from the console." },
    { q: "Is this only for certain games?", a: "No. Universal base always loads first, and we have deep coverage on the most popular experiences." },
  ];

  return (
    <section className="site-wrap py-16 border-t" id="documentation">
      <div className="mb-8">
        <Badge>FAQ</Badge>
        <h2 className="mt-4 font-display text-5xl font-black tracking-[-1.5px]">Common questions, straight answers.</h2>
      </div>
      <div className="grid gap-3 md:grid-cols-2">
        {faqs.map((item, i) => (
          <div key={i} className="rounded-3xl border p-7 bg-card/50">
            <div className="font-semibold text-lg mb-2">{item.q}</div>
            <p className="text-muted-foreground">{item.a}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

export function Footer() {
  return (
    <footer className="border-t bg-card/40 mt-12">
      <div className="site-wrap flex flex-col md:flex-row items-start md:items-center justify-between gap-y-4 py-10 text-sm text-muted-foreground">
        <div className="flex items-center gap-4">
          <Image src="/logo.svg" alt="BadWars" width={32} height={32} />
          <div>
            <div className="font-semibold text-foreground">BadWars</div>
            <div className="text-xs">Premium Roblox loader console</div>
          </div>
        </div>
        <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs">
          <Link href="/changelog" className="hover:text-foreground">Changelog</Link>
          <Link href="/downloads" className="hover:text-foreground">Downloads</Link>
          <Link href="/dashboard" className="hover:text-foreground">Dashboard</Link>
          <a href="https://github.com/evanbackup1256-ship-it/badwars" target="_blank" className="hover:text-foreground">GitHub</a>
        </div>
        <div className="text-[10px] text-muted-foreground/60">© {new Date().getFullYear()} BadWars. All rights reserved.</div>
      </div>
    </footer>
  );
}
