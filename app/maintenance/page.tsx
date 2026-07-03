import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function MaintenancePage() {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <Card className="max-w-xl text-center">
        <CardHeader>
          <CardTitle className="text-5xl">Maintenance</CardTitle>
          <CardDescription>BadWars is being updated. The loader status service will return as soon as checks finish.</CardDescription>
        </CardHeader>
      </Card>
    </main>
  );
}
