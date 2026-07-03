import { NextResponse } from "next/server";
import { defaultLoaderRef } from "@/lib/loader";
import { getLatestGitHubCommit } from "@/lib/github-sync";

export const dynamic = "force-dynamic";

export async function GET() {
  const commit = await getLatestGitHubCommit(defaultLoaderRef);

  return NextResponse.json(commit, {
    headers: {
      "Cache-Control": "no-store"
    }
  });
}
