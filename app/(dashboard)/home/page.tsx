import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { SignOutButton } from "@/components/features/auth/sign-out-button";

export default async function HomePage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: profile, error } = await supabase
    .from("profiles")
    .select("role, display_name, email")
    .eq("id", user.id)
    .single();

  if (error || !profile) {
    return (
      <div className="p-8 text-risk">
        Failed to load profile: {error?.message ?? "not found"}
      </div>
    );
  }

  return (
    <div className="p-8">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium uppercase tracking-wide text-terracotta">
            INTIMA
          </p>
          <h1 className="font-display text-2xl text-navy">
            Welcome{profile.display_name ? `, ${profile.display_name}` : ""}
          </h1>
          <p className="mt-1 text-sm text-navy/60">
            Signed in as {profile.email} — role: {profile.role}
          </p>
        </div>
        <SignOutButton />
      </div>

      <p className="mt-8 text-sm text-navy/50">
        This confirms the auth loop end-to-end: session → profile row →
        role read correctly. Real dashboard content (calendar, insights,
        couple linking) comes in later phases.
      </p>
    </div>
  );
}