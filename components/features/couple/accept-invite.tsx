"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { acceptInvite } from "@/app/actions/couples";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export function AcceptInvite() {
  const router = useRouter();
  const [code, setCode] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const result = await acceptInvite(code);

    if (result.error) {
      setError(result.error);
      setLoading(false);
      return;
    }

    router.refresh();
  };

  return (
    <div className="rounded-xl border border-border bg-white p-6">
      <h2 className="font-display text-lg text-navy">Link with your partner</h2>
      <p className="mt-1 text-sm text-navy/60">
        Enter the code your partner shared with you.
      </p>

      <form onSubmit={handleSubmit} className="mt-4 flex gap-2">
        <Input
          value={code}
          onChange={(e) => setCode(e.target.value)}
          placeholder="8-character code"
          maxLength={8}
          required
          className="uppercase tracking-widest"
        />
        <Button type="submit" disabled={loading}>
          {loading ? "Linking…" : "Link"}
        </Button>
      </form>

      {error && (
        <div className="mt-4 rounded-lg border border-risk/30 bg-risk/10 p-3 text-sm text-risk">
          {error}
        </div>
      )}
    </div>
  );
}