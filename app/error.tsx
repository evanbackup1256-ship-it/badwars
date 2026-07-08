"use client";

import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertCircle } from "lucide-react";

export default function ErrorPage({ reset }: { reset: () => void }) {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <div className="max-w-xl w-full">
        <Card className="text-center">
          <CardHeader>
            <div className="inline-flex h-16 w-16 items-center justify-center rounded-2xl bg-destructive/10 mb-4 mx-auto">
              <AlertCircle className="h-8 w-8 text-destructive" />
            </div>
            <CardTitle className="text-4xl font-display">Something slipped.</CardTitle>
            <CardDescription className="text-base">
              The console hit an unexpected error. Retry the view or return to the homepage.
            </CardDescription>
            <Button className="mt-6" onClick={reset}>
              Retry
            </Button>
          </CardHeader>
        </Card>
      </div>
    </main>
  );
}
