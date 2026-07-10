export default function Loading() {
  return <main className="system-state" aria-label="Loading BadWars console">
    <div className="system-state-panel">
      <div className="section-kicker">SYSTEM / SYNCING</div>
      <div className="mt-6 h-2 w-28 shimmer bg-primary/30" />
      <div className="mt-5 h-10 w-4/5 shimmer bg-muted" />
      <div className="mt-4 h-20 w-full shimmer bg-muted" />
    </div>
  </main>;
}
