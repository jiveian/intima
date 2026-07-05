-- ---------------------------------------------------------------------------
-- Migration: create_intimacy_logs_table
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Reusable helper: "what's this user's active couple, if any?"
-- Same reasoning as linked_partner_id() — this gets used in every policy
-- on this table, so it's defined once rather than repeated.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.my_couple_id(uid UUID)
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.couples
  WHERE status = 'active' AND (partner_1_id = uid OR partner_2_id = uid)
  LIMIT 1;
$$;

-- ---------------------------------------------------------------------------
-- intimacy_logs
--
-- Couple-shared by nature — doesn't belong to one partner more than the
-- other, unlike cycle_logs. Keyed by couple_id, not profile_id.
-- `logged_by` is attribution metadata only, not an access boundary.
-- ---------------------------------------------------------------------------
CREATE TABLE public.intimacy_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  couple_id UUID NOT NULL REFERENCES public.couples(id) ON DELETE CASCADE,
  logged_by UUID NOT NULL REFERENCES public.profiles(id),

  occurred_on DATE NOT NULL,
  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.intimacy_logs ENABLE ROW LEVEL SECURITY;

-- Both partners can read every entry for their couple — no per-partner
-- filtering, since this data is joint by design.
CREATE POLICY "Both partners can view intimacy logs"
  ON public.intimacy_logs
  FOR SELECT
  USING (couple_id = public.my_couple_id(auth.uid()));

-- Either partner can log an entry, for their shared couple.
CREATE POLICY "Either partner can insert intimacy logs"
  ON public.intimacy_logs
  FOR INSERT
  WITH CHECK (
    couple_id = public.my_couple_id(auth.uid())
    AND logged_by = auth.uid()
  );

-- Deliberate judgment call, worth naming: only whoever logged an entry
-- can delete it — not "either partner can delete anything." Prevents one
-- partner silently erasing something the other logged.
CREATE POLICY "Only the logger can delete their own intimacy log"
  ON public.intimacy_logs
  FOR DELETE
  USING (logged_by = auth.uid());