-- ---------------------------------------------------------------------------
-- Migration: fix_expire_invitations_trigger_security
--
-- expire_old_invitations() was defined without SECURITY DEFINER, so it
-- defaulted to SECURITY INVOKER — running with the calling user's
-- privileges. Its internal UPDATE needs a privilege we deliberately never
-- granted to authenticated (allowing users to directly UPDATE invitation
-- status would let someone forge their own code as 'accepted'). This
-- matches the same pattern already used correctly for handle_new_user()
-- and the linked_partner_id()/my_couple_id() helpers — just missed here.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.expire_old_invitations()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.invitations
  SET status = 'expired', updated_at = now()
  WHERE inviter_id = NEW.inviter_id AND status = 'pending';
  RETURN NEW;
END;
$$;