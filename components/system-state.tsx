import Link from "next/link";
import type { LucideIcon } from "lucide-react";
import { Button } from "@/components/ui/button";

export function SystemState({ code, title, description, icon: Icon, action, onAction }: { code: string; title: string; description: string; icon: LucideIcon; action?: string; onAction?: () => void }) {
  return <main className="system-state">
    <section className="system-state-panel" aria-labelledby="state-title">
      <div className="system-state-icon"><Icon /></div>
      <div className="section-kicker">SYSTEM / {code}</div>
      <h1 id="state-title">{title}</h1>
      <p>{description}</p>
      {onAction ? <Button onClick={onAction}>{action || "Retry"}</Button> : <Button asChild><Link href="/">Return home</Link></Button>}
    </section>
  </main>;
}
