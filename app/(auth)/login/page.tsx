"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AuthLayout } from "@/components/layouts/auth-layout";

export default function LoginPage() {
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    router.push("/home");
    router.refresh();
  };

  return (
    <AuthLayout
      title="Welcome back."
      subtitle="Sign in to see your cycle, your predictions, and each other."
    >
      <p className="mb-1 text-xs font-medium uppercase tracking-wide text-terracotta">
        INTIMA
      </p>
      <h1 className="font-display text-2xl text-navy">Sign in</h1>

      <form onSubmit={handleLogin} className="mt-8 space-y-4">
        <div className="space-y-1.5">
          <label htmlFor="email" className="text-sm font-medium text-navy">
            Email
          </label>
          <Input
            id="email"
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
          />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="password" className="text-sm font-medium text-navy">
            Password
          </label>
          <Input
            id="password"
            type="password"
            required
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Your password"
          />
        </div>

        {error && (
          <div className="rounded-lg border border-risk/30 bg-risk/10 p-3 text-sm text-risk">
            {error}
          </div>
        )}

        <Button type="submit" disabled={loading} className="w-full">
          {loading ? "Signing in…" : "Sign in"}
        </Button>
      </form>

      <p className="mt-6 text-center text-sm text-navy/60">
        Don&apos;t have an account?{" "}
        <a href="/signup" className="font-medium text-terracotta hover:underline">
          Create one
        </a>
      </p>
    </AuthLayout>
  );
}