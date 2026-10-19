-- ============================================================
-- SumaQT Studio — Esquema del Flujo 2: Orden de Trabajo
-- ============================================================

-- ============ 1. TABLAS ============

create table if not exists public.ordenes (
  id uuid primary key default gen_random_uuid(),
  nombre_proyecto text not null,
  cliente_nombre text not null,
  cliente_email text not null,
  total_imagenes int not null check (total_imagenes > 0),
  imagenes_procesadas int not null default 0,
  estado text not null default 'pendiente'
    check (estado in ('pendiente','procesando','entregada')),
  created_at timestamptz not null default now(),
  cerrada_en timestamptz
);

create table if not exists public.archivos_orden (
  id uuid primary key default gen_random_uuid(),
  orden_id uuid not null references public.ordenes(id) on delete cascade,
  nombre_original text not null,
  storage_path_original text,
  storage_path_resultado text,
  url_resultado text,
  estado text not null default 'procesado'
    check (estado in ('procesado','error')),
  created_at timestamptz not null default now()
);

create index if not exists idx_archivos_orden_id
  on public.archivos_orden(orden_id);

-- ============ 2. MÉTRICAS (resultado medible) ============

create or replace view public.vw_metricas_ordenes as
select
  count(*) filter (where estado = 'entregada')           as ordenes_cerradas,
  coalesce(sum(imagenes_procesadas), 0)                  as imagenes_procesadas,
  coalesce(avg(extract(epoch from (cerrada_en - created_at))), 0)
                                                         as seg_promedio_entrega
from public.ordenes;

-- ============ 3. BUCKET DE STORAGE ============

insert into storage.buckets (id, name, public)
values ('orden-imagenes', 'orden-imagenes', true)
on conflict (id) do nothing;

-- ============ 4. RLS (habilitar + políticas) ============
-- Red de seguridad: el backend usa service_role (bypasa RLS).
-- Las políticas permiten anon/authenticated por si se usa la anon key.

alter table public.ordenes enable row level security;
alter table public.archivos_orden enable row level security;

drop policy if exists "ordenes_full_access" on public.ordenes;
create policy "ordenes_full_access" on public.ordenes
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "archivos_full_access" on public.archivos_orden;
create policy "archivos_full_access" on public.archivos_orden
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "bucket_ordenes_lectura_escritura" on storage.objects;
create policy "bucket_ordenes_lectura_escritura" on storage.objects
  for all to anon, authenticated
  using (bucket_id = 'orden-imagenes')
  with check (bucket_id = 'orden-imagenes');
