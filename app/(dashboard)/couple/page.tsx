import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { InviteGenerator } from "@/components/features/couple/invite-generator";
import { AcceptInvite } from "@/components/features/couple/accept-invite";
import { UnlinkButton } from "@/components/features/couple/unlink-button";

export default async function CouplePage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();

  const { data: couple } = await supabase
    .from("couples")
    .select("id, partner_1_id, partner_2_id")
    .eq("status", "active")
    .or(`partner_1_id.eq.${user.id},partner_2_id.eq.${user.id}`)
    .maybeSingle();

  return (
    <div className="p-8">
      <p className="text-xs font-medium uppercase tracking-wide text-terracotta">
        INTIMA
      </p>
      <h1 className="font-display text-2xl text-navy">Couple</h1>

      <div className="mt-6 max-w-md">
        {couple ? (
          <div className="rounded-xl border border-border bg-white p-6">
            <p className="text-sm text-navy/60">You&apos;re linked with your partner.</p>
            <div className="mt-4">
              <UnlinkButton coupleId={couple.id} />
            </div>
          </div>
        ) : profile?.role === "tracker" ? (
          <InviteGenerator />
        ) : (
          <AcceptInvite />
        )}
      </div>
    </div>
  );
}