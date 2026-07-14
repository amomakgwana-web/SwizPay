-- handle_new_user() is only ever invoked by the on_auth_user_created trigger
-- (running as the table owner); it must not be publicly callable as an RPC.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
