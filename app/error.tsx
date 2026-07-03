"use client";

import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function ErrorPage({ reset }: { reset: () => void }) {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <Card className="max-w-xl text-center">
        <CardHeader>
          <CardTitle className="text-5xl">Something slipped.</CardTitle>
          <CardDescription>The console hit an unexpected error. Retry the view or return to the homepage.</CardDescription>
          <Button className="mt-4" onClick={reset}>Retry</Button>
        </CardHeader>
      </Card>
    </main>
  );
}
