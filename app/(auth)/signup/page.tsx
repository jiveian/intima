"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { AuthLayout } from "@/components/layouts/auth-layout";
import { Check } from "lucide-react";

function RoleOption({
  active,
  title,
  description,
  onSelect,
}: {
  active: boolean;
  title: string;
  description: string;
  onSelect: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onSelect}
      aria-pressed={active}
      className={`w-full rounded-xl border px-4 py-3 text-left transition-colors ${
        active
          ? "border-terracotta bg-terracotta/5 ring-1 ring-terracotta"
          : "border-border bg-background hover:border-terracotta/40"
      }`}
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-sm font-medium text-navy">{title}</p>
          <p className="mt-0.5 text-xs text-navy/60">{description}</p>
        </div>
        <div
          className={`mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full border ${
            active
              ? "border-terracotta bg-terracotta"
              : "border-border bg-background"
          }`}
        >
          {active && <Check className="h-3 w-3 text-background" strokeWidth={3} />}
        </div>
      </div>
    </button>
  );
}

export default function SignupPage() {
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState<"tracker" | "supporter">("tracker");
  const [displayName, setDisplayName] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [awaitingConfirmation, setAwaitingConfirmation] = useState(false);

  const handleSignup = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const supabase = createClient();
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          role,
          display_name: displayName || null,
        },
      },
    });

    if (error) {
      setError(error.message);
      setLoading(false);
      return;
    }

    // If confirmations are disabled (local dev), signUp() returns an
    // active session immediately — go straight in. If confirmations are
    // required (production, Phase 11), no session comes back yet — show
    // the "check your email" state instead. Checking the actual response
    // means this page doesn't need to change when that config flips.
    if (data.session) {
      router.push("/home");
      router.refresh();
    } else {
      setAwaitingConfirmation(true);
    }

    setLoading(false);
  };

  if (awaitingConfirmation) {
    return (
      <AuthLayout
        title="Almost there."
        subtitle="Confirm your email to finish setting up your account."
      >
        <h1 className="font-display text-2xl text-navy">Check your email</h1>
        <p className="mt-2 text-sm text-navy/60">
          We sent a confirmation link to{" "}
          <span className="font-medium text-navy">{email}</span>.
        </p>
        <Button
          onClick={() => router.push("/login")}
          className="mt-8 w-full"
        >
          Go to sign in
        </Button>
      </AuthLayout>
    );
  }

  return (
    <AuthLayout
      title="Two people. One cycle."
      subtitle="Private predictions, shared clarity — built for couples who track together."
    >
      <p className="mb-1 text-xs font-medium uppercase tracking-wide text-terracotta">
        INTIMA
      </p>
      <h1 className="font-display text-2xl text-navy">Create your account</h1>

      <form onSubmit={handleSignup} className="mt-8 space-y-4">
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
            minLength={6}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="At least 6 characters"
          />
        </div>

        <div className="space-y-1.5">
          <label className="text-sm font-medium text-navy">
            Who&apos;s joining?
          </label>
          <div className="space-y-2">
            <RoleOption
              active={role === "tracker"}
              onSelect={() => setRole("tracker")}
              title="I track my cycle"
              description="Log cycle data and view your own predictions"
            />
            <RoleOption
              active={role === "supporter"}
              onSelect={() => setRole("supporter")}
              title="I'm supporting my partner"
              description="View shared predictions, read-only"
            />
          </div>
        </div>

        <div className="space-y-1.5">
          <label htmlFor="displayName" className="text-sm font-medium text-navy">
            Display name{" "}
            <span className="font-normal text-navy/50">(optional)</span>
          </label>
          <Input
            id="displayName"
            type="text"
            value={displayName}
            onChange={(e) => setDisplayName(e.target.value)}
            placeholder="How your partner will see you"
          />
        </div>

        {error && (
          <div className="rounded-lg border border-risk/30 bg-risk/10 p-3 text-sm text-risk">
            {error}
          </div>
        )}

        <Button type="submit" disabled={loading} className="w-full">
          {loading ? "Creating account…" : "Create account"}
        </Button>
      </form>

      <p className="mt-6 text-center text-sm text-navy/60">
        Already have an account?{" "}
        <a href="/login" className="font-medium text-terracotta hover:underline">
          Sign in
        </a>
      </p>
    </AuthLayout>
  );
}