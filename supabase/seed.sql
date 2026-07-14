-- Demo seed data for the SwiftPay gateway console.
-- Safe to re-run: every insert is idempotent.

-- ── Demo staff accounts (mirrors the former client-side AUTH_USERS mock) ──
do $$
declare
  v_user_id uuid;
begin
  if not exists (select 1 from auth.users where email = 'ananya@swiftpay.co.za') then
    v_user_id := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
      'ananya@swiftpay.co.za', extensions.crypt('Demo2026!', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}',
      '{"name":"Ananya Mukherjee","role":"Super Admin"}', now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), v_user_id, v_user_id::text,
      jsonb_build_object('sub', v_user_id::text, 'email', 'ananya@swiftpay.co.za'), 'email', now(), now(), now());
  end if;

  if not exists (select 1 from auth.users where email = 'sipho@swiftpay.co.za') then
    v_user_id := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
      'sipho@swiftpay.co.za', extensions.crypt('Admin123!', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}',
      '{"name":"Sipho Dlamini","role":"Payments Ops"}', now(), now(), '', '', '', ''
    );
    insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (gen_random_uuid(), v_user_id, v_user_id::text,
      jsonb_build_object('sub', v_user_id::text, 'email', 'sipho@swiftpay.co.za'), 'email', now(), now(), now());
  end if;
end $$;

-- ── Historical transactions ──
insert into public.transactions (ref, type, method, bank, customer_name, amount_cents, risk_score, status, channel, merchant_id, created_at) values
  ('SPY-CP-0314',  'CP',   'Contactless NFC', 'FNB',            'Walk-in',          32000,  4, 'success', 'cp',   'MRC-00142', '2026-05-05 09:41:00+02'),
  ('SPY-CNP-0042', 'CNP',  'Visa 3DS2',        'Absa',           'Sipho Dlamini',    184000, 12,'success', 'cnp',  'MRC-00142', '2026-05-05 09:39:00+02'),
  ('SPY-PUSH-0018','Push', 'RTC Payout',       'Standard Bank',  'Zanele Mokoena',   500000, 2, 'success', 'push', 'MRC-00142', '2026-05-05 09:37:00+02'),
  ('SPY-CNP-0041', 'CNP',  'MC 3DS2',          'Nedbank',        'Priya Naidoo',     920000, 18,'success', 'cnp',  'MRC-00142', '2026-05-05 09:35:00+02'),
  ('SPY-PULL-0094','Pull', 'DebiCheck',        'Capitec',        'Thabo Khumalo',    129900, 5, 'success', 'pull', 'MRC-00142', '2026-05-05 09:33:00+02'),
  ('SPY-CP-0313',  'CP',   'Chip & PIN',       'Standard Bank',  'Walk-in',          210000, 6, 'success', 'cp',   'MRC-00142', '2026-05-05 09:31:00+02'),
  ('SPY-CNP-0040', 'CNP',  'Visa Card',        'Absa',           'Johan van Wyk',    435000, 91,'failed',  'cnp',  'MRC-00142', '2026-05-05 09:28:00+02'),
  ('SPY-PUSH-0017','Push', 'RTC Payout',       'FNB',            'Aisha Cassim',     1200000,3, 'success', 'push', 'MRC-00142', '2026-05-05 09:24:00+02'),
  ('SPY-PULL-0093','Pull', 'NAEDO',            'Absa',           'Mohamed Amin',     240000, 8, 'pending', 'pull', 'MRC-00142', '2026-05-05 09:20:00+02'),
  ('SPY-CP-0312',  'CP',   'Mag Stripe',       'Nedbank',        'Walk-in',          45000,  22,'success', 'cp',   'MRC-00142', '2026-05-05 09:18:00+02'),
  -- earlier transactions referenced by the seeded refunds below
  ('SPY-CP-0310',  'CP',   'Chip & PIN',       'Standard Bank',  'Walk-in',          180000, 5, 'success', 'cp',   'MRC-00142', '2026-05-04 16:02:00+02'),
  ('SPY-CNP-0038', 'CNP',  'Visa 3DS2',        'Absa',           'Neo Radebe',       120000, 9, 'success', 'cnp',  'MRC-00142', '2026-05-04 12:47:00+02'),
  ('SPY-PULL-0091','Pull', 'DebiCheck',        'FNB',            'Karabo Sithole',   350000, 6, 'success', 'pull', 'MRC-00142', '2026-05-03 08:15:00+02'),
  ('SPY-CNP-0031', 'CNP',  'Mastercard 3DS2',  'Nedbank',        'Lerato Mahlangu',  232000, 11,'success', 'cnp',  'MRC-00142', '2026-05-02 14:30:00+02')
on conflict (ref) do nothing;

-- ── Historical refunds (TrasFund) ──
insert into public.refunds (ref, transaction_ref, type, amount_cents, reason, status, created_at) values
  ('TF-20260505-0005', 'SPY-CNP-0042', 'Partial', 92000,  'customer_request',       'success',      '2026-05-05 09:41:00+02'),
  ('TF-20260505-0004', 'SPY-CP-0310',  'Full',    180000, 'fraudulent',             'success',      '2026-05-05 09:28:00+02'),
  ('TF-20260505-0003', 'SPY-CNP-0038', 'Partial', 40000,  'duplicate_charge',       'processing',   '2026-05-05 09:15:00+02'),
  ('TF-20260505-0002', 'SPY-PULL-0091','Full',    350000, 'product_not_received',   'pending_4eyes','2026-05-05 08:50:00+02'),
  ('TF-20260505-0001', 'SPY-CNP-0031', 'Full',    232000, 'customer_request',       'success',      '2026-05-05 08:22:00+02')
on conflict (ref) do nothing;
