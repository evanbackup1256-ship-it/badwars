import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Search } from "lucide-react";

export default function NotFound() {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <div className="max-w-xl w-full">
        <Card className="text-center">
          <CardHeader>
            <div className="inline-flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 mb-4 mx-auto">
              <Search className="h-8 w-8 text-primary" />
            </div>
            <CardTitle className="text-6xl font-display font-black text-primary">404</CardTitle>
            <CardDescription className="text-base">
              This page route is not in the BadWars console yet.
            </CardDescription>
            <Button asChild className="mt-6">
              <Link href="/">Return home</Link>
            </Button>
          </CardHeader>
        </Card>
      </div>
    </main>
  );
}
