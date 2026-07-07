"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, CheckCircle2, ClipboardCheck, Copy, Download, ExternalLink, LayoutDashboard, RefreshCcw, Search, Wifi } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { SiteNav, Footer } from "@/components/site-shell";
import { buildLoader, loaderFileName } from "@/lib/loader";
import { activity, changelog, features, games, releases } from "@/lib/site-data";
import { formatRelativeTime } from "@/lib/utils";

const sidebar = [
  { label: "Overview", href: "/dashboard", icon: LayoutDashboard },
  { label: "Downloads", href: "/downloads", icon: Download },
  { label: "Features", href: "/features", icon: CheckCircle2 },
  { label: "Changelog", href: "/changelog", icon: RefreshCcw }
];

type RobloxStatus = {
  ok: boolean;
  changed: boolean;
  version?: string | null;
  previousVersion?: string | null;
  channel?: string;
  warning?: string;
  lastCheckedAt?: string;
  lastChangedAt?: string | null;
};

type HealthStatus = {
  ok: boolean;
  service: string;
  checkedAt: string;
};

type GitHubCommitInfo = {
  sha: string;
  shortSha: string;
  message: string;
  htmlUrl: string;
  syncedAt: string;
  fallback: boolean;
  committedAt?: string;
  author?: string;
};

type GitHubCommitsResponse = {
  commits: GitHubCommitInfo[];
  syncedAt: string;
};

async function currentLoaderText() {
  const response = await fetch("/api/download/latest", { cache: "no-store" });
  if (!response.ok) {
    return buildLoader(typeof window === "undefined" ? "https://badwars-production.up.railway.app" : window.location.origin);
  }
  return response.text();
}

function downloadLatestLoader() {
  const link = document.createElement("a");
  link.href = "/api/download/latest";
  link.download = loaderFileName;
  document.body.appendChild(link);
  link.click();
  link.remove();
}

async function fetchHealth(): Promise<HealthStatus> {
  const response = await fetch("/api/health", { cache: "no-store" });
  if (!response.ok) throw new Error("Health check failed");
  return response.json();
}

async function fetchRobloxStatus(): Promise<RobloxStatus> {
  const response = await fetch("/api/roblox/status", { cache: "no-store" });
  if (!response.ok) throw new Error("Roblox status failed");
  return response.json();
}

async function fetchGitHubCommits(): Promise<GitHubCommitsResponse> {
  const response = await fetch("/api/github/commits", { cache: "no-store" });
  if (!response.ok) throw new Error("GitHub commits failed");
  return response.json();
}

function formatCommitDate(value?: string) {
  if (!value) return "just now";
  return new Intl.DateTimeFormat("en", { month: "short", day: "numeric", year: "numeric" }).format(new Date(value));
}

function AppFrame({ title, description, children }: { title: string; description: string; children: React.ReactNode }) {
  return (
    <>
      <SiteNav />
      <div className="site-wrap">
        <div className="grid gap-8 py-10 lg:grid-cols-[240px_1fr]">
          <aside className="hidden lg:block">
            <div className="sticky top-24">
              <div className="uppercase tracking-[2px] text-[10px] font-semibold text-muted-foreground mb-3 px-2">Console</div>
              <nav className="space-y-1">
                {sidebar.map((item) => {
                  const Icon = item.icon;
                  return (
                    <Link 
                      key={item.href} 
                      href={item.href} 
                      className="flex items-center gap-3 rounded-2xl px-4 py-[10px] text-sm hover:bg-white/5 transition text-muted-foreground hover:text-foreground"
                    >
                      <Icon className="h-4 w-4" /> {item.label}
                    </Link>
                  );
                })}
              </nav>
            </div>
          </aside>

          <main>
            <div className="mb-8">
              <Badge className="mb-2">BadWars Console</Badge>
              <h1 className="font-display text-5xl font-black tracking-[-1.8px]">{title}</h1>
              <p className="mt-2 max-w-lg text-muted-foreground">{description}</p>
            </div>
            {children}
          </main>
        </div>
      </div>
      <Footer />
    </>
  );
}

export function DashboardPage() {
  const health = useQuery({ queryKey: ["dashboard-health"], queryFn: fetchHealth, refetchInterval: 30_000 });
  const roblox = useQuery({ queryKey: ["dashboard-roblox"], queryFn: fetchRobloxStatus, refetchInterval: 120_000 });
  const commits = useQuery({ queryKey: ["dashboard-commits"], queryFn: fetchGitHubCommits, refetchInterval: 60_000, retry: 1 });
  const [activityQuery, setActivityQuery] = useState("");

  const filteredActivity = useMemo(() => {
    const query = activityQuery.trim().toLowerCase();
    if (!query) return activity;
    return activity.filter((item) => `${item.title} ${item.detail}`.toLowerCase().includes(query));
  }, [activityQuery]);

  const dashboardStats = [
    {
      icon: Wifi,
      label: "API health",
      value: health.data?.ok ? "Online" : health.isLoading ? "Checking" : "Offline",
      detail: health.data?.checkedAt ? `checked ${formatRelativeTime(health.data.checkedAt)}` : "live health endpoint"
    },
    {
      icon: AlertTriangle,
      label: "Roblox warnings",
      value: roblox.data?.changed ? "Active" : roblox.data?.ok ? "Clear" : "Unknown",
      detail: roblox.data?.version || "Roblox client version"
    },
    {
      icon: Download,
      label: "Latest release",
      value: releases[0].version,
      detail: releases[0].checksum
    },
    {
      icon: LayoutDashboard,
      label: "Supported routes",
      value: String(games.length),
      detail: `${games.filter((game) => game.status === "working").length} working`
    }
  ];

  const copyDashboardLoader = async () => {
    await navigator.clipboard?.writeText(await currentLoaderText());
    toast.success("Loader copied", { description: "The production loader was copied from the dashboard." });
  };

  return (
    <AppFrame title="Dashboard" description="A working command console with live status, quick actions, downloads, notifications, activity search, feature flags, and support context.">
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {dashboardStats.map((widget, index) => {
          const Icon = widget.icon;
          return (
            <motion.div initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.04 }} key={widget.label}>
              <Card className="border-white/10 hover:border-primary/20">
                <CardHeader className="pb-2">
                  <div className="flex items-center gap-2 text-xs uppercase tracking-widest text-muted-foreground">
                    <Icon className="h-3.5 w-3.5" /> {widget.label}
                  </div>
                  <CardTitle className="text-4xl font-black tracking-tighter mt-1">{widget.value}</CardTitle>
                  <CardDescription className="text-xs mt-0.5">{widget.detail}</CardDescription>
                </CardHeader>
              </Card>
            </motion.div>
          );
        })}
      </div>

      <div className="mt-5 grid gap-4 xl:grid-cols-[1fr_.75fr]">
        <Card>
          <CardHeader>
            <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <CardTitle>Activity feed</CardTitle>
                <CardDescription>Searchable runtime and product events.</CardDescription>
              </div>
              <Input className="lg:max-w-xs" placeholder="Search activity..." value={activityQuery} onChange={(event) => setActivityQuery(event.target.value)} />
            </div>
          </CardHeader>
          <CardContent className="grid gap-3">
            {filteredActivity.map((item) => {
              const Icon = item.icon;
              return <div className="flex gap-3 rounded-2xl border bg-background/45 p-4" key={item.title}><Icon className="mt-1 h-5 w-5 text-primary" /><div><div className="font-bold">{item.title}</div><p className="text-sm text-muted-foreground">{item.detail}</p></div></div>;
            })}
            {!filteredActivity.length ? <div className="rounded-2xl border border-dashed p-6 text-center text-sm text-muted-foreground">No activity matches that search.</div> : null}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <Badge variant={roblox.data?.changed ? "warning" : "success"}>{roblox.data?.changed ? "Needs testing" : "Operational"}</Badge>
            <CardTitle>Roblox update watch</CardTitle>
            <CardDescription>{roblox.data?.warning || "Live Railway status feeds the dashboard and loader."}</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            <div className="grid gap-2 rounded-2xl border bg-background/45 p-4 text-sm">
              <div className="flex justify-between gap-3"><span className="text-muted-foreground">Channel</span><strong>{roblox.data?.channel || "LIVE"}</strong></div>
              <div className="flex justify-between gap-3"><span className="text-muted-foreground">Version</span><strong className="truncate">{roblox.data?.version || "checking"}</strong></div>
              <div className="flex justify-between gap-3"><span className="text-muted-foreground">Checked</span><strong>{formatRelativeTime(roblox.data?.lastCheckedAt)}</strong></div>
            </div>
            <Button onClick={() => roblox.refetch()}><RefreshCcw className="h-4 w-4" /> Refresh Roblox status</Button>
          </CardContent>
        </Card>
      </div>

      <div className="mt-5 grid gap-4 xl:grid-cols-[.85fr_1.15fr]">
        <Card>
          <CardHeader>
            <CardTitle>Quick actions</CardTitle>
            <CardDescription>Only actions backed by current project endpoints are shown here.</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3 sm:grid-cols-2">
            <Button onClick={copyDashboardLoader}><ClipboardCheck className="h-4 w-4" /> Copy loader</Button>
            <Button variant="outline" onClick={() => { downloadLatestLoader(); toast.success("Download started", { description: loaderFileName }); }}><Download className="h-4 w-4" /> Download latest</Button>
            <Button variant="outline" onClick={() => health.refetch()}><RefreshCcw className="h-4 w-4" /> Refresh health</Button>
            <Button asChild variant="outline"><Link href="/downloads"><ExternalLink className="h-4 w-4" /> Download center</Link></Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Latest source commit</CardTitle>
            <CardDescription>Live GitHub data is used when available; maintained release notes fill in when GitHub is unavailable.</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            <div className="rounded-2xl border bg-background/45 p-4">
              <div>
                <div className="font-display text-2xl font-black">{commits.data?.commits[0]?.shortSha || releases[0].version}</div>
                <div className="mt-1 text-sm text-muted-foreground">{commits.data?.commits[0]?.message || releases[0].notes.join(", ")}</div>
              </div>
            </div>
            <div className="text-sm text-muted-foreground">Synced {formatRelativeTime(commits.data?.syncedAt)}.</div>
          </CardContent>
        </Card>
      </div>

      <div className="mt-5 grid gap-4 xl:grid-cols-3">
        <Card>
          <CardHeader><CardTitle>Runtime validation</CardTitle><CardDescription>Release checks currently enforced by the repository.</CardDescription></CardHeader>
          <CardContent className="grid gap-3">
            {["Runtime validation", "Source validation", "TypeScript", "ESLint", "Production build"].map((item) => <div className="flex items-center justify-between gap-3 rounded-2xl border bg-background/45 p-4" key={item}><span className="font-bold">{item}</span><Badge variant="success">gate</Badge></div>)}
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Supported routes</CardTitle><CardDescription>Visible route state comes from the maintained route inventory.</CardDescription></CardHeader>
          <CardContent className="grid gap-3">
            {games.slice(0, 5).map((game) => <div className="flex items-center justify-between gap-3 rounded-2xl border bg-background/45 p-4" key={game.name}><div><div className="font-bold">{game.name}</div><div className="text-xs text-muted-foreground">{game.ids[0]}</div></div><Badge variant={game.status === "working" ? "success" : "warning"}>{game.status}</Badge></div>)}
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Support checklist</CardTitle><CardDescription>What to include when reporting a real runtime failure.</CardDescription></CardHeader>
          <CardContent className="grid gap-3">
            {["Visible BadWars status text", "Place ID and route name", "Developer Console error", "Whether cache was cleared"].map((item) => <div className="rounded-2xl border bg-background/45 p-4 text-sm font-bold" key={item}>{item}</div>)}
          </CardContent>
        </Card>
      </div>
    </AppFrame>
  );
}

export function ProfilePage() {
  return (
    <AppFrame title="Runtime support profile" description="Public support context for reports. No account data or fake user statistics are shown.">
      <div className="grid gap-4 xl:grid-cols-[.75fr_1fr]">
        <Card>
          <CardHeader>
            <Badge variant="secondary">Support identity</Badge>
            <CardTitle>What to include</CardTitle>
            <CardDescription>BadWars does not need a website account to diagnose loader/runtime failures.</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            {["Visible loader status text", "Place ID and game route", "BadWars version and commit", "Developer Console error text"].map((item) => <div className="rounded-2xl border bg-background/45 p-4 text-sm font-bold" key={item}>{item}</div>)}
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>Local-only runtime data</CardTitle><CardDescription>Profiles, layout, translations, and cache files stay in the executor filesystem unless a user chooses to share diagnostics.</CardDescription></CardHeader>
          <CardContent className="grid gap-3">
            {["badscript/profiles/*.txt", "badwars_translations/*.json", "badscript/profiles/commit.txt"].map((item) => <div className="flex items-center gap-3 rounded-2xl border p-4" key={item}><CheckCircle2 className="h-5 w-5 text-emerald-300" /> {item}</div>)}
          </CardContent>
        </Card>
      </div>
    </AppFrame>
  );
}

export function DownloadsPage() {
  const commits = useQuery({ queryKey: ["github-commits"], queryFn: fetchGitHubCommits, refetchInterval: 60_000, retry: 1 });
  const latestCommit = commits.data?.commits[0];

  return (
    <AppFrame title="Downloads" description="Grab the latest loader or browse historical builds. Everything is one click away.">
      <Card className="border-primary/30 mb-8">
        <CardHeader>
          <Badge variant="success" className="w-fit">Current</Badge>
          <CardTitle className="text-3xl">Latest Loader</CardTitle>
          <CardDescription>{latestCommit?.message || "Production build ready"}</CardDescription>
        </CardHeader>
        <CardContent className="flex gap-3">
          <Button size="lg" onClick={downloadLatestLoader}>
            <Download className="h-4 w-4 mr-2" /> Download
          </Button>
          <Button size="lg" variant="outline" onClick={async () => {
            try {
              const text = await currentLoaderText();
              await navigator.clipboard?.writeText(text);
              toast.success("Loader copied");
            } catch {
              toast.error("Failed to copy");
            }
          }}>
            <Copy className="h-4 w-4 mr-2" /> Copy
          </Button>
        </CardContent>
      </Card>

      <div>
        <div className="font-medium text-sm mb-3 text-muted-foreground px-1">HISTORY</div>
        <div className="space-y-[3px]">
          {(commits.data?.commits.length ? commits.data.commits : releases).slice(0, 7).map((r: any, idx: number) => ( // eslint-disable-line @typescript-eslint/no-explicit-any
            <div key={idx} className="flex items-center justify-between px-5 py-3.5 rounded-2xl border hover:bg-card/60 transition text-sm">
              <div className="flex items-center gap-4">
                <span className="font-mono text-xs text-primary/70 w-[72px]">{r.shortSha || r.version}</span>
                <span className="text-muted-foreground truncate max-w-[340px]">{String(r.message || (r.notes && r.notes.join(", ")) || "")}</span>
              </div>
              <div className="flex items-center gap-2">
                <Button size="sm" variant="ghost" onClick={async () => {
                  try { await navigator.clipboard.writeText(await currentLoaderText()); toast.success("Copied"); } catch {} 
                }}>Copy</Button>
                <Button size="sm" variant="ghost" onClick={downloadLatestLoader}>Download</Button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </AppFrame>
  );
}

export function ChangelogPage() {
  const commits = useQuery({ queryKey: ["github-commits"], queryFn: fetchGitHubCommits, refetchInterval: 60_000, retry: 1 });

  return (
    <AppFrame title="Changelog" description="Timeline layout with version badges, categories, expandable-style entries, search, and filtering-ready structure.">
      <div className="mb-4 flex gap-3"><Input placeholder="Search changelog..." /><Button variant="outline"><Search className="h-4 w-4" /> Filter</Button></div>
      <div className="grid gap-4">
        {(commits.data?.commits.length ? commits.data.commits : changelog.map((entry) => ({
          sha: entry.title,
          shortSha: entry.version,
          message: entry.description,
          htmlUrl: "#",
          syncedAt: new Date().toISOString(),
          fallback: true,
          committedAt: entry.date,
          author: entry.category
        }))).map((entry) => <Card key={entry.sha}><CardHeader><div className="flex flex-wrap gap-2"><Badge>{entry.shortSha}</Badge><Badge variant="secondary">{entry.author || "GitHub"}</Badge><Badge variant="muted">{formatCommitDate(entry.committedAt)}</Badge></div><CardTitle>{entry.message}</CardTitle><CardDescription>{entry.sha}{entry.htmlUrl !== "#" ? <Button asChild className="ml-2 h-7 px-2" size="sm" variant="ghost"><Link href={entry.htmlUrl} target="_blank"><ExternalLink className="h-3.5 w-3.5" /> GitHub</Link></Button> : null}</CardDescription></CardHeader></Card>)}
      </div>
    </AppFrame>
  );
}

export function FeaturesPage() {
  return (
    <AppFrame title="Features" description="Everything you need for a reliable and pleasant loader experience.">
      <div className="grid gap-4 md:grid-cols-2">
        {features.map((feature, i) => {
          const Icon = feature.icon;
          return (
            <Card key={i} className="hover:border-primary/30 transition">
              <CardHeader>
                <div className="inline-flex h-9 w-9 items-center justify-center rounded-2xl bg-primary/10 mb-4">
                  <Icon className="h-5 w-5 text-primary" />
                </div>
                <CardTitle>{feature.title}</CardTitle>
                <CardDescription>{feature.description}</CardDescription>
              </CardHeader>
            </Card>
          );
        })}
      </div>
    </AppFrame>
  );
}

export function SettingsPage() {
  return (
    <AppFrame title="Runtime preferences" description="Documented local preferences and reset actions. This page does not pretend to manage a hosted account.">
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {[
          ["GUI profile", "Current loader forces the V14 new GUI profile for stability."],
          ["Reduced motion", "Runtime controls use shorter, guarded animation timings."],
          ["Cache reset", "Clear generated BadWars cache files when source validation fails."],
          ["Diagnostics", "Open the in-game console when loader/runtime status reports an error."],
          ["Safe reporting", "Share visible errors, not local profile contents."],
          ["Layout recovery", "Use reset layout after moving windows off-screen."]
        ].map(([title, description]) => <Card key={title}><CardHeader><CheckCircle2 className="h-5 w-5 text-primary" /><CardTitle>{title}</CardTitle><CardDescription>{description}</CardDescription></CardHeader></Card>)}
      </div>
      <Card className="mt-5">
        <CardHeader><CardTitle>Cache-clear steps</CardTitle><CardDescription>Use this when the loader reports stale cache, bad compile output, or invalid profile state.</CardDescription></CardHeader>
        <CardContent className="grid gap-3 text-sm text-muted-foreground">
          <div className="rounded-2xl border bg-background/45 p-4">Delete generated `badscript/main.lua` and generated game bundle files, then run the latest loader again.</div>
          <div className="rounded-2xl border bg-background/45 p-4">Keep profile files unless the error points directly at profile JSON.</div>
          <Button variant="outline" onClick={() => toast.info("Cache steps copied", { description: "Use the downloads page for the current loader." })}>Copy troubleshooting summary</Button>
        </CardContent>
      </Card>
    </AppFrame>
  );
}

export function AdminPage() {
  return (
    <AppFrame title="Release validation" description="Public validation gates and maintenance notes. No fake admin tools or private controls are exposed.">
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {[
          ["Runtime validation", "Loader, GUI, route, cache, overlay, and branding checks."],
          ["Source validation", "Mojibake, patch artifacts, backup staging, secrets, and monolith warnings."],
          ["Website validation", "TypeScript, ESLint, and production Next.js build."],
          ["Roblox executor tests", "Still require a live Roblox/executor environment before final release signoff."],
          ["Rollback", "Use the previous Git commit if runtime smoke tests fail."],
          ["Cache clear", "Clear generated cache before retesting compile or route issues."]
        ].map(([title, description]) => <Card key={title}><CardHeader><CheckCircle2 className="h-5 w-5 text-primary" /><CardTitle>{title}</CardTitle><CardDescription>{description}</CardDescription></CardHeader></Card>)}
      </div>
    </AppFrame>
  );
}
