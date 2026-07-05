import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/types/database.types";

/**
 * Service-role client — bypasses RLS entirely.
 *
 * Use ONLY for operations that legitimately need to act across users:
 *   - forming a couples row (no client INSERT policy exists, by design —
 *     see the 5.2 migration note on why)
 *   - writing cycle_predictions (no client INSERT/UPDATE policy — see the
 *     5.6 hardening decision)
 *
 * NEVER import this into a Client Component. NEVER send this key to the
 * browser. Server Actions and Route Handlers only.
 */
export function createAdminClient() {
  return createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}