import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { WifiOff } from "lucide-react";

export default function OfflinePage() {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <div className="max-w-xl w-full">
        <Card className="text-center">
          <CardHeader>
            <div className="inline-flex h-16 w-16 items-center justify-center rounded-2xl bg-muted mb-4 mx-auto">
              <WifiOff className="h-8 w-8 text-muted-foreground" />
            </div>
            <CardTitle className="text-4xl font-display">Offline</CardTitle>
            <CardDescription className="text-base">
              The dashboard cannot reach live services right now. Cached loader links may still be available.
            </CardDescription>
          </CardHeader>
        </Card>
      </div>
    </main>
  );
}
