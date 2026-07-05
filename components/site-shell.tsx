"use client";

import Link from "next/link";
import Image from "next/image";
import { useMemo, useState } from "react";
import Fuse from "fuse.js";
import { motion } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import { useTheme } from "next-themes";
import { Activity, Copy, Download, Gauge, Menu, Moon, Search, ShieldCheck, Sun, Terminal, X } from "lucide-react";
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
    <header className="sticky top-3 z-50 site-wrap">
      <div className="glass flex min-h-16 items-center justify-between rounded-2xl border px-3 shadow-premium">
        <Link className="flex items-center gap-3 rounded-xl px-2 py-2 font-display text-xl font-black" href="/">
          <Image src="/logo.svg" alt="BadWars" width={38} height={38} priority />
          <span>BadWars</span>
        </Link>
        <nav className="hidden items-center gap-1 lg:flex">
          {navItems.map((item) => <Link className="rounded-xl px-3 py-2 text-sm text-muted-foreground transition hover:bg-muted hover:text-foreground" href={item.href} key={item.href}>{item.label}</Link>)}
        </nav>
        <div className="flex items-center gap-2">
          <Button aria-label="Toggle theme" size="icon" variant="outline" onClick={() => setTheme(theme === "dark" ? "light" : "dark")}>
            <Sun className="h-4 w-4 dark:hidden" />
            <Moon className="hidden h-4 w-4 dark:block" />
          </Button>
          <Button asChild className="hidden md:inline-flex" variant="outline"><Link href="/dashboard">Status</Link></Button>
          <Button onClick={() => void copyLatestLoader()}><Copy className="h-4 w-4" /> Copy</Button>
          <Button aria-label="Open menu" className="lg:hidden" size="icon" variant="ghost" onClick={() => setOpen((value) => !value)}>{open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}</Button>
        </div>
      </div>
      {open ? (
        <div className="glass mt-2 grid gap-1 rounded-2xl border p-2 lg:hidden">
          {navItems.map((item) => <Link className="rounded-xl px-3 py-2 text-sm text-muted-foreground hover:bg-muted hover:text-foreground" href={item.href} key={item.href} onClick={() => setOpen(false)}>{item.label}</Link>)}
          <Link className="rounded-xl px-3 py-2 text-sm text-muted-foreground hover:bg-muted hover:text-foreground" href="/dashboard" onClick={() => setOpen(false)}>Status console</Link>
        </div>
      ) : null}
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
        <section className="site-wrap grid gap-10 py-14 lg:min-h-[calc(100vh-92px)] lg:grid-cols-[1.02fr_.98fr] lg:items-center">
          <motion.div initial={{ opacity: 0, y: 24 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7 }} className="space-y-7">
            <Badge><Activity className="h-3.5 w-3.5" /> Live route console</Badge>
            <div className="space-y-5">
              <h1 className="max-w-5xl font-display text-5xl font-black leading-[.94] md:text-7xl xl:text-8xl">BadWars launch console.</h1>
              <p className="max-w-2xl text-lg text-muted-foreground">Copy the pinned loader, check update risk, inspect supported routes, and get useful failure context before a support thread starts.</p>
            </div>
            <div className="flex flex-wrap gap-3">
              <Button size="lg" onClick={() => copyLoader(loader, commit.data?.fallback ? "GitHub sync fallback was copied." : "Synced from the latest GitHub commit.")}><Copy className="h-5 w-5" /> Copy Latest Loader</Button>
              <Button asChild size="lg" variant="outline"><Link href="/downloads"><Download className="h-5 w-5" /> Open Download Center</Link></Button>
            </div>
            <div className="grid gap-3 sm:grid-cols-3">
              <Stat label="GitHub Sync" value={commit.data?.shortSha || (commit.isLoading ? "syncing" : "fallback")} detail={commit.data?.message || "latest loader source"} />
              <Stat label="Roblox Watch" value={status.data?.changed ? "warning" : status.data?.ok ? "steady" : "checking"} detail={status.data?.version || "Railway status"} />
              <Stat label="Runtime" value="keyless" detail="copy, paste, read status" />
            </div>
          </motion.div>
          <HeroConsole loader={loader} status={status.data} />
        </section>
        <SearchSection />
        <FeatureSection />
        <GamesSection />
        <ModuleMatrixSection />
        <OpsSection />
        <FAQSection />
      </main>
      <Footer />
    </>
  );
}

function Stat({ label, value, detail }: { label: string; value: string; detail: string }) {
  return (
    <Card className="p-5">
      <div className="text-xs font-bold uppercase text-muted-foreground">{label}</div>
      <div className="mt-2 font-display text-2xl font-black text-primary">{value}</div>
      <div className="mt-1 truncate text-xs text-muted-foreground">{detail}</div>
    </Card>
  );
}

function HeroConsole({ loader, status }: { loader: string; status?: RobloxStatus }) {
  return (
    <motion.div initial={{ opacity: 0, y: 24, rotateY: -7 }} animate={{ opacity: 1, y: 0, rotateY: -7 }} transition={{ duration: 0.75, delay: 0.1 }} className="orbital-card">
      <Card className="hero-grid overflow-hidden">
        <CardHeader>
          <div className="flex items-center justify-between gap-3">
            <Badge variant={status?.changed ? "warning" : "success"}>{status?.changed ? "Roblox warning" : "Roblox steady"}</Badge>
            <span className="text-xs text-muted-foreground">{formatRelativeTime(status?.lastCheckedAt)}</span>
          </div>
          <CardTitle className="text-3xl">Live loader workspace</CardTitle>
          <CardDescription>{status?.warning || "Loader, version watch, and game routing are ready."}</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-3 md:grid-cols-2">
            <MiniPanel title="Current channel" value={status?.channel || "LIVE"} />
            <MiniPanel title="Roblox version" value={status?.version || "checking"} />
          </div>
          <div className="mt-4 rounded-2xl border bg-black/70 p-4 font-mono text-xs text-emerald-100 shadow-inner">
            <pre className="code-scroll whitespace-pre-wrap break-words">{loader}</pre>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}

function MiniPanel({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-2xl border bg-background/45 p-4">
      <div className="text-xs font-bold uppercase text-muted-foreground">{title}</div>
      <div className="mt-2 overflow-hidden text-ellipsis font-display text-xl font-black">{value}</div>
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
  const results = query ? fuse.search(query).slice(0, 6).map((entry) => entry.item) : items.slice(0, 4);

  return (
    <section className="site-wrap py-10" id="support">
      <div className="rounded-lg border bg-card/70 p-6 shadow-premium backdrop-blur-xl">
        <div className="mb-5">
          <Badge variant="secondary"><Search className="h-3.5 w-3.5" /> Fuzzy search</Badge>
          <h2 className="mt-3 font-display text-3xl font-black md:text-5xl">Find routes, releases, and answers fast.</h2>
        </div>
          <Input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search BedWars, Roblox warning, checksum, version 2.0..." />
          <div className="mt-4 grid gap-3 md:grid-cols-2">
            {results.map((item) => (
              <div className="rounded-lg border bg-background/45 p-4" key={`${item.type}-${item.title}`}>
                <Badge variant="muted">{item.type}</Badge>
                <div className="mt-3 font-display text-lg font-black">{item.title}</div>
                <p className="mt-1 text-sm text-muted-foreground">{item.description}</p>
              </div>
            ))}
          </div>
      </div>
    </section>
  );
}

function FeatureSection() {
  return (
        <section className="site-wrap py-16" id="features">
      <SectionHead badge="Feature highlights" title="Built like a launcher, not a link page." description="Motion-safe panels, live data, copy UX, theme support, clean routing, and readable failure context." />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {features.map((feature, index) => {
          const Icon = feature.icon;
          return (
            <motion.div initial={{ opacity: 0, y: 18 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} transition={{ delay: index * 0.04 }} key={feature.title}>
              <Card className="group h-full overflow-hidden transition hover:-translate-y-1 hover:border-primary/60">
                <CardHeader>
                  <div className="grid h-12 w-12 place-items-center rounded-2xl bg-primary/15 text-primary transition group-hover:shadow-glow"><Icon className="h-5 w-5" /></div>
                  <CardTitle>{feature.title}</CardTitle>
                  <CardDescription>{feature.description}</CardDescription>
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
      <SectionHead badge="Supported projects" title="Game support with visual routing." description="Every card shows status, module route, place IDs, and a loader copy path." />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {games.map((game) => <GameCard game={game} key={game.name} />)}
      </div>
    </section>
  );
}

function GameCard({ game }: { game: (typeof games)[number] }) {
  return (
    <Card className="game-card relative min-h-[430px] overflow-hidden p-5" style={{ "--game-a": game.tone, "--game-b": "hsl(var(--accent))" } as React.CSSProperties}>
      <div className="grid h-40 place-items-center">
        <div className="render-core">
          <span className="render-face face-front">{game.name.slice(0, 2).toUpperCase()}</span>
          <span className="render-face face-side" />
          <span className="render-face face-top" />
        </div>
      </div>
      <div className="flex items-start justify-between gap-3">
        <div>
          <Badge variant={game.status === "testing" ? "warning" : "success"}>{game.status}</Badge>
          <h3 className="mt-3 font-display text-2xl font-black">{game.name}</h3>
        </div>
        <Button size="sm" onClick={() => void copyLatestLoader()}><Copy className="h-4 w-4" /> Copy</Button>
      </div>
      <p className="mt-3 text-sm text-muted-foreground">{game.description}</p>
      <div className="mt-5 flex flex-wrap gap-2">
        <Badge variant="muted">{game.modules} modules</Badge>
        <Badge variant="muted">{game.route}</Badge>
        {game.ids.map((id) => <Badge variant="muted" key={id}>{id}</Badge>)}
      </div>
    </Card>
  );
}

function ModuleMatrixSection() {
  const rows = [
    ["Universal base", "68 modules", "Loads before game routes"],
    ["BedWars V14", "70 modules", "Compatibility audit exposed in runtime"],
    ["Route map", `${games.length} families`, "Nested place IDs resolve to base files"],
    ["Validation", "local script", "Cache, loader, GUI, bundle, and route checks"]
  ];

  return (
    <section className="site-wrap py-16">
      <SectionHead badge="Module matrix" title="The site now mirrors the runtime." description="Public support copy lines up with the real loader path, route inventory, and validation checks." />
      <div className="overflow-hidden rounded-lg border bg-card/80 shadow-premium backdrop-blur-xl">
        {rows.map(([name, value, detail]) => (
          <div className="grid gap-3 border-b p-5 last:border-b-0 md:grid-cols-[.7fr_.45fr_1fr] md:items-center" key={name}>
            <div className="font-display text-xl font-black">{name}</div>
            <Badge variant="secondary">{value}</Badge>
            <p className="text-sm text-muted-foreground">{detail}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function OpsSection() {
  const items = [
    { icon: Terminal, title: "Loader diagnostics", description: "Startup stages report cache setup, downloads, compilation, validation, and final module status." },
    { icon: ShieldCheck, title: "Failure isolation", description: "Module toggle and option callbacks are guarded so a bad route does not take down the whole UI." },
    { icon: Gauge, title: "Support readouts", description: "Dashboard widgets poll health, Roblox status, release data, and recent commit context." }
  ];

  return (
    <section className="site-wrap py-16" id="community">
      <SectionHead badge="Operations" title="Built around the boring checks that save time." description="The visible experience is tied to concrete runtime checks instead of decorative panels." />
      <div className="grid gap-4 md:grid-cols-3">
        {items.map((item) => {
          const Icon = item.icon;
          return (
            <Card key={item.title}><CardHeader><Icon className="h-5 w-5 text-primary" /><CardTitle>{item.title}</CardTitle><CardDescription>{item.description}</CardDescription></CardHeader></Card>
          );
        })}
      </div>
    </section>
  );
}

function FAQSection() {
  const faqs = [
    ["Which loader should I copy?", "Use Latest Commit first. It pins the newest pushed build and includes the website status API."],
    ["What does a Roblox warning mean?", "Roblox shipped a new client version. The loader may still run, but game-specific routes should be tested."],
    ["What do I send if something fails?", "Send the BadWars status label, place ID, and Developer Console error."],
    ["Is this admin-only?", "No. The public site is user-facing. The admin panel is a separate internal route shell."]
  ];
  return (
    <section className="site-wrap py-16" id="documentation">
      <SectionHead badge="FAQ" title="Answers that save a support ping." description="Short, practical help that keeps users moving." />
      <div className="grid gap-3 md:grid-cols-2">
        {faqs.map(([question, answer]) => <Card key={question}><CardHeader><CardTitle>{question}</CardTitle><CardDescription>{answer}</CardDescription></CardHeader></Card>)}
      </div>
    </section>
  );
}

export function SectionHead({ badge, title, description }: { badge: string; title: string; description: string }) {
  return (
    <div className="mb-8 grid gap-4 lg:grid-cols-[1fr_.72fr] lg:items-end">
      <div>
        <Badge>{badge}</Badge>
        <h2 className="mt-3 max-w-4xl font-display text-4xl font-black leading-tight md:text-6xl">{title}</h2>
      </div>
      <p className="text-muted-foreground">{description}</p>
    </div>
  );
}

export function Footer() {
  return (
    <footer className="site-wrap border-t py-10 text-sm text-muted-foreground">
      <div className="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div className="flex items-center gap-3"><Image src="/logo.svg" alt="" width={38} height={38} /><span><strong className="text-foreground">BadWars</strong><br />Current loader. Clear warnings. Faster fixes.</span></div>
        <div className="flex gap-4"><Link href="/changelog">Changelog</Link><Link href="/downloads">Downloads</Link><Link href="/dashboard">Account</Link></div>
      </div>
    </footer>
  );
}
