-- Script de emergência: desfaz a migration
-- supabase/migrations/20260802235900_corrige_rls_permissiva.sql,
-- recriando exatamente as regras como estavam antes (conferido pelos
-- resultados de pg_policies em 2026-08-02, ver logs/desenvolvimento.md).
--
-- Só usar se a correção quebrar algum fluxo do app em produção e não
-- der tempo de corrigir a regra nova diretamente. Isso volta a abrir
-- as brechas descritas no log -- é uma medida temporária, não uma
-- solução.

begin;

drop policy if exists drivers_delete_admin on public.drivers;
drop policy if exists drivers_select_own on public.drivers;
drop policy if exists drivers_select_admin on public.drivers;
create policy drivers_delete on public.drivers for delete using (true);
create policy drivers_insert on public.drivers for insert with check (true);
create policy drivers_read on public.drivers for select using (true);
create policy drivers_select_all on public.drivers for select using (true);

drop policy if exists places_delete_admin on public.places;

drop policy if exists flags_select on public.flags;
drop policy if exists flags_insert on public.flags;
drop policy if exists flags_update_admin on public.flags;
drop policy if exists flags_delete_admin on public.flags;
create policy public_all on public.flags for all using (true) with check (true);

drop policy if exists mrevs_select on public.mrevs;
drop policy if exists mrevs_insert on public.mrevs;
drop policy if exists mrevs_update_admin on public.mrevs;
drop policy if exists mrevs_delete_admin on public.mrevs;
create policy public_all on public.mrevs for all using (true) with check (true);

drop policy if exists rrevs_select on public.rrevs;
drop policy if exists rrevs_insert on public.rrevs;
drop policy if exists rrevs_update_admin on public.rrevs;
drop policy if exists rrevs_delete_admin on public.rrevs;
create policy public_all on public.rrevs for all using (true) with check (true);

drop policy if exists ann_insert_admin on public.announcements;
drop policy if exists ann_delete_admin on public.announcements;
create policy ann_insert on public.announcements for insert with check (true);
create policy ann_delete on public.announcements for delete using (true);

drop policy if exists config_update_admin on public.configuracoes;
create policy config_update_authenticated on public.configuracoes for update using (auth.uid() is not null);

drop policy if exists fretes_select_scoped on public.fretes;
create policy fretes_select_all on public.fretes for select using (true);
create policy fretes_select_own_hist on public.fretes for select using (true);

drop policy if exists fretes_update_own_or_claim on public.fretes;
create policy fretes_update_own_or_claim on public.fretes for update
  using ((auth.uid() = driver_id) or (status = 'aguardando'::text));

-- admins e is_admin() não são removidos por padrão -- são inofensivos
-- sozinhos (só passam a existir, não quebram nada se ficarem sem uso).
-- Descomente as linhas abaixo só se quiser remover por completo:
-- drop function if exists public.is_admin(uuid);
-- drop table if exists public.admins;

commit;
