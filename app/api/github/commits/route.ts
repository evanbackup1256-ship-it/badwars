import { NextResponse } from "next/server";
import { getRecentGitHubCommits } from "@/lib/github-sync";
import { defaultLoaderRef } from "@/lib/loader";

export const dynamic = "force-dynamic";

export async function GET() {
  const commits = await getRecentGitHubCommits(defaultLoaderRef, 12);

  return NextResponse.json(
    { commits, syncedAt: new Date().toISOString() },
    {
      headers: {
        "Cache-Control": "no-store"
      }
    }
  );
}
