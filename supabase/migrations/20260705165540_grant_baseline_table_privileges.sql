-- ---------------------------------------------------------------------------
-- Migration: grant_baseline_table_privileges
--
-- RLS restricts WHICH ROWS an operation can touch. It does not grant the
-- operation itself — Postgres checks table-level GRANTs first. Newer
-- Supabase CLI versions default to NOT auto-exposing new tables to
-- anon/authenticated (see the commented-out auto_expose_new_tables in
-- config.toml). Every table since 5.1 has had correct RLS policies sitting
-- on top of missing baseline grants — this closes that gap precisely,
-- matching exactly what each table's existing policies need. No broader.
--
-- anon gets nothing here, deliberately: every table in this schema
-- requires authentication, there is no public/anonymous read path
-- anywhere in this app.
-- ---------------------------------------------------------------------------

-- profiles: read own+partner; update only what 5.6 already scoped
-- (display_name, updated_at) — re-stated here for completeness, not
-- widened.
GRANT SELECT ON public.profiles TO authenticated;
GRANT UPDATE (display_name, updated_at) ON public.profiles TO authenticated;

-- invitations: inviter can view their own, and create their own.
GRANT SELECT, INSERT ON public.invitations TO authenticated;

-- couples: partners can view; update only status/updated_at (5.6 scope),
-- restated for completeness. No INSERT — that's service-role only.
GRANT SELECT ON public.couples TO authenticated;
GRANT UPDATE (status, updated_at) ON public.couples TO authenticated;

-- cycle_logs: owner+partner read, owner writes/deletes, no update.
GRANT SELECT, INSERT, DELETE ON public.cycle_logs TO authenticated;

-- intimacy_logs: both partners read, either inserts, logger deletes.
GRANT SELECT, INSERT, DELETE ON public.intimacy_logs TO authenticated;

-- cycle_predictions: owner+partner read only. No INSERT/UPDATE for
-- authenticated at all — per the Phase 5.6 hardening decision, only
-- service_role writes this table (which bypasses grants entirely, so it
-- needs no explicit GRANT here).
GRANT SELECT ON public.cycle_predictions TO authenticated;