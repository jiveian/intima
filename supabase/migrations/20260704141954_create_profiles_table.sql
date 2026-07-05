-- ---------------------------------------------------------------------------
-- Migration: create_profiles_table
--
-- Purpose: Extends auth.users with INTIMA-specific fields. A trigger
-- automatically creates a profile row every time a new user signs up.
--
-- Role model: 'role' describes ONLY what a person does in the app —
-- 'tracker' (logs cycle/intimacy data) or 'supporter' (views shared data,
-- read-only). It carries no assumption about gender or biological sex.
-- This is a deliberate departure from the old male/female-coded model.
-- ---------------------------------------------------------------------------

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,

  role TEXT NOT NULL DEFAULT 'tracker' CHECK (role IN ('tracker', 'supporter')),

  display_name TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- A user can always read their own profile.
CREATE POLICY "Users can view their own profile"
  ON public.profiles
  FOR SELECT
  USING (id = auth.uid());

-- A user can update their own profile (display_name, etc.) — but never
-- their own role. Role changes, if ever needed, go through a separate
-- server-side path, not a direct client update.
CREATE POLICY "Users can update their own profile"
  ON public.profiles
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- NOTE: partner-read-access ("supporter can view tracker's profile") is
-- deferred to the migration that creates `couples`, since it needs that
-- table to exist to express the relationship. Deliberately not guessed
-- at here.

-- ---------------------------------------------------------------------------
-- Auto-create profile on signup
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role, display_name)
  VALUES (
    NEW.id,
    NEW.email,
    -- Defaults to 'tracker' if the signup form didn't send a role for
    -- some reason, rather than failing the whole signup.
    COALESCE((NEW.raw_user_meta_data->>'role')::text, 'tracker'),
    (NEW.raw_user_meta_data->>'display_name')::text
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Keep updated_at current on every row change
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();