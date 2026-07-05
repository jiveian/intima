-- ---------------------------------------------------------------------------
-- Migration: create_cycle_logs_table
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Reusable helper: "who is this user's active linked partner, if any?"
--
-- Every couple-scoped table (cycle_logs, intimacy_logs, and profiles'
-- partner-view policy below) needs this exact lookup. Defined once here
-- instead of repeating the same subquery in every future migration.
--
-- SECURITY DEFINER + STABLE: runs once per statement (not per row), and
-- executes with the function owner's privileges so it isn't re-evaluating
-- RLS on `couples` recursively for every row it's used against.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.linked_partner_id(uid UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE WHEN partner_1_id = uid THEN partner_2_id ELSE partner_1_id END
  FROM public.couples
  WHERE status = 'active' AND (partner_1_id = uid OR partner_2_id = uid)
  LIMIT 1;
$$;

-- ---------------------------------------------------------------------------
-- Closes the note left in the profiles migration: now that `couples`
-- exists, a supporter can view their linked tracker's profile (and vice
-- versa) — needed for showing "tracking for [display_name]" in the UI.
-- ---------------------------------------------------------------------------
CREATE POLICY "Partners can view each other's profile"
  ON public.profiles
  FOR SELECT
  USING (id = public.linked_partner_id(auth.uid()));

-- ---------------------------------------------------------------------------
-- cycle_logs
--
-- Individual by nature (describes one body) — owner writes, linked
-- partner reads. Asymmetric on purpose, unlike intimacy_logs (next
-- migration), which is couple-shared.
-- ---------------------------------------------------------------------------
CREATE TABLE public.cycle_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

  start_date DATE NOT NULL,
  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Prevents accidentally logging the same period twice on the same date.
  UNIQUE (profile_id, start_date)
);

ALTER TABLE public.cycle_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owner can view their own cycle logs"
  ON public.cycle_logs
  FOR SELECT
  USING (profile_id = auth.uid());

CREATE POLICY "Linked partner can view cycle logs"
  ON public.cycle_logs
  FOR SELECT
  USING (profile_id = public.linked_partner_id(auth.uid()));

CREATE POLICY "Owner can insert their own cycle logs"
  ON public.cycle_logs
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Owner can delete their own cycle logs"
  ON public.cycle_logs
  FOR DELETE
  USING (profile_id = auth.uid());

-- No UPDATE policy: matches the old app's feature set (add/delete only,
-- no editing a logged date after the fact). Easy to add later if needed —
-- deliberately not building it before there's a real use case for it.