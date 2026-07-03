import { NextResponse } from "next/server";
import { checkRobloxStatus } from "@/lib/roblox-status";

export const dynamic = "force-dynamic";

export async function GET() {
  const status = await checkRobloxStatus();
  return NextResponse.json(status);
}

export async function POST() {
  const status = await checkRobloxStatus();
  return NextResponse.json(status);
}
