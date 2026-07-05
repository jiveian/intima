-- ---------------------------------------------------------------------------
-- Migration: create_cycle_predictions_table
--
-- Recompute-on-write, not a DB trigger, not lazy-on-read — decided
-- earlier. Every addCycleLog/deleteCycleLog Server Action recomputes and
-- upserts this row in the same request. See ADR (Phase 12) for the full
-- reasoning: correctness > premature caching-performance concerns, and
-- keeping the algorithm in one place (TypeScript) rather than
-- duplicating it in PL/pgSQL.
-- ---------------------------------------------------------------------------

CREATE TABLE public.cycle_predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- One current prediction per tracker — this is a cache, not a history
  -- table. UNIQUE enables upsert via ON CONFLICT (profile_id).
  profile_id UUID UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

  fertile_window_start DATE,
  fertile_window_end DATE,
  next_period_date DATE,

  -- Deliberately NOT storing a separate confidence_label ('green'/
  -- 'orange'/'red') alongside the score. The label is a pure function of
  -- the score — storing both risks them drifting out of sync if one is
  -- ever updated without the other. Derive the label from the score at
  -- render time, in the same algorithm module that computes the score.
  confidence_score INTEGER CHECK (confidence_score BETWEEN 0 AND 100),

  cycle_count INTEGER NOT NULL DEFAULT 0,

  -- Audit trail: which specific cycle_log rows fed into this computation.
  -- Answers "what did we predict, and based on what data" later, which
  -- matters for a health-adjacent app more than typical caching does.
  source_log_ids UUID[] NOT NULL DEFAULT '{}',

  computed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.cycle_predictions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owner can view their own prediction"
  ON public.cycle_predictions
  FOR SELECT
  USING (profile_id = auth.uid());

CREATE POLICY "Linked partner can view prediction"
  ON public.cycle_predictions
  FOR SELECT
  USING (profile_id = public.linked_partner_id(auth.uid()));

-- Written by the same Server Action (running as the authenticated user,
-- not service-role) that inserts/deletes a cycle_log — so this just needs
-- normal owner-write access, unlike couples' cross-user insert case.
CREATE POLICY "Owner can upsert their own prediction"
  ON public.cycle_predictions
  FOR INSERT
  WITH CHECK (profile_id = auth.uid());

CREATE POLICY "Owner can update their own prediction"
  ON public.cycle_predictions
  FOR UPDATE
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

-- No DELETE policy: a prediction row gets updated back toward "no data
-- yet" (nulled fields, cycle_count 0) rather than deleted, when someone
-- removes enough cycle_logs to drop below the minimum-cycles threshold.
-- Deliberately not building row deletion until there's an actual case
-- that needs it.