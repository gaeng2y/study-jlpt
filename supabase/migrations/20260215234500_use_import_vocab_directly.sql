-- Switch app content source from content_items to import_jlpt_vocab.
-- Keeps old tables intact but routes reads/SRS references to import_jlpt_vocab.

create extension if not exists pgcrypto;

-- 1) Ensure import_jlpt_vocab has a stable UUID primary key.
alter table if exists public.import_jlpt_vocab
add column if not exists id uuid;

update public.import_jlpt_vocab
set id = gen_random_uuid()
where id is null;

alter table if exists public.import_jlpt_vocab
alter column id set default gen_random_uuid();

alter table if exists public.import_jlpt_vocab
alter column id set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.import_jlpt_vocab'::regclass
      and contype = 'p'
  ) then
    alter table public.import_jlpt_vocab
      add constraint import_jlpt_vocab_pkey primary key (id);
  end if;
end $$;

-- 2) Make import_jlpt_vocab readable by app clients.
drop policy if exists "import_table_no_access" on public.import_jlpt_vocab;

create policy "import_vocab_read_all_public" on public.import_jlpt_vocab
for select to public
using (is_active = true);

-- 3) Remap existing SRS/Favorites rows to import_jlpt_vocab ids by vocab fields.
-- Skip this step when content_items has already been dropped.
do $$
begin
  if to_regclass('public.content_items') is not null
     and to_regclass('public.user_srs') is not null then
    execute $sql$
      with mapped as (
        select
          c.id as old_id,
          i.id as new_id
        from public.content_items c
        join public.import_jlpt_vocab i
          on i.kind = c.kind
         and i.jlpt_level = c.jlpt_level
         and i.jp = c.jp
         and coalesce(i.reading, '') = coalesce(c.reading, '')
         and i.meaning_ko = c.meaning_ko
      )
      update public.user_srs u
      set content_id = mapped.new_id
      from mapped
      where u.content_id = mapped.old_id
    $sql$;
  end if;

  if to_regclass('public.content_items') is not null
     and to_regclass('public.user_favorites') is not null then
    execute $sql$
      with mapped as (
        select
          c.id as old_id,
          i.id as new_id
        from public.content_items c
        join public.import_jlpt_vocab i
          on i.kind = c.kind
         and i.jlpt_level = c.jlpt_level
         and i.jp = c.jp
         and coalesce(i.reading, '') = coalesce(c.reading, '')
         and i.meaning_ko = c.meaning_ko
      )
      update public.user_favorites f
      set content_id = mapped.new_id
      from mapped
      where f.content_id = mapped.old_id
    $sql$;
  end if;

  if to_regclass('public.user_srs') is not null then
    execute $sql$
      delete from public.user_srs u
      where not exists (
        select 1 from public.import_jlpt_vocab i where i.id = u.content_id
      )
    $sql$;
  end if;

  if to_regclass('public.user_favorites') is not null then
    execute $sql$
      delete from public.user_favorites f
      where not exists (
        select 1 from public.import_jlpt_vocab i where i.id = f.content_id
      )
    $sql$;
  end if;
end $$;

-- 4) Re-point foreign keys.
alter table if exists public.user_srs
drop constraint if exists user_srs_content_id_fkey;

alter table if exists public.user_srs
add constraint user_srs_content_id_fkey
foreign key (content_id) references public.import_jlpt_vocab(id) on delete cascade;

alter table if exists public.user_favorites
drop constraint if exists user_favorites_content_id_fkey;

alter table if exists public.user_favorites
add constraint user_favorites_content_id_fkey
foreign key (content_id) references public.import_jlpt_vocab(id) on delete cascade;

create index if not exists idx_import_vocab_level on public.import_jlpt_vocab(jlpt_level);
create index if not exists idx_import_vocab_jp on public.import_jlpt_vocab(jp);
