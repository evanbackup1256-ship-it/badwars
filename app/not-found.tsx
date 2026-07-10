import { ScanSearch } from "lucide-react";
import { SystemState } from "@/components/system-state";

export default function NotFound() {
  return <SystemState code="404" title="Route not mapped." description="This coordinate is outside the BadWars command network." icon={ScanSearch} />;
}
