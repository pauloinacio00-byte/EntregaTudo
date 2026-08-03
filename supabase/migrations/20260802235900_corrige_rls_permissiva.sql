-- Corrige políticas de RLS permissivas demais no Entrega Tudo.
-- Contexto completo: logs/desenvolvimento.md, item "Etapa 4: segredos
-- no código-fonte (chave TomTom + PIN do admin)", registro de 2026-08-02.
--
-- Cria um conceito real de admin no banco (tabela + função is_admin()),
-- substituindo o PIN client-side, e fecha regras que hoje valem `true`
-- para qualquer pessoa, logada ou não. Nada aqui remove leitura pública
-- que já era intencional (avaliações, locais, avisos, configurações
-- continuam visíveis a todos) nem a criação sem login Google (o app
-- também suporta login só por e-mail/apelido, sem sessão Supabase Auth).
--
-- Como desfazer: script de reversão em docs/rollback_20260802_rls.sql
-- (recria exatamente as regras antigas, tal como estavam antes desta
-- migration).

begin;

-- ── Conceito de admin ────────────────────────────────────────────────
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admins enable row level security;

drop policy if exists admins_select_self on public.admins;
create policy admins_select_self on public.admins
  for select
  using (auth.uid() = user_id);

create or replace function public.is_admin(uid uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins a where a.user_id = uid);
$$;

insert into public.admins (user_id)
values ('9af58470-79b0-4b7f-93da-f81a98390001')
on conflict (user_id) do nothing;

-- ── drivers ───────────────────────────────────────────────────────────
-- Antes: drivers_delete e drivers_insert valiam "true" -- qualquer um
-- apagava ou criava motorista sem checagem nenhuma. drivers_read e
-- drivers_select_all também valiam "true", expondo e-mail de todo mundo.
-- drivers_delete_own, drivers_insert_own e drivers_update_own já
-- estavam corretas e não são tocadas.
drop policy if exists drivers_delete on public.drivers;
drop policy if exists drivers_insert on public.drivers;
drop policy if exists drivers_read on public.drivers;
drop policy if exists drivers_select_all on public.drivers;

create policy drivers_delete_admin on public.drivers
  for delete
  using (public.is_admin(auth.uid()));

create policy drivers_select_own on public.drivers
  for select
  using ((auth.uid())::text = id or (auth.uid())::text = (user_id)::text);

create policy drivers_select_admin on public.drivers
  for select
  using (public.is_admin(auth.uid()));

-- ── places ────────────────────────────────────────────────────────────
-- places_delete (só o autor apaga) já estava correta -- mantida.
-- Adiciona: admin também pode apagar (usado no painel admin).
create policy places_delete_admin on public.places
  for delete
  using (public.is_admin(auth.uid()));

-- ── flags / mrevs / rrevs ────────────────────────────────────────────
-- Antes: 1 regra "public_all" (ALL, true/true) por tabela -- qualquer
-- um lia, criava, EDITAVA e APAGAVA qualquer avaliação/denúncia de
-- qualquer pessoa. Leitura e criação continuam abertas (o app permite
-- avaliar sem login Google); editar/apagar passam a exigir admin --
-- hoje só o painel admin edita (ocultar) ou apaga avaliação.
drop policy if exists public_all on public.flags;
create policy flags_select on public.flags for select using (true);
create policy flags_insert on public.flags for insert with check (true);
create policy flags_update_admin on public.flags for update using (public.is_admin(auth.uid()));
create policy flags_delete_admin on public.flags for delete using (public.is_admin(auth.uid()));

drop policy if exists public_all on public.mrevs;
create policy mrevs_select on public.mrevs for select using (true);
create policy mrevs_insert on public.mrevs for insert with check (true);
create policy mrevs_update_admin on public.mrevs for update using (public.is_admin(auth.uid()));
create policy mrevs_delete_admin on public.mrevs for delete using (public.is_admin(auth.uid()));

drop policy if exists public_all on public.rrevs;
create policy rrevs_select on public.rrevs for select using (true);
create policy rrevs_insert on public.rrevs for insert with check (true);
create policy rrevs_update_admin on public.rrevs for update using (public.is_admin(auth.uid()));
create policy rrevs_delete_admin on public.rrevs for delete using (public.is_admin(auth.uid()));

-- ── announcements ─────────────────────────────────────────────────────
-- Antes: qualquer um criava OU apagava avisos "oficiais" -- risco de
-- golpe/phishing se alguém forjasse um aviso lido como comunicado real
-- do app. ann_select (leitura pública) já estava correta -- mantida.
drop policy if exists ann_insert on public.announcements;
drop policy if exists ann_delete on public.announcements;
create policy ann_insert_admin on public.announcements for insert with check (public.is_admin(auth.uid()));
create policy ann_delete_admin on public.announcements for delete using (public.is_admin(auth.uid()));

-- ── configuracoes ─────────────────────────────────────────────────────
-- Antes: qualquer motorista logado (não só admin) podia mudar config,
-- ex.: preço do combustível usado na precificação de frete pra todo
-- mundo. config_select_all (leitura pública) mantida -- dado não sensível.
drop policy if exists config_update_authenticated on public.configuracoes;
create policy config_update_admin on public.configuracoes
  for update
  using (public.is_admin(auth.uid()));

-- ── fretes ────────────────────────────────────────────────────────────
-- Antes: fretes_select_all (true) expunha nome, telefone e endereço de
-- QUALQUER chamado de frete pra qualquer um, logado ou não. A aba Frete
-- do app já exige login Google real (checagem de UUID) antes de mostrar
-- qualquer chamado, então exigir auth.uid() aqui não muda o comportamento
-- de quem já usa a aba normalmente.
drop policy if exists fretes_select_all on public.fretes;
drop policy if exists fretes_select_own_hist on public.fretes;
create policy fretes_select_scoped on public.fretes
  for select
  using (
    auth.uid() is not null
    and (
      status = 'aguardando'
      or auth.uid() = driver_id
      or public.is_admin(auth.uid())
    )
  );

-- Antes: a condição "status = 'aguardando'" sozinha (sem checar login)
-- deixava qualquer pessoa, mesmo sem estar autenticada, editar um frete
-- pendente. Passa a exigir login também nesse caso.
drop policy if exists fretes_update_own_or_claim on public.fretes;
create policy fretes_update_own_or_claim on public.fretes
  for update
  using (
    auth.uid() = driver_id
    or (status = 'aguardando' and auth.uid() is not null)
  );

-- fretes_insert_temp NÃO foi tocada -- tabela ainda em fase de teste
-- (ver comentário "@STATE-TEMP" no app: o fluxo real de criação de
-- frete pelo cliente ainda não existe). Revisar quando esse fluxo for
-- construído de verdade.

commit;
