import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function NotFound() {
  return (
    <main className="grid min-h-screen place-items-center p-6">
      <Card className="max-w-xl text-center">
        <CardHeader>
          <CardTitle className="text-5xl">404</CardTitle>
          <CardDescription>This page route is not in the BadWars console yet.</CardDescription>
          <Button asChild className="mt-4"><Link href="/">Return home</Link></Button>
        </CardHeader>
      </Card>
    </main>
  );
}
