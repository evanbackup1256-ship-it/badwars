"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, ArrowRight, CheckCircle2, ChevronRight, ClipboardCheck, Copy, Download, ExternalLink, GitBranch, LayoutDashboard, RefreshCcw, Search, Wifi, Zap } from "lucide-react";
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
      <div className="site-wrap pt-32 pb-16">
        <div className="grid gap-8 lg:grid-cols-[260px_1fr]">
          <aside className="hidden lg:block">
            <div className="sticky top-24">
              <div className="uppercase tracking-[2px] text-[10px] font-semibold text-muted-foreground mb-4 px-3">Console</div>
              <nav className="space-y-1">
                {sidebar.map((item) => {
                  const Icon = item.icon;
                  return (
                    <motion.div
                      key={item.href}
                      whileHover={{ x: 4 }}
                      whileTap={{ scale: 0.98 }}
                    >
                      <Link 
                        href={item.href} 
                        className="flex items-center gap-3 rounded-xl px-4 py-3 text-sm hover:bg-primary/10 transition-all text-muted-foreground hover:text-foreground group"
                      >
                        <Icon className="h-4 w-4 group-hover:text-primary transition-colors" />
                        {item.label}
                      </Link>
                    </motion.div>
                  );
                })}
              </nav>
            </div>
          </aside>

          <main>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="mb-8"
            >
              <Badge className="mb-3 bg-primary/10 border-primary/30 text-primary">BadWars Console</Badge>
              <h1 className="font-display text-5xl font-black tracking-tight">{title}</h1>
              <p className="mt-3 text-lg text-muted-foreground max-w-2xl">{description}</p>
            </motion.div>
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
      label: "API Health",
      value: health.data?.ok ? "Online" : health.isLoading ? "Checking" : "Offline",
      detail: health.data?.checkedAt ? `Checked ${formatRelativeTime(health.data.checkedAt)}` : "Live endpoint",
      color: "from-primary/20 to-primary/5"
    },
    {
      icon: AlertTriangle,
      label: "Roblox Status",
      value: roblox.data?.changed ? "Update" : roblox.data?.ok ? "Clear" : "Unknown",
      detail: roblox.data?.version || "Client version",
      color: "from-secondary/20 to-secondary/5"
    },
    {
      icon: Download,
      label: "Latest Release",
      value: releases[0].version,
      detail: releases[0].checksum,
      color: "from-accent/20 to-accent/5"
    },
    {
      icon: LayoutDashboard,
      label: "Supported Games",
      value: String(games.length),
      detail: `${games.filter((game) => game.status === "working").length} Working`,
      color: "from-primary/20 to-secondary/5"
    }
  ];

  const copyDashboardLoader = async () => {
    await navigator.clipboard?.writeText(await currentLoaderText());
    toast.success("Loader copied", { description: "The production loader was copied from the dashboard." });
  };

  return (
    <AppFrame title="Dashboard" description="Live status, quick actions, and runtime insights.">
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {dashboardStats.map((widget, index) => {
          const Icon = widget.icon;
          return (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              key={widget.label}
            >
              <Card className="premium-card h-full">
                <CardHeader className="pb-4">
                  <div className={`inline-flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br ${widget.color} mb-3`}>
                    <Icon className="h-5 w-5 text-primary" />
                  </div>
                  <div className="text-xs uppercase tracking-wider text-muted-foreground font-semibold">{widget.label}</div>
                  <CardTitle className="text-3xl font-black mt-2">{widget.value}</CardTitle>
                  <CardDescription className="text-xs mt-1">{widget.detail}</CardDescription>
                </CardHeader>
              </Card>
            </motion.div>
          );
        })}
      </div>

      <div className="mt-8 grid gap-6 xl:grid-cols-[1fr_.8fr]">
        <Card>
          <CardHeader>
            <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <CardTitle>Activity Feed</CardTitle>
                <CardDescription>Runtime and product events</CardDescription>
              </div>
              <Input 
                className="lg:max-w-xs" 
                placeholder="Search activity..." 
                value={activityQuery} 
                onChange={(event) => setActivityQuery(event.target.value)} 
              />
            </div>
          </CardHeader>
          <CardContent className="grid gap-3">
            {filteredActivity.map((item, i) => {
              const Icon = item.icon;
              return (
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.05 }}
                  className="flex gap-4 rounded-xl border bg-background/50 p-4 hover:border-primary/30 transition-colors"
                  key={item.title}
                >
                  <div className="flex-shrink-0">
                    <Icon className="h-5 w-5 text-primary mt-1" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold mb-1">{item.title}</div>
                    <p className="text-sm text-muted-foreground">{item.detail}</p>
                  </div>
                </motion.div>
              );
            })}
            {!filteredActivity.length && (
              <div className="rounded-xl border border-dashed p-8 text-center text-sm text-muted-foreground">
                No activity matches your search.
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <Badge variant={roblox.data?.changed ? "warning" : "success"} className="w-fit mb-3">
              {roblox.data?.changed ? "Update Detected" : "Operational"}
            </Badge>
            <CardTitle>Roblox Watch</CardTitle>
            <CardDescription>{roblox.data?.warning || "Live status monitoring"}</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-4">
            <div className="grid gap-3 rounded-xl border bg-background/50 p-4 text-sm">
              <div className="flex justify-between gap-3">
                <span className="text-muted-foreground">Channel</span>
                <strong>{roblox.data?.channel || "LIVE"}</strong>
              </div>
              <div className="flex justify-between gap-3">
                <span className="text-muted-foreground">Version</span>
                <strong className="truncate font-mono">{roblox.data?.version || "checking"}</strong>
              </div>
              <div className="flex justify-between gap-3">
                <span className="text-muted-foreground">Last Check</span>
                <strong>{formatRelativeTime(roblox.data?.lastCheckedAt)}</strong>
              </div>
            </div>
            <Button onClick={() => roblox.refetch()} className="gap-2">
              <RefreshCcw className="h-4 w-4" />
              Refresh Status
            </Button>
          </CardContent>
        </Card>
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-[.9fr_1.1fr]">
        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
            <CardDescription>Deploy and manage your loader</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3 sm:grid-cols-2">
            <Button onClick={copyDashboardLoader} className="gap-2">
              <ClipboardCheck className="h-4 w-4" />
              Copy Loader
            </Button>
            <Button 
              variant="outline" 
              onClick={() => { downloadLatestLoader(); toast.success("Download started", { description: loaderFileName }); }}
              className="gap-2"
            >
              <Download className="h-4 w-4" />
              Download
            </Button>
            <Button variant="outline" onClick={() => health.refetch()} className="gap-2">
              <RefreshCcw className="h-4 w-4" />
              Refresh Health
            </Button>
            <Button asChild variant="outline" className="gap-2">
              <Link href="/downloads">
                <ExternalLink className="h-4 w-4" />
                Downloads
              </Link>
            </Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Latest Commit</CardTitle>
            <CardDescription>Live from GitHub</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-4">
            <div className="rounded-xl border bg-background/50 p-5">
              <div className="font-display text-2xl font-black mb-2">
                {commits.data?.commits[0]?.shortSha || releases[0].version}
              </div>
              <div className="text-sm text-muted-foreground">
                {commits.data?.commits[0]?.message || releases[0].notes.join(", ")}
              </div>
            </div>
            <div className="text-sm text-muted-foreground">
              Synced {formatRelativeTime(commits.data?.syncedAt)}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Validation Gates</CardTitle>
            <CardDescription>Release checks enforced</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            {["Runtime validation", "Source validation", "TypeScript", "ESLint", "Production build"].map((item) => (
              <div 
                className="flex items-center justify-between gap-3 rounded-xl border bg-background/50 p-4" 
                key={item}
              >
                <span className="font-semibold text-sm">{item}</span>
                <Badge variant="success" className="text-xs">Pass</Badge>
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Supported Games</CardTitle>
            <CardDescription>Route inventory</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            {games.slice(0, 5).map((game) => (
              <div 
                className="flex items-center justify-between gap-3 rounded-xl border bg-background/50 p-4" 
                key={game.name}
              >
                <div className="min-w-0 flex-1">
                  <div className="font-semibold text-sm truncate">{game.name}</div>
                  <div className="text-xs text-muted-foreground font-mono">{game.ids[0]}</div>
                </div>
                <Badge variant={game.status === "working" ? "success" : "warning"} className="text-xs">
                  {game.status}
                </Badge>
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Support Checklist</CardTitle>
            <CardDescription>For reporting issues</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            {["Visible status text", "Place ID and route", "Console error", "Cache cleared"].map((item) => (
              <div 
                className="rounded-xl border bg-background/50 p-4 text-sm font-semibold flex items-center gap-3" 
                key={item}
              >
                <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0" />
                {item}
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </AppFrame>
  );
}

export function ProfilePage() {
  return (
    <AppFrame title="Support Profile" description="Public context for diagnostics. No account data shown.">
      <div className="grid gap-6 xl:grid-cols-[.8fr_1.2fr]">
        <Card>
          <CardHeader>
            <Badge variant="secondary" className="w-fit mb-3">Support Identity</Badge>
            <CardTitle>What to Include</CardTitle>
            <CardDescription>Essential information for diagnosing loader issues</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            {["Visible loader status text", "Place ID and game route", "BadWars version and commit", "Developer Console error text"].map((item) => (
              <div 
                className="rounded-xl border bg-background/50 p-4 text-sm font-semibold flex items-center gap-3" 
                key={item}
              >
                <CheckCircle2 className="h-4 w-4 text-primary flex-shrink-0" />
                {item}
              </div>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Local Runtime Data</CardTitle>
            <CardDescription>Files that stay on your system</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3">
            {["badscript/profiles/*.txt", "badwars_translations/*.json", "badscript/profiles/commit.txt"].map((item) => (
              <div 
                className="flex items-center gap-3 rounded-xl border bg-background/50 p-4" 
                key={item}
              >
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <CheckCircle2 className="h-4 w-4 text-primary" />
                </div>
                <span className="font-mono text-sm">{item}</span>
              </div>
            ))}
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
    <AppFrame title="Downloads" description="Get the latest loader or browse historical builds.">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
      >
        <Card className="border-primary/30 bg-gradient-to-br from-primary/10 via-card to-secondary/10 mb-8">
          <CardHeader>
            <Badge variant="success" className="w-fit mb-3">Current Release</Badge>
            <CardTitle className="text-3xl font-display">Latest Loader</CardTitle>
            <CardDescription className="text-base">
              {latestCommit?.message || "Production build ready"}
            </CardDescription>
          </CardHeader>
          <CardContent className="flex flex-wrap gap-3">
            <Button 
              size="lg" 
              onClick={downloadLatestLoader}
              className="gap-2 bg-gradient-to-r from-primary to-secondary hover:from-primary/90 hover:to-secondary/90"
            >
              <Download className="h-5 w-5" />
              Download
            </Button>
            <Button 
              size="lg" 
              variant="outline" 
              onClick={async () => {
                try {
                  const text = await currentLoaderText();
                  await navigator.clipboard?.writeText(text);
                  toast.success("Loader copied");
                } catch {
                  toast.error("Failed to copy");
                }
              }}
              className="gap-2"
            >
              <Copy className="h-5 w-5" />
              Copy
            </Button>
          </CardContent>
        </Card>
      </motion.div>

      <div>
        <div className="font-semibold text-sm mb-4 text-muted-foreground uppercase tracking-wider">History</div>
        <div className="space-y-2">
          {(commits.data?.commits.length ? commits.data.commits : releases).slice(0, 8).map((r: any, idx: number) => (
            <motion.div
              key={idx}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: idx * 0.05 }}
              className="flex items-center justify-between px-5 py-4 rounded-xl border hover:border-primary/30 hover:bg-card/60 transition-all text-sm group"
            >
              <div className="flex items-center gap-4 flex-1 min-w-0">
                <span className="font-mono text-xs text-primary font-semibold w-[80px] flex-shrink-0">
                  {r.shortSha || r.version}
                </span>
                <span className="text-muted-foreground truncate">
                  {String(r.message || (r.notes && r.notes.join(", ")) || "")}
                </span>
              </div>
              <div className="flex items-center gap-2 flex-shrink-0 ml-4">
                <Button 
                  size="sm" 
                  variant="ghost" 
                  onClick={async () => {
                    try { 
                      await navigator.clipboard.writeText(await currentLoaderText()); 
                      toast.success("Copied"); 
                    } catch {} 
                  }}
                  className="opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  Copy
                </Button>
                <Button 
                  size="sm" 
                  variant="ghost" 
                  onClick={downloadLatestLoader}
                  className="opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  Download
                </Button>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </AppFrame>
  );
}

export function ChangelogPage() {
  const commits = useQuery({ queryKey: ["github-commits"], queryFn: fetchGitHubCommits, refetchInterval: 60_000, retry: 1 });

  return (
    <AppFrame title="Changelog" description="Version history and updates.">
      <div className="mb-6 flex gap-3">
        <Input placeholder="Search changelog..." className="max-w-md" />
        <Button variant="outline" className="gap-2">
          <Search className="h-4 w-4" />
          Filter
        </Button>
      </div>

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
        }))).map((entry, i) => (
          <motion.div
            key={entry.sha}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.05 }}
          >
            <Card className="premium-card">
              <CardHeader>
                <div className="flex flex-wrap gap-2 mb-3">
                  <Badge className="bg-primary/10 text-primary border-primary/30">{entry.shortSha}</Badge>
                  <Badge variant="secondary">{entry.author || "GitHub"}</Badge>
                  <Badge variant="muted">{formatCommitDate(entry.committedAt)}</Badge>
                </div>
                <CardTitle className="text-lg">{entry.message}</CardTitle>
                <CardDescription className="mt-2">
                  {entry.sha}
                  {entry.htmlUrl !== "#" && (
                    <Button 
                      asChild 
                      className="ml-3 h-7 px-3" 
                      size="sm" 
                      variant="ghost"
                    >
                      <Link href={entry.htmlUrl} target="_blank" className="gap-1">
                        <GitBranch className="h-3.5 w-3.5" />
                        GitHub
                      </Link>
                    </Button>
                  )}
                </CardDescription>
              </CardHeader>
            </Card>
          </motion.div>
        ))}
      </div>
    </AppFrame>
  );
}

export function FeaturesPage() {
  return (
    <AppFrame title="Features" description="Everything you need for a reliable loader experience.">
      <div className="grid gap-6 md:grid-cols-2">
        {features.map((feature, i) => {
          const Icon = feature.icon;
          return (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.05 }}
            >
              <Card className="premium-card h-full">
                <CardHeader>
                  <div className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-primary/20 to-secondary/20 mb-4">
                    <Icon className="h-6 w-6 text-primary" />
                  </div>
                  <CardTitle className="text-xl">{feature.title}</CardTitle>
                  <CardDescription className="text-base">{feature.description}</CardDescription>
                </CardHeader>
              </Card>
            </motion.div>
          );
        })}
      </div>
    </AppFrame>
  );
}

export function SettingsPage() {
  return (
    <AppFrame title="Preferences" description="Local settings and troubleshooting.">
      <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        {[
          ["GUI Profile", "Current loader forces the V19 GUI profile"],
          ["Reduced Motion", "Shorter animation timings"],
          ["Cache Reset", "Clear generated cache files"],
          ["Diagnostics", "Open in-game console on errors"],
          ["Safe Reporting", "Share visible errors only"],
          ["Layout Recovery", "Reset off-screen windows"]
        ].map(([title, description], i) => (
          <motion.div
            key={title}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: i * 0.05 }}
          >
            <Card className="premium-card h-full">
              <CardHeader>
                <div className="h-10 w-10 rounded-xl bg-primary/10 flex items-center justify-center mb-3">
                  <CheckCircle2 className="h-5 w-5 text-primary" />
                </div>
                <CardTitle>{title}</CardTitle>
                <CardDescription>{description}</CardDescription>
              </CardHeader>
            </Card>
          </motion.div>
        ))}
      </div>

      <Card className="mt-8">
        <CardHeader>
          <CardTitle>Cache Clear Steps</CardTitle>
          <CardDescription>When to clear generated files</CardDescription>
        </CardHeader>
        <CardContent className="grid gap-4 text-sm">
          <div className="rounded-xl border bg-background/50 p-5">
            Delete generated <code className="font-mono text-primary">badscript/main.lua</code> and game bundle files, then run the latest loader again.
          </div>
          <div className="rounded-xl border bg-background/50 p-5">
            Keep profile files unless the error points directly at profile JSON.
          </div>
          <Button 
            variant="outline" 
            onClick={() => toast.info("Cache steps copied", { description: "Use the downloads page for the current loader." })}
          >
            Copy Troubleshooting Summary
          </Button>
        </CardContent>
      </Card>
    </AppFrame>
  );
}

export function AdminPage() {
  return (
    <AppFrame title="Validation" description="Release gates and maintenance notes.">
      <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
        {[
          ["Runtime Validation", "Loader, GUI, route, and branding checks"],
          ["Source Validation", "Mojibake, patches, and secrets detection"],
          ["Website Validation", "TypeScript, ESLint, and Next.js build"],
          ["Executor Tests", "Live Roblox environment required"],
          ["Rollback", "Use previous commit if tests fail"],
          ["Cache Clear", "Clear before retesting compile issues"]
        ].map(([title, description], i) => (
          <motion.div
            key={title}
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: i * 0.05 }}
          >
            <Card className="premium-card h-full">
              <CardHeader>
                <div className="h-10 w-10 rounded-xl bg-primary/10 flex items-center justify-center mb-3">
                  <CheckCircle2 className="h-5 w-5 text-primary" />
                </div>
                <CardTitle>{title}</CardTitle>
                <CardDescription>{description}</CardDescription>
              </CardHeader>
            </Card>
          </motion.div>
        ))}
      </div>
    </AppFrame>
  );
}
