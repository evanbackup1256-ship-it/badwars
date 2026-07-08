import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Wrench } from "lucide-react";

export default function MaintenancePage() {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <div className="max-w-xl w-full">
        <Card className="text-center">
          <CardHeader>
            <div className="inline-flex h-16 w-16 items-center justify-center rounded-2xl bg-warning/10 mb-4 mx-auto">
              <Wrench className="h-8 w-8 text-warning" />
            </div>
            <CardTitle className="text-4xl font-display">Maintenance</CardTitle>
            <CardDescription className="text-base">
              BadWars is being updated. The loader status service will return as soon as checks finish.
            </CardDescription>
          </CardHeader>
        </Card>
      </div>
    </main>
  );
}
