import { NextResponse } from "next/server";
import { checkRobloxStatus, getCachedRobloxStatus } from "@/lib/roblox-status";

export const dynamic = "force-dynamic";

export async function GET() {
  const cached = getCachedRobloxStatus();
  if (cached && Date.now() - new Date(cached.lastCheckedAt).getTime() < 120_000) {
    return NextResponse.json(cached);
  }
  const status = await checkRobloxStatus();
  return NextResponse.json(status);
}
