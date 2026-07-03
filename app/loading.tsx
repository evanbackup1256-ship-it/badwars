import { Card } from "@/components/ui/card";

export default function Loading() {
  return (
    <main className="site-wrap grid min-h-screen place-items-center">
      <Card className="w-full max-w-xl p-6">
        <div className="h-4 w-28 animate-pulse rounded-full bg-muted" />
        <div className="mt-5 h-12 animate-pulse rounded-xl bg-muted" />
        <div className="mt-3 h-24 animate-pulse rounded-xl bg-muted" />
      </Card>
    </main>
  );
}
