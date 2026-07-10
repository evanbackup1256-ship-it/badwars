"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import {
  Activity, ArrowRight, Boxes, Check, ChevronRight, Clipboard,
  Copy, Cpu, Download, GitBranch, Menu, Radar, Route,
  ShieldCheck, TerminalSquare, X, Zap,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { buildLoader } from "@/lib/loader";
import { games, navItems } from "@/lib/site-data";

type RobloxStatus = { ok: boolean; changed: boolean; version?: string; warning?: string };
type CommitInfo = { shortSha: string; message: string; fallback: boolean };

async function fetchRobloxStatus(): Promise<RobloxStatus> {
  const response = await fetch("/api/roblox/status", { cache: "no-store" });
  if (!response.ok) throw new Error("Status unavailable");
  return response.json();
}

async function fetchLatestCommit(): Promise<CommitInfo> {
  const response = await fetch("/api/github/latest", { cache: "no-store" });
  if (!response.ok) throw new Error("Commit unavailable");
  return response.json();
}

async function getLatestLoader() {
  const response = await fetch("/api/download/latest", { cache: "no-store" });
  if (!response.ok) {
    return buildLoader(typeof window === "undefined" ? "https://badwars-production.up.railway.app" : window.location.origin);
  }
  return response.text();
}

async function copyLatestLoader() {
  try {
    await navigator.clipboard.writeText(await getLatestLoader());
    toast.success("Loader copied", { description: "Ready to paste into your executor." });
  } catch {
    toast.error("Clipboard blocked", { description: "Open Downloads to select the loader manually." });
  }
}

export function SiteNav() {
  const [open, setOpen] = useState(false);
  return (
    <header className="command-nav">
      <div className="site-wrap flex h-16 items-center justify-between">
        <Link href="/" className="brand-lockup" aria-label="BadWars home">
          <span className="brand-mark"><Image src="/logo.svg" alt="" width={24} height={24} priority /></span>
          <span><b>BAD</b>WARS</span>
        </Link>
        <nav className="hidden items-center lg:flex" aria-label="Primary navigation">
          {navItems.map((item) => <Link className="nav-link" key={item.href} href={item.href}>{item.label}</Link>)}
          <Link className="nav-link" href="/dashboard">Console</Link>
        </nav>
        <div className="flex items-center gap-2">
          <Button size="sm" onClick={copyLatestLoader} className="hidden sm:inline-flex uppercase font-mono text-[11px]">
            <Copy /> Copy loader
          </Button>
          <button className="icon-control lg:hidden" onClick={() => setOpen((value) => !value)} aria-label={open ? "Close menu" : "Open menu"} aria-expanded={open}>
            {open ? <X /> : <Menu />}
          </button>
        </div>
      </div>
      <AnimatePresence>
        {open && <motion.nav initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }} exit={{ height: 0, opacity: 0 }} className="mobile-nav" aria-label="Mobile navigation">
          <div className="site-wrap py-3">
            {[...navItems, { label: "Console", href: "/dashboard" }].map((item) => <Link key={item.href} href={item.href} onClick={() => setOpen(false)}>{item.label}<ChevronRight /></Link>)}
            <Button onClick={copyLatestLoader} className="mt-2 w-full sm:hidden"><Copy /> Copy loader</Button>
          </div>
        </motion.nav>}
      </AnimatePresence>
    </header>
  );
}

function CommandCore({ status, commit }: { status: RobloxStatus | undefined; commit: CommitInfo | undefined }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const node = ref.current;
    if (!node || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const move = (event: PointerEvent) => {
      const rect = node.getBoundingClientRect();
      const x = (event.clientX - rect.left) / rect.width - 0.5;
      const y = (event.clientY - rect.top) / rect.height - 0.5;
      node.style.setProperty("--rx", `${-y * 9}deg`);
      node.style.setProperty("--ry", `${x * 12}deg`);
    };
    const reset = () => { node.style.setProperty("--rx", "0deg"); node.style.setProperty("--ry", "0deg"); };
    node.addEventListener("pointermove", move);
    node.addEventListener("pointerleave", reset);
    return () => { node.removeEventListener("pointermove", move); node.removeEventListener("pointerleave", reset); };
  }, []);

  return (
    <div className="core-stage" ref={ref} aria-label="Live BadWars command core">
      <div className="core-grid" />
      <div className="orbit orbit-a"><i /><i /><i /></div>
      <div className="orbit orbit-b"><i /><i /></div>
      <div className="telemetry-rail rail-left"><span>NODE 01</span><b>EXEC</b><em>98.7%</em></div>
      <div className="telemetry-rail rail-right"><span>NODE 10</span><b>ROUTE</b><em>{games.length}/10</em></div>
      <div className="core-object">
        <div className="core-plane plane-back" />
        <div className="core-plane plane-mid"><Image src="/logo.svg" alt="" width={76} height={76} /></div>
        <div className="core-plane plane-front"><span>CORE</span><strong>{status?.ok ? "LIVE" : "SYNC"}</strong></div>
      </div>
      <div className="core-readout readout-top"><span>COMMIT</span><strong>{commit?.shortSha || "SYNCING"}</strong></div>
      <div className="core-readout readout-bottom"><span>ROUTES ACTIVE</span><strong>{games.length}</strong></div>
      <div className="core-caption"><Activity /> BADWARS.RUNTIME / ONLINE</div>
    </div>
  );
}

const architecture = [
  { icon: Zap, number: "01", title: "Execution", text: "Transport fallbacks negotiate the fastest available request path." },
  { icon: ShieldCheck, number: "02", title: "Isolation", text: "Guarded modules fail independently without taking down the bundle." },
  { icon: Route, number: "03", title: "Routing", text: "Place IDs resolve directly into game-specific module trees." },
  { icon: Radar, number: "04", title: "Diagnostics", text: "Preflight and runtime checks surface actionable status." },
  { icon: Cpu, number: "05", title: "Detection", text: "Capability probes verify executor support before launch." },
  { icon: Boxes, number: "06", title: "Interface", text: "A persistent control layer keeps modules and profiles close." },
];

export function Footer() {
  return <footer className="command-footer">
    <div className="site-wrap footer-grid">
      <div><Link href="/" className="brand-lockup"><span className="brand-mark"><Image src="/logo.svg" alt="" width={22} height={22} /></span><span><b>BAD</b>WARS</span></Link><p>Route-aware Roblox loader infrastructure.</p></div>
      <div><span className="footer-label">Explore</span>{navItems.map((item) => <Link key={item.href} href={item.href}>{item.label}</Link>)}</div>
      <div><span className="footer-label">System</span><Link href="/dashboard">Dashboard</Link><Link href="/settings">Settings</Link><Link href="/profile">Support profile</Link></div>
      <div><span className="footer-label">Network</span><a href="https://github.com/evanbackup1256-ship-it/badwars" target="_blank" rel="noreferrer">GitHub <GitBranch /></a><span className="footer-status"><i /> Operational</span></div>
    </div>
    <div className="site-wrap footer-base"><span>BADWARS / 2026</span><span>BUILD CHANNEL: MAIN</span></div>
  </footer>;
}

export function LandingPage() {
  const status = useQuery({ queryKey: ["landing-roblox"], queryFn: fetchRobloxStatus, refetchInterval: 120_000, retry: 1 });
  const commit = useQuery({ queryKey: ["landing-commit"], queryFn: fetchLatestCommit, refetchInterval: 60_000, retry: 1 });
  const loaderPreview = 'loadstring(game:HttpGet("https://badwars-production.up.railway.app/api/download/latest"))()';

  return <div className="scanlines">
    <SiteNav />
    <main>
      <section className="hero-band">
        <div className="hero-grid" />
        <div className="site-wrap hero-layout">
          <motion.div className="hero-copy" initial={{ y: 8 }} animate={{ y: 0 }} transition={{ duration: .35 }}>
            <div className="eyebrow"><span className="live-dot" /> V19 / OBSIDIAN CHANNEL</div>
            <h1>BADWARS</h1>
            <p>Route-aware loader infrastructure built to execute cleanly, recover intelligently, and show its work.</p>
            <div className="hero-actions">
              <Button size="lg" onClick={copyLatestLoader}><Clipboard /> Copy loader <ArrowRight /></Button>
              <Button size="lg" variant="outline" asChild><Link href="/downloads"><Download /> Downloads</Link></Button>
            </div>
            <dl className="hero-stats">
              <div><dt>Network</dt><dd><i /> {status.data?.ok ? "Operational" : status.isError ? "Degraded" : "Checking"}</dd></div>
              <div><dt>Commit</dt><dd>{commit.data?.shortSha || "Syncing"}</dd></div>
              <div><dt>Routes</dt><dd>{games.length} active</dd></div>
            </dl>
          </motion.div>
          <motion.div initial={{ scale: .985 }} animate={{ scale: 1 }} transition={{ duration: .4 }}><CommandCore status={status.data} commit={commit.data} /></motion.div>
        </div>
        <div className="hero-index"><span>01</span><i /><span>COMMAND CORE</span></div>
      </section>

      <section className="ticker" aria-label="Platform metrics"><div>{["234 MODULES", "10 ROUTES", "7 TRANSPORTS", "45 SIGNATURES", "LIVE DIAGNOSTICS", "GUARDED EXECUTION", "234 MODULES", "10 ROUTES", "7 TRANSPORTS"].map((item, i) => <span key={i}><i />{item}</span>)}</div></section>

      <section className="section-band" id="architecture"><div className="site-wrap">
        <div className="section-heading"><div><span className="section-kicker">02 / ARCHITECTURE</span><h2>Six systems.<br />One clean launch.</h2></div><p>Every layer has a job. Every failure has a boundary. The loader stays readable from first request to final module.</p></div>
        <div className="architecture-list">{architecture.map(({ icon: Icon, number, title, text }) => <article key={title}><span>{number}</span><Icon /><div><h3>{title}</h3><p>{text}</p></div><ChevronRight /></article>)}</div>
      </div></section>

      <section className="section-band route-band" id="routes"><div className="site-wrap">
        <div className="section-heading"><div><span className="section-kicker">03 / ROUTE INVENTORY</span><h2>Mapped to the game.</h2></div><p>{games.filter((game) => game.status === "working").length} production routes and {games.filter((game) => game.status !== "working").length} monitored routes resolve automatically.</p></div>
        <div className="route-table"><div className="route-head"><span>Game</span><span>Modules</span><span>Primary ID</span><span>State</span></div>{games.map((game) => <div className="route-row" key={game.name}><span><b>{game.name}</b><small>{game.route}</small></span><span>{String(game.modules).padStart(2, "0")}</span><span>{game.ids[0]}</span><span className={game.status === "working" ? "state-live" : "state-watch"}><i />{game.status === "working" ? "Stable" : "Testing"}</span></div>)}</div>
      </div></section>

      <section className="deploy-band"><div className="site-wrap deploy-layout"><div><span className="section-kicker">04 / DEPLOYMENT</span><h2>One line.<br />Full system.</h2><p>Paste the current loader into your executor. Routing, compatibility checks, diagnostics, and interface registration run from there.</p></div><div className="deploy-console"><div className="console-bar"><span><TerminalSquare /> loader.lua</span><button onClick={copyLatestLoader} aria-label="Copy loader"><Copy /></button></div><code><span>01</span>{loaderPreview}</code><div className="console-result"><Check /> Production endpoint ready</div></div></div></section>
    </main>
    <Footer />
  </div>;
}
