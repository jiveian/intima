/**
 * Fails fast, at startup, if a required env var is missing — instead of
 * failing later with a cryptic Supabase error deep in a Server Action.
 *
 * Import this once from a root-level file (e.g. instrumentation.ts or the
 * first Server Component that runs) so it's checked before anything else.
 */
const requiredServerVars = [
  "NEXT_PUBLIC_SUPABASE_URL",
  "NEXT_PUBLIC_SUPABASE_ANON_KEY",
  "SUPABASE_SERVICE_ROLE_KEY",
] as const;

export function assertEnv() {
  const missing = requiredServerVars.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    throw new Error(
      `Missing required environment variable(s): ${missing.join(", ")}\n` +
        `Check .env.local against .env.example.`
    );
  }
}