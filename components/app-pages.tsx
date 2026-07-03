"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { useQuery } from "@tanstack/react-query";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { AlertTriangle, Bell, CheckCircle2, ClipboardCheck, Copy, Download, ExternalLink, Home, KeyRound, LayoutDashboard, RefreshCcw, Search, Shield, SlidersHorizontal, Trash2, UploadCloud, UserRound, Wifi } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { SiteNav, Footer } from "@/components/site-shell";
import { buildLoader, loaderFileName } from "@/lib/loader";
import { activity, adminModules, changelog, features, games, releases, settingsSections } from "@/lib/site-data";
import { formatRelativeTime } from "@/lib/utils";

const sidebar = [
  { label: "Overview", href: "/dashboard", icon: LayoutDashboard },
  { label: "Downloads", href: "/downloads", icon: Download },
  { label: "Profile", href: "/profile", icon: UserRound },
  { label: "Settings", href: "/settings", icon: SlidersHorizontal },
  { label: "Admin", href: "/admin", icon: Shield }
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

function currentLoaderText() {
  return buildLoader(typeof window === "undefined" ? "https://badwars-production.up.railway.app" : window.location.origin);
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

function AppFrame({ title, description, children }: { title: string; description: string; children: React.ReactNode }) {
  return (
    <>
      <SiteNav />
      <main className="site-wrap grid gap-5 py-10 lg:grid-cols-[250px_1fr]">
        <aside className="glass sticky top-24 hidden h-fit rounded-2xl border p-3 lg:block">
          <div className="mb-3 flex items-center gap-2 px-2 text-sm text-muted-foreground"><Home className="h-4 w-4" /> BadWars Console</div>
          <nav className="grid gap-1">
            {sidebar.map((item) => {
              const Icon = item.icon;
              return <Link className="flex items-center gap-2 rounded-xl px-3 py-2 text-sm text-muted-foreground transition hover:bg-muted hover:text-foreground" href={item.href} key={item.href}><Icon className="h-4 w-4" /> {item.label}</Link>;
            })}
          </nav>
        </aside>
        <section className="min-w-0">
          <div className="mb-6">
            <Badge>Console</Badge>
            <h1 className="mt-3 font-display text-4xl font-black md:text-6xl">{title}</h1>
            <p className="mt-3 max-w-2xl text-muted-foreground">{description}</p>
          </div>
          {children}
        </section>
      </main>
      <Footer />
    </>
  );
}

export function DashboardPage() {
  const health = useQuery({ queryKey: ["dashboard-health"], queryFn: fetchHealth, refetchInterval: 30_000 });
  const roblox = useQuery({ queryKey: ["dashboard-roblox"], queryFn: fetchRobloxStatus, refetchInterval: 120_000 });
  const [activityQuery, setActivityQuery] = useState("");
  const [downloadProgress, setDownloadProgress] = useState(0);
  const [notifications, setNotifications] = useState([
    { type: "success", title: "Runtime validation passed", detail: "All local checks are green." },
    { type: "info", title: "Dashboard online", detail: "Live widgets are polling production APIs." }
  ]);
  const [flags, setFlags] = useState([
    { key: "new-ui", label: "New UI profile", enabled: true },
    { key: "roblox-watch", label: "Roblox update watch", enabled: true },
    { key: "beta-downloads", label: "Beta download flow", enabled: false }
  ]);

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

  const addNotification = (title: string, detail: string, type = "info") => {
    setNotifications((current) => [{ title, detail, type }, ...current].slice(0, 6));
    toast(title, { description: detail });
  };

  const copyDashboardLoader = async () => {
    await navigator.clipboard?.writeText(currentLoaderText());
    addNotification("Loader copied", "The production loader was copied from the dashboard.", "success");
  };

  const startDownload = () => {
    setDownloadProgress(8);
    addNotification("Download started", "Preparing BadWars latest release.", "info");
    const timer = window.setInterval(() => {
      setDownloadProgress((value) => {
        const next = Math.min(100, value + 14);
        if (next >= 100) {
          window.clearInterval(timer);
          downloadLatestLoader();
          toast.success("Download ready", { description: "Latest release package finished preparing." });
        }
        return next;
      });
    }, 280);
  };

  return (
    <AppFrame title="Dashboard" description="A working command console with live status, quick actions, downloads, notifications, activity search, feature flags, and support context.">
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {dashboardStats.map((widget, index) => {
          const Icon = widget.icon;
          return (
            <motion.div initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.04 }} key={widget.label}>
              <Card><CardHeader><Icon className="h-5 w-5 text-primary" /><CardTitle>{widget.value}</CardTitle><CardDescription>{widget.label} · {widget.detail}</CardDescription></CardHeader></Card>
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
            <Button variant="outline" onClick={() => addNotification("Test notification", "Dashboard notifications are working.", "info")}><Bell className="h-4 w-4" /> Send test notification</Button>
          </CardContent>
        </Card>
      </div>

      <div className="mt-5 grid gap-4 xl:grid-cols-[.85fr_1.15fr]">
        <Card>
          <CardHeader>
            <CardTitle>Quick actions</CardTitle>
            <CardDescription>Actions are wired with copy, refresh, notification, and route behavior.</CardDescription>
          </CardHeader>
          <CardContent className="grid gap-3 sm:grid-cols-2">
            <Button onClick={copyDashboardLoader}><ClipboardCheck className="h-4 w-4" /> Copy loader</Button>
            <Button variant="outline" onClick={startDownload}><UploadCloud className="h-4 w-4" /> Download latest</Button>
            <Button variant="outline" onClick={() => health.refetch()}><RefreshCcw className="h-4 w-4" /> Refresh health</Button>
            <Button asChild variant="outline"><Link href="/downloads"><ExternalLink className="h-4 w-4" /> Download center</Link></Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Download manager</CardTitle>
            <CardDescription>Latest release preparation with progress and checksum context.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="mb-3 flex flex-wrap items-center justify-between gap-3">
              <div>
                <div className="font-display text-2xl font-black">{releases[0].version}</div>
                <div className="text-sm text-muted-foreground">{releases[0].checksum}</div>
              </div>
              <Badge variant={downloadProgress === 100 ? "success" : downloadProgress > 0 ? "secondary" : "muted"}>{downloadProgress === 100 ? "Ready" : downloadProgress > 0 ? "Preparing" : "Idle"}</Badge>
            </div>
            <div className="h-3 overflow-hidden rounded-full bg-muted">
              <motion.div className="h-full rounded-full bg-primary" animate={{ width: `${downloadProgress}%` }} transition={{ type: "spring", stiffness: 80, damping: 18 }} />
            </div>
            <div className="mt-3 text-sm text-muted-foreground">{downloadProgress}% complete</div>
          </CardContent>
        </Card>
      </div>

      <div className="mt-5 grid gap-4 xl:grid-cols-3">
        <Card>
          <CardHeader><CardTitle>Notifications</CardTitle><CardDescription>Stacking dashboard notification state.</CardDescription></CardHeader>
          <CardContent className="grid gap-3">
            {notifications.map((item, index) => <div className="rounded-2xl border bg-background/45 p-4" key={`${item.title}-${index}`}><Badge variant={item.type === "success" ? "success" : item.type === "warning" ? "warning" : "secondary"}>{item.type}</Badge><div className="mt-2 font-bold">{item.title}</div><p className="text-sm text-muted-foreground">{item.detail}</p></div>)}
            <Button variant="outline" onClick={() => setNotifications([])}><Trash2 className="h-4 w-4" /> Clear notifications</Button>
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Feature flags</CardTitle><CardDescription>Toggle runtime-facing UI states locally.</CardDescription></CardHeader>
          <CardContent className="grid gap-3">
            {flags.map((flag) => (
              <button type="button" className="flex items-center justify-between rounded-2xl border bg-background/45 p-4 text-left transition hover:bg-muted" key={flag.key} onClick={() => setFlags((current) => current.map((item) => item.key === flag.key ? { ...item, enabled: !item.enabled } : item))}>
                <span><span className="block font-bold">{flag.label}</span><span className="text-sm text-muted-foreground">{flag.enabled ? "Enabled" : "Disabled"}</span></span>
                <span className={`h-6 w-11 rounded-full p-1 transition ${flag.enabled ? "bg-primary" : "bg-muted"}`}><span className={`block h-4 w-4 rounded-full bg-background transition ${flag.enabled ? "translate-x-5" : ""}`} /></span>
              </button>
            ))}
          </CardContent>
        </Card>

        <Card>
          <CardHeader><CardTitle>Support queue</CardTitle><CardDescription>Actionable reports users should send.</CardDescription></CardHeader>
          <CardContent className="grid gap-3">
            {games.slice(0, 4).map((game) => <div className="flex items-center justify-between gap-3 rounded-2xl border bg-background/45 p-4" key={game.name}><div><div className="font-bold">{game.name}</div><div className="text-xs text-muted-foreground">{game.ids[0]}</div></div><Badge variant={game.status === "working" ? "success" : "warning"}>{game.status}</Badge></div>)}
          </CardContent>
        </Card>
      </div>
    </AppFrame>
  );
}

export function ProfilePage() {
  return (
    <AppFrame title="Profile" description="Avatar, statistics, badges, devices, sessions, preferences, and security layout.">
      <div className="grid gap-4 xl:grid-cols-[.75fr_1fr]">
        <Card>
          <CardHeader className="items-center text-center">
            <div className="grid h-24 w-24 place-items-center rounded-full bg-primary/15 text-3xl font-black text-primary">BW</div>
            <CardTitle>BadWars Member</CardTitle>
            <CardDescription>Premium dashboard profile placeholder</CardDescription>
          </CardHeader>
          <CardContent className="grid grid-cols-3 gap-3 text-center">
            {["12 badges", "4 devices", "98% health"].map((item) => <div className="rounded-2xl border p-3 text-sm font-bold" key={item}>{item}</div>)}
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>Security and sessions</CardTitle><CardDescription>Device trust, active sessions, and account protections.</CardDescription></CardHeader>
          <CardContent className="grid gap-3">
            {["Windows desktop · active now", "Mobile browser · 2 days ago", "Recovery codes · configured"].map((item) => <div className="flex items-center gap-3 rounded-2xl border p-4" key={item}><CheckCircle2 className="h-5 w-5 text-emerald-300" /> {item}</div>)}
          </CardContent>
        </Card>
      </div>
    </AppFrame>
  );
}

export function DownloadsPage() {
  return (
    <AppFrame title="Download center" description="Version history, release notes, system requirements, checksum display, copy buttons, and latest release highlight.">
      <Card className="mb-5 border-primary/40">
        <CardHeader><Badge>Latest release</Badge><CardTitle>BadWars 2.0.0</CardTitle><CardDescription>Next.js site, live status API, dashboard shell, and runtime routing fixes.</CardDescription></CardHeader>
        <CardContent className="flex flex-wrap gap-3"><Button onClick={() => { downloadLatestLoader(); toast.success("Download started", { description: loaderFileName }); }}><Download className="h-4 w-4" /> Download latest</Button><Button variant="outline" onClick={async () => { await navigator.clipboard?.writeText(releases[0].checksum); toast.success("Checksum copied"); }}><Copy className="h-4 w-4" /> Copy checksum</Button></CardContent>
      </Card>
      <div className="grid gap-4">
        {releases.map((release) => (
          <Card key={release.version}>
            <CardHeader><div className="flex flex-wrap items-center justify-between gap-3"><CardTitle>{release.version}</CardTitle><Badge variant={release.channel === "Latest" ? "success" : "muted"}>{release.channel}</Badge></div><CardDescription>{release.date} · {release.checksum}</CardDescription></CardHeader>
            <CardContent><ul className="grid gap-2 text-sm text-muted-foreground">{release.notes.map((note) => <li key={note}>• {note}</li>)}</ul><div className="mt-4 flex flex-wrap gap-2"><Button size="sm" onClick={() => { downloadLatestLoader(); toast.success(`${release.version} download started`); }}><Download className="h-4 w-4" /> Download</Button><Button size="sm" variant="outline" onClick={async () => { await navigator.clipboard?.writeText(release.checksum); toast.success("Checksum copied"); }}><Copy className="h-4 w-4" /> Checksum</Button></div></CardContent>
          </Card>
        ))}
      </div>
    </AppFrame>
  );
}

export function ChangelogPage() {
  return (
    <AppFrame title="Changelog" description="Timeline layout with version badges, categories, expandable-style entries, search, and filtering-ready structure.">
      <div className="mb-4 flex gap-3"><Input placeholder="Search changelog..." /><Button variant="outline"><Search className="h-4 w-4" /> Filter</Button></div>
      <div className="grid gap-4">
        {changelog.map((entry) => <Card key={entry.title}><CardHeader><div className="flex flex-wrap gap-2"><Badge>{entry.version}</Badge><Badge variant="secondary">{entry.category}</Badge><Badge variant="muted">{entry.date}</Badge></div><CardTitle>{entry.title}</CardTitle><CardDescription>{entry.description}</CardDescription></CardHeader></Card>)}
      </div>
    </AppFrame>
  );
}

export function FeaturesPage() {
  return (
    <AppFrame title="Features" description="Feature comparison, performance charts, animation-ready sections, and premium launcher UX.">
      <div className="grid gap-4 md:grid-cols-2">
        {features.map((feature) => {
          const Icon = feature.icon;
          return <Card key={feature.title}><CardHeader><Icon className="h-6 w-6 text-primary" /><CardTitle>{feature.title}</CardTitle><CardDescription>{feature.description}</CardDescription></CardHeader></Card>;
        })}
      </div>
      <Card className="mt-5"><CardHeader><CardTitle>Performance chart</CardTitle><CardDescription>Placeholder chart area for launch metrics, loader copies, route searches, and warnings.</CardDescription></CardHeader><CardContent><div className="grid h-64 place-items-center rounded-2xl border bg-muted/35 text-muted-foreground">Chart surface ready</div></CardContent></Card>
    </AppFrame>
  );
}

const settingsSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, "Use at least 8 characters")
});

export function SettingsPage() {
  const form = useForm<z.infer<typeof settingsSchema>>({ resolver: zodResolver(settingsSchema), defaultValues: { email: "user@badwars.local", password: "" } });
  return (
    <AppFrame title="Settings" description="Theme, accent color, animation preferences, notifications, privacy, account, security, and developer options.">
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {settingsSections.map((section) => { const Icon = section.icon; return <Card key={section.title}><CardHeader><Icon className="h-5 w-5 text-primary" /><CardTitle>{section.title}</CardTitle><CardDescription>{section.description}</CardDescription></CardHeader></Card>; })}
      </div>
      <Card className="mt-5">
        <CardHeader><CardTitle>Security form</CardTitle><CardDescription>React Hook Form plus Zod validation with inline errors.</CardDescription></CardHeader>
        <CardContent>
          <form className="grid gap-4 md:grid-cols-2" onSubmit={form.handleSubmit(() => toast.success("Settings saved"))}>
            <label className="grid gap-2 text-sm font-bold">Email<Input {...form.register("email")} />{form.formState.errors.email ? <span className="text-xs text-destructive">{form.formState.errors.email.message}</span> : null}</label>
            <label className="grid gap-2 text-sm font-bold">Password<Input type="password" {...form.register("password")} />{form.formState.errors.password ? <span className="text-xs text-destructive">{form.formState.errors.password.message}</span> : null}</label>
            <Button className="md:col-span-2" type="submit"><KeyRound className="h-4 w-4" /> Save preferences</Button>
          </form>
        </CardContent>
      </Card>
    </AppFrame>
  );
}

export function AdminPage() {
  return (
    <AppFrame title="Admin panel" description="Advanced admin dashboard shell for analytics, users, announcements, flags, downloads, logs, reports, audit trail, and roles.">
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {adminModules.map((module) => { const Icon = module.icon; return <Card key={module.title}><CardHeader><Icon className="h-5 w-5 text-primary" /><CardTitle>{module.title}</CardTitle><CardDescription>{module.description}</CardDescription></CardHeader></Card>; })}
      </div>
    </AppFrame>
  );
}
