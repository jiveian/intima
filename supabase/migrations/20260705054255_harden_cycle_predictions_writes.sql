-- ---------------------------------------------------------------------------
-- Migration: harden_cycle_predictions_writes
--
-- Decision from the 5.6 RLS review: cycle_predictions is a computed
-- result, not user-entered data. A client with normal authenticated
-- access could otherwise write a fabricated prediction directly,
-- bypassing the actual algorithm entirely — and since a supporter
-- partner trusts this data at face value, that's a meaningful gap
-- specific to what this app is for, not a generic hardening exercise.
--
-- Removing these policies means: no role except service_role can write
-- to this table at all (service_role bypasses RLS unconditionally, so it
-- needs no policy of its own). The prediction-recompute step in the
-- cycle_logs Server Action must use the service-role admin client
-- (lib/supabase/admin.ts) specifically for this one write — the same
-- admin client the couples accept-invite flow already needs. One file,
-- two call sites.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Owner can upsert their own prediction" ON public.cycle_predictions;
DROP POLICY IF EXISTS "Owner can update their own prediction" ON public.cycle_predictions;

-- SELECT policies (owner + linked partner) are unaffected and remain —
-- reading your own prediction is fine for a normal authenticated client.