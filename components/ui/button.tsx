import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-lg text-sm font-bold transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 motion-safe:hover:-translate-y-0.5 active:scale-95",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground shadow-glow hover:bg-primary/90 hover:shadow-lg hover:shadow-primary/50",
        secondary: "bg-secondary text-secondary-foreground hover:bg-secondary/90",
        outline: "border-2 border-border bg-background/40 hover:bg-accent/20 hover:text-accent-foreground hover:border-accent/50 backdrop-blur-sm",
        ghost: "hover:bg-accent/30 hover:text-accent-foreground",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90 shadow-lg shadow-destructive/30",
        glow: "bg-primary/10 text-primary border border-primary/30 hover:bg-primary/20 hover:border-primary shadow-lg shadow-primary/20 backdrop-blur-md",
        success: "bg-green-500/10 text-green-400 border border-green-500/30 hover:bg-green-500/20 hover:shadow-lg hover:shadow-green-500/20"
      },
      size: {
        sm: "h-9 px-3",
        default: "h-11 px-4",
        lg: "h-12 px-6 text-base",
        icon: "h-10 w-10"
      }
    },
    defaultVariants: {
      variant: "default",
      size: "default"
    }
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return <Comp className={cn(buttonVariants({ variant, size, className }))} ref={ref} {...props} />;
  }
);
Button.displayName = "Button";

export { buttonVariants };
