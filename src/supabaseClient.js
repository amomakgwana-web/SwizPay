import { createClient } from '@supabase/supabase-js';

// Public project URL + publishable (anon) key — safe to expose client-side.
// Access control is enforced by Postgres Row Level Security, not by keeping
// these values secret. See supabase/migrations for the RLS policies.
const SUPABASE_URL = 'https://pbwbriebntqjghfppnxh.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_STgax_KAT2PUrVPtHKu4mg_nNcgTU1i';

export const supabase = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
