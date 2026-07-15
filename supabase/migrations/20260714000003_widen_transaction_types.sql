-- The payment initiator UI also offers PayShap and WA Pay channels.
alter table public.transactions drop constraint transactions_type_check;
alter table public.transactions add constraint transactions_type_check
  check (type in ('CP','CNP','Push','Pull','PayShap','WA Pay'));
