import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const badgeVariants = cva("inline-flex items-center gap-2 rounded-full px-3 py-1 text-xs font-black uppercase tracking-normal", {
  variants: {
    variant: {
      default: "bg-primary/15 text-primary ring-1 ring-primary/25",
      secondary: "bg-secondary/15 text-secondary ring-1 ring-secondary/25",
      success: "bg-emerald-500/15 text-emerald-300 ring-1 ring-emerald-400/25",
      warning: "bg-amber-500/15 text-amber-300 ring-1 ring-amber-400/25",
      error: "bg-rose-500/15 text-rose-300 ring-1 ring-rose-400/25",
      muted: "bg-muted text-muted-foreground"
    }
  },
  defaultVariants: { variant: "default" }
});

export function Badge({ className, variant, ...props }: React.HTMLAttributes<HTMLDivElement> & VariantProps<typeof badgeVariants>) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />;
}
