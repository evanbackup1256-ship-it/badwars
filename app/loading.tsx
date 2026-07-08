"use client";

import { motion } from "framer-motion";

export default function Loading() {
  return (
    <main className="site-wrap grid min-h-screen place-items-center">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="w-full max-w-xl rounded-lg border border-primary/30 bg-card p-6"
      >
        <div className="space-y-4">
          <motion.div
            animate={{ opacity: [0.3, 1, 0.3] }}
            transition={{ duration: 1.5, repeat: Infinity }}
            className="h-3 w-24 rounded bg-primary/40"
          />
          <motion.div
            animate={{ opacity: [0.3, 1, 0.3] }}
            transition={{ duration: 1.5, repeat: Infinity, delay: 0.2 }}
            className="h-10 rounded bg-muted"
          />
          <motion.div
            animate={{ opacity: [0.3, 1, 0.3] }}
            transition={{ duration: 1.5, repeat: Infinity, delay: 0.4 }}
            className="h-20 rounded bg-muted"
          />
        </div>
      </motion.div>
    </main>
  );
}
