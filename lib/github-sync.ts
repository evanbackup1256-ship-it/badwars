export const githubRepo = {
  owner: "evanbackup1256-ship-it",
  name: "badwars",
  branch: "main",
  loaderPath: "badscript/loader.lua"
};

export type GitHubCommitInfo = {
  sha: string;
  shortSha: string;
  message: string;
  htmlUrl: string;
  syncedAt: string;
  fallback: boolean;
};

export async function getLatestGitHubCommit(fallbackRef: string): Promise<GitHubCommitInfo> {
  const response = await fetch(
    `https://api.github.com/repos/${githubRepo.owner}/${githubRepo.name}/commits/${githubRepo.branch}`,
    {
      headers: {
        Accept: "application/vnd.github+json",
        "User-Agent": "badwars-site"
      },
      cache: "no-store"
    }
  );

  if (!response.ok) {
    return {
      sha: fallbackRef,
      shortSha: fallbackRef.slice(0, 7),
      message: "GitHub sync fallback",
      htmlUrl: `https://github.com/${githubRepo.owner}/${githubRepo.name}/commit/${fallbackRef}`,
      syncedAt: new Date().toISOString(),
      fallback: true
    };
  }

  const data = await response.json() as {
    sha: string;
    html_url?: string;
    commit?: { message?: string };
  };

  return {
    sha: data.sha,
    shortSha: data.sha.slice(0, 7),
    message: data.commit?.message?.split("\n")[0] || "Latest GitHub commit",
    htmlUrl: data.html_url || `https://github.com/${githubRepo.owner}/${githubRepo.name}/commit/${data.sha}`,
    syncedAt: new Date().toISOString(),
    fallback: false
  };
}
