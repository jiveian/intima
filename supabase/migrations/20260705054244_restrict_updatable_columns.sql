-- ---------------------------------------------------------------------------
-- Migration: restrict_updatable_columns
--
-- RLS controls WHICH ROWS a policy allows — it does not restrict which
-- COLUMNS within an allowed row can be changed. The UPDATE policies
-- written in earlier migrations were row-correct but column-open: a user
-- could update their own profiles/couples row, which technically includes
-- every column on it, not just the one we intended (display_name,
-- status). This migration closes that gap with column-level GRANTs,
-- which Postgres enforces independently of, and in addition to, RLS.
-- ---------------------------------------------------------------------------

-- profiles: a user may update their display name, never their own role.
REVOKE UPDATE ON public.profiles FROM authenticated;
GRANT UPDATE (display_name, updated_at) ON public.profiles TO authenticated;

-- couples: a partner may only flip status (to unlink) — never reassign
-- who the partners are, or reactivate a couple by rewriting status
-- directly back to 'active' outside the proper invite/accept flow.
REVOKE UPDATE ON public.couples FROM authenticated;
GRANT UPDATE (status, updated_at) ON public.couples TO authenticated;