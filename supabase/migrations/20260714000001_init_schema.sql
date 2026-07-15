-- SwiftPay gateway console — core schema
-- profiles: one row per internal staff member (Super Admin, Payments Ops, ...)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  name text not null,
  role text not null default 'Payments Ops',
  created_at timestamptz not null default now()
);

-- transactions: CP / CNP / Push / Pull payment events
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  ref text unique not null,
  type text not null check (type in ('CP','CNP','Push','Pull')),
  method text,
  bank text,
  customer_name text,
  amount_cents bigint not null check (amount_cents >= 0),
  currency text not null default 'ZAR',
  risk_score int not null default 0 check (risk_score between 0 and 100),
  status text not null default 'pending' check (status in ('pending','success','approved','declined','failed')),
  channel text,
  merchant_id text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create index if not exists transactions_created_at_idx on public.transactions (created_at desc);
create index if not exists transactions_status_idx on public.transactions (status);

-- refunds: TrasFund refund records against a transaction
create table if not exists public.refunds (
  id uuid primary key default gen_random_uuid(),
  ref text unique not null,
  transaction_ref text not null references public.transactions(ref),
  type text not null default 'Partial' check (type in ('Full','Partial')),
  amount_cents bigint not null check (amount_cents >= 0),
  reason text not null default 'customer_request',
  status text not null default 'processing' check (status in ('processing','success','failed','pending_4eyes')),
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create index if not exists refunds_created_at_idx on public.refunds (created_at desc);

-- Auto-create a profile row whenever a new auth user is created
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', new.email),
    coalesce(new.raw_user_meta_data->>'role', 'Payments Ops')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row Level Security
alter table public.profiles enable row level security;
alter table public.transactions enable row level security;
alter table public.refunds enable row level security;

-- profiles: any authenticated staff member can see the staff directory;
-- a user may only update their own row.
create policy "profiles_select_authenticated" on public.profiles
  for select to authenticated using (true);
create policy "profiles_update_own" on public.profiles
  for update to authenticated using (id = auth.uid());

-- transactions / refunds: this is SwiftPay's internal ops console — any
-- authenticated staff member can read and write gateway data.
create policy "transactions_select_authenticated" on public.transactions
  for select to authenticated using (true);
create policy "transactions_insert_authenticated" on public.transactions
  for insert to authenticated with check (true);
create policy "transactions_update_authenticated" on public.transactions
  for update to authenticated using (true);

create policy "refunds_select_authenticated" on public.refunds
  for select to authenticated using (true);
create policy "refunds_insert_authenticated" on public.refunds
  for insert to authenticated with check (true);
create policy "refunds_update_authenticated" on public.refunds
  for update to authenticated using (true);
