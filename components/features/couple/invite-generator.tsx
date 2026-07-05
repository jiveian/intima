"use client";

import { useState } from "react";
import { generateInviteCode } from "@/app/actions/couples";
import { Button } from "@/components/ui/button";

export function InviteGenerator() {
  const [code, setCode] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleGenerate = async () => {
    setLoading(true);
    setError(null);

    const result = await generateInviteCode();

    if (result.error) {
      setError(result.error);
      setLoading(false);
      return;
    }

    setCode(result.data!.code);
    setLoading(false);
  };

  return (
    <div className="rounded-xl border border-border bg-white p-6">
      <h2 className="font-display text-lg text-navy">Invite your partner</h2>
      <p className="mt-1 text-sm text-navy/60">
        Generate a code and share it with your partner so they can link
        their account to yours.
      </p>

      {code ? (
        <div className="mt-4">
          <p className="text-xs text-navy/50">Your code — expires in 24 hours</p>
          <p className="mt-1 font-display text-3xl tracking-widest text-terracotta">
            {code}
          </p>
          <Button onClick={handleGenerate} variant="outline" className="mt-4">
            Generate a new code
          </Button>
        </div>
      ) : (
        <Button onClick={handleGenerate} disabled={loading} className="mt-4">
          {loading ? "Generating…" : "Generate invite code"}
        </Button>
      )}

      {error && (
        <div className="mt-4 rounded-lg border border-risk/30 bg-risk/10 p-3 text-sm text-risk">
          {error}
        </div>
      )}
    </div>
  );
}