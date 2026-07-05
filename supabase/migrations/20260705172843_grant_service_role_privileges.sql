-- ---------------------------------------------------------------------------
-- Migration: grant_service_role_privileges
--
-- service_role bypasses RLS entirely — but under the stricter
-- auto_expose_new_tables default (same root cause as
-- grant_baseline_table_privileges), it still needs baseline table-level
-- GRANTs, exactly like any other role. We granted those to `authenticated`
-- already; this was the missing counterpart for `service_role`, needed
-- for acceptInvite() and the future cycle_predictions write path to
-- actually work.
--
-- service_role gets full access on every table — that's the entire point
-- of the role; it's never exposed to the browser, only used server-side
-- via the admin client.
-- ---------------------------------------------------------------------------

GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.invitations TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.couples TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cycle_logs TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.intimacy_logs TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cycle_predictions TO service_role;