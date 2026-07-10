"use client";

import { AlertTriangle } from "lucide-react";
import { SystemState } from "@/components/system-state";

export default function ErrorPage({ reset }: { reset: () => void }) {
  return <SystemState code="500" title="Command interrupted." description="The console hit an unexpected error. Retry the current view to reconnect." icon={AlertTriangle} action="Retry view" onAction={reset} />;
}
