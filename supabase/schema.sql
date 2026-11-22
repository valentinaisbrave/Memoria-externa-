-- Ejecuta una sola vez en Supabase > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  created_at timestamptz not null default now()
);
create table if not exists public.memories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_name text not null check (char_length(file_name) between 1 and 150),
  file_type text not null check (file_type in ('image','pdf','txt','docx','poem','text','folder')),
  description text not null default '',
  text_content text,
  storage_path text,
  position_x integer not null default 0,
  position_y integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists memories_created_idx on public.memories(created_at desc);
create index if not exists memories_user_idx on public.memories(user_id);
create table if not exists public.desktop_settings (
  id integer primary key default 1 check (id = 1),
  desktop_width integer not null default 3000,
  desktop_height integer not null default 2100,
  background_settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
insert into public.desktop_settings(id) values(1) on conflict do nothing;

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 insert into public.profiles (id, username)
 values (new.id, 'usuario_' || left(new.id::text, 8)) on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.touch_memory() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists touch_memory on public.memories;
create trigger touch_memory before update on public.memories for each row execute procedure public.touch_memory();

alter table public.profiles enable row level security;
alter table public.memories enable row level security;
alter table public.desktop_settings enable row level security;

drop policy if exists "Perfiles visibles" on public.profiles;
create policy "Perfiles visibles" on public.profiles for select to anon, authenticated using (true);
drop policy if exists "Editar perfil propio" on public.profiles;
create policy "Editar perfil propio" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
drop policy if exists "Leer memorias" on public.memories;
create policy "Leer memorias" on public.memories for select to anon, authenticated using (true);
drop policy if exists "Crear memoria propia" on public.memories;
create policy "Crear memoria propia" on public.memories for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "Modificar memoria propia" on public.memories;
create policy "Modificar memoria propia" on public.memories for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "Borrar memoria propia" on public.memories;
create policy "Borrar memoria propia" on public.memories for delete to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "Leer configuración" on public.desktop_settings;
create policy "Leer configuración" on public.desktop_settings for select to anon, authenticated using (true);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('memorias','memorias',true,10485760, array['image/jpeg','image/png','image/webp','application/pdf','text/plain','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Archivos públicos" on storage.objects;
create policy "Archivos públicos" on storage.objects for select to anon, authenticated using (bucket_id = 'memorias');
drop policy if exists "Subir a carpeta personal" on storage.objects;
create policy "Subir a carpeta personal" on storage.objects for insert to authenticated with check (bucket_id='memorias' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists "Modificar archivos propios" on storage.objects;
create policy "Modificar archivos propios" on storage.objects for update to authenticated using (bucket_id='memorias' and (storage.foldername(name))[1] = (select auth.uid())::text) with check (bucket_id='memorias' and (storage.foldername(name))[1] = (select auth.uid())::text);
drop policy if exists "Borrar archivos propios" on storage.objects;
create policy "Borrar archivos propios" on storage.objects for delete to authenticated using (bucket_id='memorias' and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Realtime. Si la tabla ya existe en la publicación, se ignora el aviso.
do $$ begin alter publication supabase_realtime add table public.memories;
exception when duplicate_object then null; end $$;
