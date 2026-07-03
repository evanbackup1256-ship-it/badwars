import { NextRequest, NextResponse } from "next/server";
import { buildLoader, defaultLoaderRef, loaderFileName } from "@/lib/loader";
import { getLatestGitHubCommit } from "@/lib/github-sync";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const origin = request.nextUrl.origin;
  const commit = await getLatestGitHubCommit(defaultLoaderRef);
  const body = buildLoader(origin, commit.sha);

  return new NextResponse(body, {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Content-Disposition": `attachment; filename="${loaderFileName}"`,
      "Cache-Control": "no-store",
      "X-BadWars-GitHub-Ref": commit.sha,
      "X-BadWars-GitHub-Fallback": String(commit.fallback)
    }
  });
}
