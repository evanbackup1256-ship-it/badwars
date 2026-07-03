type RobloxVersion = {
  version?: string;
  clientVersionUpload?: string;
  bootstrapperVersion?: string;
};

type RobloxStatus = {
  ok: boolean;
  changed: boolean;
  version: string | null;
  previousVersion: string | null;
  clientVersionUpload?: string;
  bootstrapperVersion?: string;
  channel: string;
  lastCheckedAt: string;
  lastChangedAt: string | null;
  warning: string;
};

const versionUrl = "https://clientsettingscdn.roblox.com/v2/client-version/WindowsPlayer";
const channelUrl = "https://clientsettings.roblox.com/v2/user-channel?binaryType=WindowsPlayer";

const globalStore = globalThis as typeof globalThis & {
  __badwarsRobloxStatus?: RobloxStatus;
};

async function fetchJson<T>(url: string): Promise<T> {
  const response = await fetch(url, {
    headers: { "User-Agent": "BadWarsStatus/2.0" },
    cache: "no-store"
  });
  if (!response.ok) throw new Error(`${url} returned ${response.status}`);
  return response.json() as Promise<T>;
}

async function sendWebhook(status: RobloxStatus) {
  const url = process.env.DISCORD_WEBHOOK_URL;
  if (!url) return;

  await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      username: "BadWars Watch",
      embeds: [
        {
          title: "Roblox client version changed",
          color: 0xffbf24,
          fields: [
            { name: "New version", value: status.version || "unknown", inline: true },
            { name: "Previous", value: status.previousVersion || "unknown", inline: true },
            { name: "Channel", value: status.channel || "LIVE", inline: true }
          ],
          timestamp: status.lastCheckedAt
        }
      ]
    })
  });
}

export async function checkRobloxStatus(): Promise<RobloxStatus> {
  const [version, channelResponse] = await Promise.allSettled([
    fetchJson<RobloxVersion>(versionUrl),
    fetchJson<{ channelName?: string }>(channelUrl)
  ]);

  if (version.status === "rejected") {
    const now = new Date().toISOString();
    return {
      ok: false,
      changed: false,
      version: globalStore.__badwarsRobloxStatus?.version || null,
      previousVersion: globalStore.__badwarsRobloxStatus?.previousVersion || null,
      channel: globalStore.__badwarsRobloxStatus?.channel || "unknown",
      lastCheckedAt: now,
      lastChangedAt: globalStore.__badwarsRobloxStatus?.lastChangedAt || null,
      warning: "Roblox status could not be checked. The loader can still run, but warnings may be delayed."
    };
  }

  const previous = globalStore.__badwarsRobloxStatus;
  const now = new Date().toISOString();
  const currentVersion = version.value.version || version.value.clientVersionUpload || "unknown";
  const changed = Boolean(previous?.version && previous.version !== currentVersion);
  const status: RobloxStatus = {
    ok: true,
    changed,
    version: currentVersion,
    previousVersion: changed ? previous?.version || null : previous?.previousVersion || null,
    clientVersionUpload: version.value.clientVersionUpload,
    bootstrapperVersion: version.value.bootstrapperVersion,
    channel: channelResponse.status === "fulfilled" ? channelResponse.value.channelName || "LIVE" : "LIVE",
    lastCheckedAt: now,
    lastChangedAt: changed ? now : previous?.lastChangedAt || null,
    warning: changed ? "Roblox updated recently. Test game-specific modules before trusting the build." : "Roblox client version is unchanged."
  };

  globalStore.__badwarsRobloxStatus = status;
  if (changed) {
    await sendWebhook(status).catch(() => undefined);
  }
  return status;
}

export function getCachedRobloxStatus() {
  return globalStore.__badwarsRobloxStatus;
}
