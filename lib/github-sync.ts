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
  committedAt?: string;
  author?: string;
};

type GitHubCommitApiItem = {
  sha: string;
  html_url?: string;
  commit?: {
    message?: string;
    author?: {
      name?: string;
      date?: string;
    };
  };
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
    const fallbackIsSha = /^[0-9a-f]{7,40}$/i.test(fallbackRef);
    return {
      sha: fallbackRef,
      shortSha: fallbackRef.slice(0, 7),
      message: "GitHub sync fallback",
      htmlUrl: fallbackIsSha
        ? `https://github.com/${githubRepo.owner}/${githubRepo.name}/commit/${fallbackRef}`
        : `https://github.com/${githubRepo.owner}/${githubRepo.name}/tree/${fallbackRef}`,
      syncedAt: new Date().toISOString(),
      fallback: true
    };
  }

  const data = await response.json() as GitHubCommitApiItem;

  return {
    sha: data.sha,
    shortSha: data.sha.slice(0, 7),
    message: data.commit?.message?.split("\n")[0] || "Latest GitHub commit",
    htmlUrl: data.html_url || `https://github.com/${githubRepo.owner}/${githubRepo.name}/commit/${data.sha}`,
    syncedAt: new Date().toISOString(),
    fallback: false,
    committedAt: data.commit?.author?.date,
    author: data.commit?.author?.name
  };
}

export async function getRecentGitHubCommits(fallbackRef: string, limit = 10): Promise<GitHubCommitInfo[]> {
  const response = await fetch(
    `https://api.github.com/repos/${githubRepo.owner}/${githubRepo.name}/commits?sha=${githubRepo.branch}&per_page=${limit}`,
    {
      headers: {
        Accept: "application/vnd.github+json",
        "User-Agent": "badwars-site"
      },
      cache: "no-store"
    }
  );

  if (!response.ok) {
    return [await getLatestGitHubCommit(fallbackRef)];
  }

  const data = await response.json() as GitHubCommitApiItem[];
  const syncedAt = new Date().toISOString();

  return data.map((item) => ({
    sha: item.sha,
    shortSha: item.sha.slice(0, 7),
    message: item.commit?.message?.split("\n")[0] || "GitHub commit",
    htmlUrl: item.html_url || `https://github.com/${githubRepo.owner}/${githubRepo.name}/commit/${item.sha}`,
    syncedAt,
    fallback: false,
    committedAt: item.commit?.author?.date,
    author: item.commit?.author?.name
  }));
}
