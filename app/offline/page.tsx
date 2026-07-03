import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function OfflinePage() {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <Card className="max-w-xl text-center">
        <CardHeader>
          <CardTitle className="text-5xl">Offline</CardTitle>
          <CardDescription>The dashboard cannot reach live services right now. Cached loader links may still be available.</CardDescription>
        </CardHeader>
      </Card>
    </main>
  );
}
