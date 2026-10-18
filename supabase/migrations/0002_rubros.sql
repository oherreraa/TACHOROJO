-- Rubros (sectores) para que la app afine la clasificación según la actividad del usuario.
create table public.industry_sectors (
  id text primary key check (id ~ '^[a-z_]+$'),
  name_es text not null,
  name_en text not null,
  description_es text not null,
  prompt_context_es text not null,
  display_order int not null,
  active boolean not null default true
);

create table public.sector_waste_profiles (
  id bigint generated always as identity primary key,
  sector_id text not null references public.industry_sectors(id),
  waste_name_es text not null,
  examples_es text,
  primary_basel_code text references public.basel_codes(code),
  alt_basel_codes text[] not null default '{}',
  hazard_type_ids text[] not null default '{}',
  hazardous_typical boolean not null,
  frequency text not null check (frequency in ('alta','media','baja')),
  question_hint_es text,
  basis text not null default 'inferencia' check (basis in ('texto_oficial','inferencia')),
  verified boolean not null default false
);
create index on public.sector_waste_profiles (sector_id, frequency);
create index on public.sector_waste_profiles (primary_basel_code);
create index on public.sector_waste_profiles using gin (hazard_type_ids);
create index on public.sector_waste_profiles using gin (waste_name_es extensions.gin_trgm_ops);

alter table public.plants add column sector_id text references public.industry_sectors(id);
alter table public.classifications add column sector_id text references public.industry_sectors(id);
alter table public.test_cases add column sector_id text references public.industry_sectors(id);
alter table public.ml_samples add column sector_id text references public.industry_sectors(id);
create index on public.plants (sector_id);
create index on public.classifications (sector_id);
create index on public.test_cases (sector_id);
create index on public.ml_samples (sector_id);

alter table public.industry_sectors enable row level security;
alter table public.sector_waste_profiles enable row level security;
create policy "lectura publica" on public.industry_sectors for select to anon, authenticated using (true);
create policy "lectura publica" on public.sector_waste_profiles for select to anon, authenticated using (true);

create view public.v_sector_classifications with (security_invoker = true) as
select sector_id, country_code, classification, count(*) as total,
       count(*) filter (where precautionary_applied) as precautorios
from public.classifications
group by sector_id, country_code, classification;
