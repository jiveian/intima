"use server";

import { createClient } from "@/lib/supabase/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { revalidatePath } from "next/cache";

// ---------------------------------------------------------------------------
// generateInviteCode — runs as the normal authenticated user. The
// tracker-only, self-only restriction is enforced by the INSERT policy
// written in migration 5.2 (WITH CHECK ... role = 'tracker'), not
// re-checked here — RLS is the actual enforcement, this is just the call.
// ---------------------------------------------------------------------------
export async function generateInviteCode() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { error: "Not signed in." };

  const { data, error } = await supabase
    .from("invitations")
    .insert({ inviter_id: user.id })
    .select("code, expires_at")
    .single();

  if (error) {
    // The RLS policy is what actually blocks a supporter from calling
    // this — if it fires, surface something a non-technical user can
    // read rather than the raw Postgres error.
    if (error.message.includes("row-level security")) {
      return { error: "Only the person tracking their cycle can invite a partner." };
    }
    return { error: error.message };
  }

  revalidatePath("/couple");
  return { data };
}

// ---------------------------------------------------------------------------
// acceptInvite — this is the one place the admin client is actually
// required. Looking up an invitation by code, forming the couples row,
// and marking the invitation accepted all need to act on data the
// current user doesn't own — none of that has a client-facing policy,
// by design (see migrations 5.2 and the note above create_couples).
// ---------------------------------------------------------------------------
export async function acceptInvite(code: string) {
  const supabase = await createClient();
  const admin = createAdminClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return { error: "Not signed in." };

  // Confirm the accepting user is actually a supporter, mirroring the
  // tracker-only check on the generate side. Checked here explicitly
  // since this whole function runs on the admin client, which has no
  // RLS to fall back on for enforcement.
  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();

  if (profile?.role !== "supporter") {
    return { error: "Only a supporting partner can accept an invite code." };
  }

  const normalizedCode = code.trim().toUpperCase();

  const { data: invitation, error: lookupError } = await admin
    .from("invitations")
    .select("id, inviter_id, status, expires_at")
    .eq("code", normalizedCode)
    .single();

  if (lookupError || !invitation) {
    console.error("Invitation lookup failed:", lookupError);
    return { error: "That code doesn't match an active invite." };
  }

  if (invitation.inviter_id === user.id) {
    return { error: "You can't accept your own invite code." };
  }

  if (invitation.status !== "pending") {
    return { error: "That code has already been used." };
  }

  if (new Date(invitation.expires_at) < new Date()) {
    return { error: "That code has expired. Ask your partner for a new one." };
  }

  // Guard against double-linking — someone already in an active couple
  // shouldn't silently form a second one.
  const { data: existingLink } = await admin
    .from("couples")
    .select("id")
    .eq("status", "active")
    .or(`partner_1_id.eq.${user.id},partner_2_id.eq.${user.id}`)
    .maybeSingle();

  if (existingLink) {
    return { error: "You're already linked with a partner." };
  }

  const { error: coupleError } = await admin.from("couples").insert({
    invitation_id: invitation.id,
    partner_1_id: invitation.inviter_id,
    partner_2_id: user.id,
  });

  if (coupleError) {
    return { error: coupleError.message };
  }

  const { error: updateError } = await admin
    .from("invitations")
    .update({ status: "accepted" })
    .eq("id", invitation.id);

  if (updateError) {
    // The link itself succeeded — this is a non-fatal bookkeeping miss,
    // not something to block the user on. Worth surfacing to logs, not
    // to the person who just successfully linked.
    console.error("Couple linked, but failed to mark invitation accepted:", updateError.message);
  }

  revalidatePath("/couple");
  return { success: true };
}

// ---------------------------------------------------------------------------
// unlinkCouple — deliberately the NORMAL client, not admin. The Phase 5.6
// grant already permits updating `status` on a couple you're part of;
// reaching for admin here would be using more privilege than the
// operation actually needs.
// ---------------------------------------------------------------------------
export async function unlinkCouple(coupleId: string) {
  const supabase = await createClient();

  const { error } = await supabase
    .from("couples")
    .update({ status: "unlinked" })
    .eq("id", coupleId);

  if (error) return { error: error.message };

  revalidatePath("/couple");
  return { success: true };
}