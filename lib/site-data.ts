import {
  Bell,
  Boxes,
  ChartNoAxesCombined,
  CheckCircle2,
  Code2,
  Download,
  Flag,
  Gamepad2,
  History,
  KeyRound,
  LifeBuoy,
  Lock,
  Megaphone,
  Palette,
  Rocket,
  Search,
  ShieldCheck,
  Sparkles,
  Terminal,
  Users
} from "lucide-react";

export const navItems = [
  { label: "Home", href: "/" },
  { label: "Features", href: "/features" },
  { label: "Downloads", href: "/downloads" },
  { label: "Documentation", href: "/#documentation" },
  { label: "Support", href: "/#support" },
  { label: "Community", href: "/#community" },
  { label: "Changelog", href: "/changelog" }
];

export const features = [
  { icon: Rocket, title: "Latest-commit loader", description: "The site resolves the newest main commit and builds a clean loader before copy time.", tone: "primary" },
  { icon: Bell, title: "Roblox update watch", description: "Railway checks Roblox client version changes and feeds the website plus in-game warning layer.", tone: "secondary" },
  { icon: Gamepad2, title: "Game route detection", description: "Nested place routes are mapped so supported games stop falling through as unknown.", tone: "accent" },
  { icon: ShieldCheck, title: "Status-first runtime", description: "Startup stages surface useful context for GUI, security, universal, and game-module failures.", tone: "success" },
  { icon: Search, title: "Fuzzy support search", description: "Instant matching across games, features, releases, changelog entries, and support docs.", tone: "primary" },
  { icon: Palette, title: "Full theme system", description: "Dark-first polish with light mode, accent controls, reduced motion, and saved preferences.", tone: "secondary" }
];

export const games = [
  { name: "BedWars", status: "working", modules: 42, route: "bedwars/6872274481 - game/base.lua", tone: "#38bdf8", ids: ["6872274481", "6872265039", "8444591321", "8560631822"], description: "Flagship route with lobby, game, mega, and micro module coverage." },
  { name: "SkyWars Voxel", status: "working", modules: 18, route: "skywars voxel/8768229691 - skywars game/base.lua", tone: "#818cf8", ids: ["8768229691", "8542275097", "8592115909", "8951451142"], description: "Voxel suite with lobby, bridge, solo, duos, squads, and live match routes." },
  { name: "Bridge Duel", status: "working", modules: 10, route: "bridge duel/139566161526375 - game/base.lua", tone: "#fbbf24", ids: ["139566161526375"], description: "Compact duel route with clean startup diagnostics and arena-specific grouping." },
  { name: "Prison Life", status: "working", modules: 20, route: "prison life/155615604 - main/base.lua", tone: "#fb7185", ids: ["155615604", "135564683255158"], description: "Main and VC server routes mapped for cleaner reports." },
  { name: "Jailbreak", status: "testing", modules: 6, route: "jailbreak/606849621 - main/base.lua", tone: "#f472b6", ids: ["606849621"], description: "Testing route. Send status text after Roblox or game-side updates." },
  { name: "Universal", status: "working", modules: 72, route: "universal - base/bundle.lua", tone: "#34d399", ids: ["all games"], description: "Loads first and keeps the UI useful when a game-specific route is missing." }
];

export const releases = [
  { version: "2.0.0", channel: "Latest", date: "July 2026", checksum: "sha256: 5cc7...b9e1", notes: ["Next.js rebuild", "Roblox update API", "Dashboard shell", "Download center"] },
  { version: "1.8.4", channel: "Stable", date: "July 2026", checksum: "sha256: 92af...10dd", notes: ["Nested game routes", "New UI profile", "Loader warning layer"] },
  { version: "1.7.9", channel: "Legacy", date: "June 2026", checksum: "sha256: 08de...6a10", notes: ["Raw path fixes", "Universal bundle validation"] }
];

export const changelog = [
  { version: "2.0.0", category: "Website", title: "Premium Next.js launch", description: "Landing, dashboard, downloads, changelog, settings, admin shell, themes, and animations rebuilt.", date: "Jul 2026" },
  { version: "1.8.4", category: "Runtime", title: "Roblox warning layer", description: "Loader can read the website status API and warn when Roblox client versions move.", date: "Jul 2026" },
  { version: "1.8.3", category: "Routing", title: "Game detection repair", description: "Nested module paths are resolved for supported games that previously looked unknown.", date: "Jul 2026" },
  { version: "1.7.9", category: "Cache", title: "Raw GitHub paths fixed", description: "Spaces in game module paths are escaped before remote downloads.", date: "Jul 2026" }
];

export const activity = [
  { icon: CheckCircle2, title: "Runtime validation passed", detail: "Loader cache versions and module routing are synchronized." },
  { icon: Megaphone, title: "Announcement queued", detail: "Roblox update watch is now visible on the public website." },
  { icon: History, title: "Release 2.0.0 staged", detail: "Next.js site build and download center are ready." },
  { icon: LifeBuoy, title: "Support hint updated", detail: "Users are prompted to send place ID and visible status text." }
];

export const adminModules = [
  { icon: ChartNoAxesCombined, title: "Analytics", description: "Traffic, loader copies, route searches, and warning events." },
  { icon: Users, title: "User management", description: "Accounts, roles, sessions, device trust, and access history." },
  { icon: Megaphone, title: "Announcements", description: "Public notices, Roblox update banners, and maintenance windows." },
  { icon: Flag, title: "Feature flags", description: "Progressive rollout toggles for UI, runtime, and download flows." },
  { icon: Terminal, title: "Logs", description: "Status API checks, webhook dispatch, errors, and audit events." },
  { icon: Lock, title: "Audit trail", description: "Admin activity, role changes, and security-sensitive events." }
];

export const settingsSections = [
  { icon: Palette, title: "Theme", description: "Light, dark, system, and accent preferences." },
  { icon: Sparkles, title: "Animations", description: "Motion-safe transitions, reduced motion, and interface density." },
  { icon: Bell, title: "Notifications", description: "Success, info, warning, error, and progress events." },
  { icon: KeyRound, title: "Security", description: "Sessions, devices, password strength, and recovery options." },
  { icon: Code2, title: "Developer options", description: "API status, debug context, webhooks, and beta surfaces." },
  { icon: Boxes, title: "Privacy", description: "Data export, telemetry preferences, and account visibility." }
];
