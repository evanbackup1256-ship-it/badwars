import { WifiOff } from "lucide-react";
import { SystemState } from "@/components/system-state";

export default function OfflinePage() {
  return <SystemState code="OFFLINE" title="Network unavailable." description="Live services are out of reach. Cached loader links may still be available locally." icon={WifiOff} />;
}
