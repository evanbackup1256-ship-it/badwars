import { Wrench } from "lucide-react";
import { SystemState } from "@/components/system-state";

export default function MaintenancePage() {
  return <SystemState code="MAINT" title="Core under maintenance." description="BadWars is applying an update. Loader status will return when validation completes." icon={Wrench} />;
}
