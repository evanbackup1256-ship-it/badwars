"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import {
  ArrowUpRight,
  ChevronDown,
  Code2,
  Copy,
  Cpu,
  Download,
  GitBranch,
  Layers,
  Monitor,
  Shield,
  Terminal,
  Zap,
} from "lucide-react";

const GAMES = [
  { name: "BedWars", modules: 70, status: "stable", placeIds: "6872274481" },
  { name: "SkyWars Voxel", modules: 18, status: "stable", placeIds: "8768229691" },
  { name: "Bridge Duel", modules: 10, status: "stable", placeIds: "139566161526375" },
  { name: "Prison Life", modules: 20, status: "stable", placeIds: "155615604" },
  { name: "Frontlines", modules: 9, status: "stable", placeIds: "5938036553" },
  { name: "Block Tales", modules: 11, status: "stable", placeIds: "16483433878" },
  { name: "Redliner", modules: 12, status: "beta", placeIds: "115875349872417" },
  { name: "1.8 Arena", modules: 10, status: "beta", placeIds: "77790193039862" },
  { name: "Jailbreak", modules: 6, status: "beta", placeIds: "606849621" },
];

const CAPABILITIES = [
  {
    icon: Zap,
    label: "Execution",
    detail: "Multi-transport HTTP layer with automatic fallback across request, http_request, syn.request, fluxus.request, and game.HttpGet. Cache-busted URLs on every load.",
  },
  {
    icon: Shield,
    label: "Isolation",
    detail: "Each module runs in a guarded sandbox. Failures are recorded, broken modules auto-disable, and the rest of the bundle keeps running.",
  },
  {
    icon: Layers,
    label: "Routing",
    detail: "Place ID resolution maps directly to nested game module bundles. Unknown games fall back to the universal module set instead of breaking.",
  },
  {
    icon: Terminal,
    label: "Diagnostics",
    detail: "Preflight syntax checks, postflight registration audits, runtime error tracking, and a full compatibility layer for BedWars controller resolution.",
  },
  {
    icon: Cpu,
    label: "Executor Detection",
    detail: "Multi-signal fingerprinting cross-checks identity APIs, namespace markers, closure tests, and capability probes. Spoofing is flagged.",
  },
  {
    icon: Monitor,
    label: "Interface",
    detail: "WindUI adapter with tabbed categories, notification pipeline, profile persistence, and per-module option controls. RightShift toggles.",
  },
];

const TICKER_ITEMS = [
  "BedWars — 70 modules",
  "SkyWars Voxel — 18 modules",
  "Bridge Duel — 10 modules",
  "Prison Life — 20 modules",
  "Frontlines — 9 modules",
  "Block Tales — 11 modules",
  "Redliner — 12 modules",
  "1.8 Arena — 10 modules",
  "Jailbreak — 6 modules",
  "Universal — 68 modules",
];

function useCountUp(target: number, duration = 1500) {
  const [value, setValue] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  const started = useRef(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !started.current) {
          started.current = true;
          const start = performance.now();
          const tick = (now: number) => {
            const progress = Math.min((now - start) / duration, 1);
            const eased = 1 - Math.pow(1 - progress, 3);
            setValue(Math.round(eased * target));
            if (progress < 1) requestAnimationFrame(tick);
          };
          requestAnimationFrame(tick);
        }
      },
      { threshold: 0.5 }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [target, duration]);

  return { value, ref };
}

function Stat({ label, value, suffix = "" }: { label: string; value: number; suffix?: string }) {
  const { value: display, ref } = useCountUp(value);
  return (
    <div className="text-center">
      <span ref={ref} className="text-4xl md:text-5xl font-black tracking-tighter text-gradient">
        {display}
        {suffix}
      </span>
      <p className="text-xs font-mono text-[var(--fg-muted)] mt-2 uppercase tracking-widest">{label}</p>
    </div>
  );
}

function TerminalBlock() {
  const [line, setLine] = useState(0);
  const lines = [
    { prompt: "$", text: "badwars --init", output: null },
    { prompt: "→", text: "executor detected", output: "WindUI adapter loaded" },
    { prompt: "→", text: "universal bundle", output: "68 modules registered" },
    { prompt: "→", text: "game route resolved", output: "BedWars / 6872274481" },
    { prompt: "→", text: "profile loaded", output: "default" },
    { prompt: "$", text: "status", output: "all systems operational", success: true },
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setLine((prev) => (prev < lines.length - 1 ? prev + 1 : prev));
    }, 800);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="code-block p-5 max-w-lg mx-auto">
      {lines.slice(0, line + 1).map((l, i) => (
        <div key={i} className="flex gap-3">
          <span className="prompt shrink-0">{l.prompt}</span>
          <span className="text-[var(--fg-primary)]">{l.text}</span>
          {l.output && (
            <span className={l.success ? "success" : "output"}>— {l.output}</span>
          )}
        </div>
      ))}
      {line < lines.length - 1 && <div className="cursor-blink mt-1" />}
    </div>
  );
}

export default function LandingPage() {
  const [copied, setCopied] = useState(false);

  const loaderScript = `loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true))()`;

  function handleCopy() {
    navigator.clipboard?.writeText(loaderScript).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }

  return (
    <div className="relative min-h-screen scanlines">
      <div className="noise-overlay" />
      <div className="vignette" />

      {/* ─── NAV ─── */}
      <nav className="fixed top-0 left-0 right-0 z-50 border-b border-[var(--border-subtle)] bg-[var(--bg-deep)]/80 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-6 h-14 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3 group">
            <div className="w-7 h-7 rounded bg-[var(--accent)] flex items-center justify-center">
              <span className="text-white font-black text-xs">B</span>
            </div>
            <span className="font-black text-lg tracking-tight">
              <span className="text-[var(--accent)]">BAD</span>
              <span className="text-[var(--fg-primary)]">WARS</span>
            </span>
          </Link>

          <div className="hidden md:flex items-center gap-1">
            {["Features", "Games", "Downloads", "Changelog"].map((item) => (
              <Link
                key={item}
                href={`/${item.toLowerCase()}`}
                className="px-4 py-2 text-xs font-mono uppercase tracking-wider text-[var(--fg-secondary)] hover:text-[var(--fg-primary)] transition-colors"
              >
                {item}
              </Link>
            ))}
          </div>

          <button
            onClick={handleCopy}
            className="btn-glow flex items-center gap-2 px-4 py-2 bg-[var(--accent)] text-white text-xs font-mono uppercase tracking-wider rounded-[var(--radius-sm)] hover:bg-[var(--accent)]/90 transition-colors"
          >
            <Copy className="w-3 h-3" />
            {copied ? "Copied" : "Copy Loader"}
          </button>
        </div>
      </nav>

      {/* ─── HERO ─── */}
      <section className="relative min-h-screen flex items-center pt-14 overflow-hidden">
        <div className="grid-pattern absolute inset-0 opacity-40" />
        <div className="radial-glow" style={{ top: "-10%", left: "30%" }} />

        <div className="relative z-10 max-w-7xl mx-auto px-6 w-full">
          <div className="max-w-3xl">
            <div className="tag tag-accent mb-8">
              <span className="status-dot" style={{ width: 6, height: 6 }} />
              v19.0 — Obsidian
            </div>

            <h1 className="text-6xl md:text-8xl lg:text-9xl font-black tracking-tighter leading-[0.9] mb-8">
              <span className="glitch text-[var(--fg-primary)]" data-text="BADWARS">
                BADWARS
              </span>
            </h1>

            <p className="text-lg md:text-xl text-[var(--fg-secondary)] max-w-xl mb-12 leading-relaxed">
              Loader console for Roblox. Route-aware module bundles, executor fingerprinting, and a WindUI interface. No accounts, no downloads.
            </p>

            <div className="flex flex-col sm:flex-row gap-4">
              <button
                onClick={handleCopy}
                className="btn-glow flex items-center justify-center gap-3 px-8 py-4 bg-[var(--accent)] text-white font-mono text-sm uppercase tracking-wider rounded-[var(--radius-sm)] hover:bg-[var(--accent)]/90 transition-all"
              >
                <Copy className="w-4 h-4" />
                {copied ? "Copied to clipboard" : "Copy Loader"}
                <ArrowUpRight className="w-4 h-4" />
              </button>

              <Link
                href="/downloads"
                className="flex items-center justify-center gap-3 px-8 py-4 border border-[var(--border-subtle)] text-[var(--fg-primary)] font-mono text-sm uppercase tracking-wider rounded-[var(--radius-sm)] hover:border-[var(--accent)]/50 hover:bg-[var(--accent-dim)] transition-all"
              >
                <Download className="w-4 h-4" />
                Downloads
              </Link>
            </div>
          </div>

          {/* Terminal */}
          <div className="mt-20 md:mt-32">
            <TerminalBlock />
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-[var(--fg-muted)]">
          <span className="text-[10px] font-mono uppercase tracking-widest">Scroll</span>
          <ChevronDown className="w-4 h-4 animate-bounce" />
        </div>
      </section>

      {/* ─── MARQUEE ─── */}
      <div className="border-y border-[var(--border-subtle)] bg-[var(--bg-surface)] overflow-hidden py-4">
        <div className="flex marquee-track" style={{ width: "max-content" }}>
          {[...TICKER_ITEMS, ...TICKER_ITEMS].map((item, i) => (
            <span
              key={i}
              className="mx-8 text-xs font-mono uppercase tracking-wider text-[var(--fg-muted)] whitespace-nowrap flex items-center gap-3"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-[var(--accent)]" />
              {item}
            </span>
          ))}
        </div>
      </div>

      {/* ─── STATS ─── */}
      <section className="py-24 border-b border-[var(--border-subtle)]">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-12">
            <Stat label="Total Modules" value={234} />
            <Stat label="Games Supported" value={9} />
            <Stat label="HTTP Transports" value={7} />
            <Stat label="Executor Signatures" value={45} />
          </div>
        </div>
      </section>

      {/* ─── CAPABILITIES ─── */}
      <section className="py-24" id="features">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex items-end justify-between mb-16 flex-wrap gap-4">
            <div>
              <div className="tag tag-accent mb-4">
                <Code2 className="w-3 h-3" />
                Architecture
              </div>
              <h2 className="text-4xl md:text-5xl font-black tracking-tight">
                How it works
              </h2>
            </div>
            <p className="text-[var(--fg-secondary)] max-w-md text-sm leading-relaxed">
              Six subsystems handle execution, isolation, routing, diagnostics, detection, and interface. Each one is independently testable.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-px bg-[var(--border-subtle)] border border-[var(--border-subtle)]">
            {CAPABILITIES.map((cap) => {
              const Icon = cap.icon;
              return (
                <div
                  key={cap.label}
                  className="card-lift bg-[var(--bg-surface)] p-8 group"
                >
                  <div className="w-10 h-10 rounded-[var(--radius-sm)] bg-[var(--accent-dim)] flex items-center justify-center mb-6 group-hover:bg-[var(--accent)]/30 transition-colors">
                    <Icon className="w-5 h-5 text-[var(--accent)]" />
                  </div>
                  <h3 className="text-lg font-bold mb-3 tracking-tight">{cap.label}</h3>
                  <p className="text-sm text-[var(--fg-secondary)] leading-relaxed">
                    {cap.detail}
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      <hr className="hr-accent" />

      {/* ─── GAMES TABLE ─── */}
      <section className="py-24" id="games">
        <div className="max-w-7xl mx-auto px-6">
          <div className="mb-16">
            <div className="tag tag-accent mb-4">
              <GitBranch className="w-3 h-3" />
              Route Inventory
            </div>
            <h2 className="text-4xl md:text-5xl font-black tracking-tight">
              {GAMES.length} games mapped
            </h2>
          </div>

          <div className="border border-[var(--border-subtle)] rounded-[var(--radius-md)] overflow-hidden">
            {/* Header */}
            <div className="grid grid-cols-12 gap-4 px-6 py-3 bg-[var(--bg-elevated)] text-[10px] font-mono uppercase tracking-widest text-[var(--fg-muted)] border-b border-[var(--border-subtle)]">
              <div className="col-span-4">Game</div>
              <div className="col-span-2">Modules</div>
              <div className="col-span-3">Place ID</div>
              <div className="col-span-3 text-right">Status</div>
            </div>

            {/* Rows */}
            {GAMES.map((game, i) => (
              <div
                key={game.name}
                className="grid grid-cols-12 gap-4 px-6 py-4 border-b border-[var(--border-subtle)] last:border-b-0 hover:bg-[var(--bg-hover)] transition-colors group"
                style={{ animationDelay: `${i * 50}ms` }}
              >
                <div className="col-span-4 font-semibold text-sm group-hover:text-[var(--accent)] transition-colors">
                  {game.name}
                </div>
                <div className="col-span-2 text-sm font-mono text-[var(--fg-secondary)]">
                  {game.modules}
                </div>
                <div className="col-span-3 text-sm font-mono text-[var(--fg-muted)]">
                  {game.placeIds}
                </div>
                <div className="col-span-3 flex justify-end">
                  <span
                    className={`tag ${
                      game.status === "stable" ? "tag-success" : "tag-warning"
                    }`}
                  >
                    {game.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <hr className="hr-accent" />

      {/* ─── LOADER BLOCK ─── */}
      <section className="py-24" id="downloads">
        <div className="max-w-7xl mx-auto px-6">
          <div className="gradient-border p-8 md:p-12">
            <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-8">
              <div>
                <h2 className="text-3xl md:text-4xl font-black tracking-tight mb-3">
                  One line. That's it.
                </h2>
                <p className="text-[var(--fg-secondary)] text-sm max-w-md">
                  Paste this into your executor. The loader handles the rest — cache, diagnostics, module bundles, and UI.
                </p>
              </div>

              <button
                onClick={handleCopy}
                className="btn-glow shrink-0 flex items-center gap-3 px-6 py-3 bg-[var(--accent)] text-white font-mono text-xs uppercase tracking-wider rounded-[var(--radius-sm)] hover:bg-[var(--accent)]/90 transition-all"
              >
                <Copy className="w-4 h-4" />
                {copied ? "Copied" : "Copy"}
              </button>
            </div>

            <div className="code-block mt-8 p-5 overflow-x-auto">
              <span className="prompt">$ </span>
              <span className="text-[var(--fg-primary)] break-all">{loaderScript}</span>
            </div>
          </div>
        </div>
      </section>

      {/* ─── FOOTER ─── */}
      <footer className="border-t border-[var(--border-subtle)] bg-[var(--bg-surface)]">
        <div className="max-w-7xl mx-auto px-6 py-12">
          <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
            <div className="flex items-center gap-3">
              <div className="w-6 h-6 rounded bg-[var(--accent)] flex items-center justify-center">
                <span className="text-white font-black text-[10px]">B</span>
              </div>
              <span className="font-black tracking-tight">
                <span className="text-[var(--accent)]">BAD</span>
                <span className="text-[var(--fg-primary)]">WARS</span>
              </span>
            </div>

            <div className="flex items-center gap-6 text-xs font-mono text-[var(--fg-muted)]">
              <Link href="/features" className="hover:text-[var(--fg-primary)] transition-colors">Features</Link>
              <Link href="/downloads" className="hover:text-[var(--fg-primary)] transition-colors">Downloads</Link>
              <Link href="/changelog" className="hover:text-[var(--fg-primary)] transition-colors">Changelog</Link>
              <a
                href="https://github.com/evanbackup1256-ship-it/badwars"
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-[var(--fg-primary)] transition-colors flex items-center gap-1"
              >
                <GitBranch className="w-3 h-3" />
                Source
              </a>
            </div>
          </div>

          <div className="section-divider my-8" />

          <div className="flex flex-col sm:flex-row justify-between items-center gap-4 text-[11px] font-mono text-[var(--fg-muted)]">
            <span>2026 BadWars</span>
            <div className="flex items-center gap-2">
              <span className="status-dot" style={{ width: 6, height: 6 }} />
              <span>All systems operational</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
