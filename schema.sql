-- PLATA · Esquema inicial para Supabase (PostgreSQL)
-- Ejecuta TODO este archivo en Supabase > SQL Editor > New query.
-- Seguridad: cada usuario solo puede leer y modificar sus propios registros.

create extension if not exists pgcrypto;

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type text not null check (type in ('income','expense')),
  description text not null check (char_length(trim(description)) between 1 and 140),
  amount numeric(14,0) not null check (amount > 0),
  category text not null default 'General',
  is_initial boolean not null default false,
  notes text,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint initial_must_be_income check (not is_initial or type = 'income')
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  transaction_id uuid not null references public.transactions(id) on delete cascade,
  amount numeric(14,0) not null check (amount > 0),
  method text not null check (method in ('Efectivo','Transferencia','Nequi','Bancolombia','Daviplata','Bre-B','Otro')),
  note text,
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index if not exists transactions_owner_occurred_idx on public.transactions(owner_id, occurred_at desc);
create index if not exists transactions_owner_type_idx on public.transactions(owner_id, type);
create index if not exists payments_owner_paid_idx on public.payments(owner_id, paid_at desc);
create index if not exists payments_transaction_idx on public.payments(transaction_id);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists transactions_set_updated_at on public.transactions;
create trigger transactions_set_updated_at before update on public.transactions
for each row execute function public.set_updated_at();

alter table public.transactions enable row level security;
alter table public.payments enable row level security;

drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own" on public.transactions for select to authenticated
using ((select auth.uid()) = owner_id);
drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own" on public.transactions for insert to authenticated
with check ((select auth.uid()) = owner_id);
drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own" on public.transactions for update to authenticated
using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own" on public.transactions for delete to authenticated
using ((select auth.uid()) = owner_id);

drop policy if exists "payments_select_own" on public.payments;
create policy "payments_select_own" on public.payments for select to authenticated
using ((select auth.uid()) = owner_id);
drop policy if exists "payments_insert_own" on public.payments;
create policy "payments_insert_own" on public.payments for insert to authenticated
with check (
  (select auth.uid()) = owner_id
  and exists (
    select 1 from public.transactions t
    where t.id = transaction_id and t.owner_id = (select auth.uid())
  )
);
drop policy if exists "payments_update_own" on public.payments;
create policy "payments_update_own" on public.payments for update to authenticated
using ((select auth.uid()) = owner_id)
with check (
  (select auth.uid()) = owner_id
  and exists (select 1 from public.transactions t where t.id = transaction_id and t.owner_id = (select auth.uid()))
);
drop policy if exists "payments_delete_own" on public.payments;
create policy "payments_delete_own" on public.payments for delete to authenticated
using ((select auth.uid()) = owner_id);

-- El navegador usa únicamente la clave publishable/anon junto con una sesión autenticada.
-- No copies la clave service_role al frontend. Los totales se calculan sumando pagos reales.
