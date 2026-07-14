import { createClient } from 'jsr:@supabase/supabase-js@2';

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const TYPE_MAP: Record<string, string> = { CNP: 'CNP', CP: 'CP', PayShap: 'Push', 'WA Pay': 'Push' };
const METHOD_MAP: Record<string, string> = {
  CNP: 'Visa 3DS2',
  CP: 'Chip & PIN',
  PayShap: 'PayShap',
  'WA Pay': 'WhatsApp Pay',
};

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'Invalid JSON body' }, 400);
  }

  const { card, amount, merchant, channel } = body ?? {};
  const cardDigits = String(card ?? '').replace(/\s/g, '');
  if (cardDigits.length < 8 || !/^\d+$/.test(cardDigits)) {
    return json({ error: 'Invalid card number' }, 400);
  }
  const amt = Number(amount);
  if (!Number.isFinite(amt) || amt <= 0) {
    return json({ error: 'Invalid amount' }, 400);
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  const userClient = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: 'Not authenticated' }, 401);

  const type = TYPE_MAP[channel] ?? 'CNP';
  const method = METHOD_MAP[channel] ?? channel ?? 'Card';

  // Simplified risk model: baseline jitter + a premium for high-value payments.
  const risk = Math.min(97, Math.max(1, Math.round(8 + Math.random() * 25 + (amt > 10000 ? 15 : 0))));
  const status = risk > 85 ? 'declined' : 'approved';
  const ref = `SPY-${String(channel ?? 'CNP').replace(/\s/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data, error } = await admin
    .from('transactions')
    .insert({
      ref,
      type,
      method,
      bank: 'FNB',
      customer_name: 'Test Customer',
      amount_cents: Math.round(amt * 100),
      risk_score: risk,
      status,
      channel: String(channel ?? '').toLowerCase(),
      merchant_id: merchant || 'MRC-00142',
      created_by: user.id,
    })
    .select()
    .single();

  if (error) return json({ error: error.message }, 500);

  return json({
    ref: data.ref,
    status: data.status,
    risk: data.risk_score,
    amount: amt,
    authCode: String(Math.floor(100000 + Math.random() * 900000)),
    approved: status === 'approved',
  });
});
