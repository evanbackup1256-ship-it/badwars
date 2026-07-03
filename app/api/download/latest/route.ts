import { NextRequest, NextResponse } from "next/server";
import { buildLoader, loaderFileName } from "@/lib/loader";

export const dynamic = "force-dynamic";

export function GET(request: NextRequest) {
  const origin = request.nextUrl.origin;
  const body = buildLoader(origin);

  return new NextResponse(body, {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Content-Disposition": `attachment; filename="${loaderFileName}"`,
      "Cache-Control": "no-store"
    }
  });
}
