-- ---------------------------------------------------------------------------
-- Migration: create_invitations_and_couples_tables
--
-- Two separate tables, deliberately:
--   invitations — transient (code, expiry, status changes)
--   couples     — stable, permanent link, once formed
--
-- Direction: tracker generates a code, supporter enters it to link.
-- Enforced as an application-layer + DB-check-constraint rule (see
-- invitations INSERT policy below), not a hardcoded schema assumption —
-- easy to loosen later without a migration.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Invite code generator
--
-- Excludes visually ambiguous characters (0/O, 1/I) since these codes are
-- meant to be read aloud or typed by hand between two people.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT
LANGUAGE sql
AS $$
  SELECT string_agg(
    substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', ceil(random() * 33)::int, 1),
    ''
  )
  FROM generate_series(1, 8);
$$;

CREATE TABLE public.invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

  code TEXT UNIQUE NOT NULL DEFAULT public.generate_invite_code(),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '24 hours'),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Only one active (pending) code per inviter at a time — generating a new
-- one automatically expires whatever was pending before it.
CREATE OR REPLACE FUNCTION public.expire_old_invitations()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.invitations
  SET status = 'expired', updated_at = now()
  WHERE inviter_id = NEW.inviter_id AND status = 'pending';
  RETURN NEW;
END;
$$;

CREATE TRIGGER before_invitation_insert
  BEFORE INSERT ON public.invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.expire_old_invitations();

CREATE TRIGGER set_invitations_updated_at
  BEFORE UPDATE ON public.invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- You can only ever see your own invitations (e.g. to display "your active
-- code" in the UI). Deliberately NOT open to other users — see the note
-- above the migration about why lookup-by-code happens server-side instead.
CREATE POLICY "Inviter can view their own invitations"
  ON public.invitations
  FOR SELECT
  USING (inviter_id = auth.uid());

-- Enforced at the DB layer, not just in application code: only a
-- 'tracker' can create an invitation, and only for themself.
CREATE POLICY "Only trackers can create invitations, for themselves"
  ON public.invitations
  FOR INSERT
  WITH CHECK (
    inviter_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'tracker'
    )
  );

-- ---------------------------------------------------------------------------
-- Couples
-- ---------------------------------------------------------------------------
CREATE TABLE public.couples (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invitation_id UUID UNIQUE NOT NULL REFERENCES public.invitations(id),

  -- No ordering or role meaning attached to either slot — see the role
  -- modeling decision. Just two linked people.
  partner_1_id UUID NOT NULL REFERENCES public.profiles(id),
  partner_2_id UUID NOT NULL REFERENCES public.profiles(id),

  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'unlinked')),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT different_partners CHECK (partner_1_id <> partner_2_id)
);

CREATE TRIGGER set_couples_updated_at
  BEFORE UPDATE ON public.couples
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.couples ENABLE ROW LEVEL SECURITY;

-- Either partner can view the link.
CREATE POLICY "Partners can view their own couple link"
  ON public.couples
  FOR SELECT
  USING (partner_1_id = auth.uid() OR partner_2_id = auth.uid());

-- No INSERT policy here on purpose: forming a couple means validating an
-- invitation code server-side (checking status/expiry, marking it
-- 'accepted') and creating the link atomically — done via the service-role
-- client in a Server Action, which bypasses RLS entirely. There is no
-- "insert your own couple row" operation that makes sense for a regular
-- authenticated client to perform directly.

-- Either partner can unlink.
CREATE POLICY "Partners can update (unlink) their own couple link"
  ON public.couples
  FOR UPDATE
  USING (partner_1_id = auth.uid() OR partner_2_id = auth.uid())
  WITH CHECK (partner_1_id = auth.uid() OR partner_2_id = auth.uid());