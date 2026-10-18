-- TachoRojo · esquema completo de la base de datos (estado actual en Supabase).
-- Proyecto Supabase: TachoRojo (región sa-east-1). Se aplicó en varias migraciones; aquí está consolidado.
-- Orden: referencias -> Basilea -> listados nacionales -> permisos -> operación -> ML -> estadísticas -> RLS.

create extension if not exists vector with schema extensions;
create extension if not exists pg_trgm with schema extensions;
create schema if not exists private;

create or replace function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

-- 1. PAÍSES Y NORMAS ---------------------------------------------------------
create table public.countries (
  code text primary key check (code ~ '^[A-Z]{2}$'),
  name text not null,
  active boolean not null default true
);

create table public.legal_instruments (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  code text not null,
  title text not null,
  kind text not null check (kind in ('ley','reglamento','norma_tecnica','convenio','guia','otro')),
  year int,
  source_url text,
  verified boolean not null default false,
  notes text,
  unique (country_code, code)
);
create index on public.legal_instruments (country_code);

-- 2. CONTENEDORES Y PELIGROSIDAD ---------------------------------------------
create table public.container_schemes (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  scope text not null check (scope in ('municipal','no_municipal')),
  color text not null,
  label text not null,
  waste_type text not null,
  hazardous boolean not null default false,
  instrument_id bigint references public.legal_instruments(id),
  verified boolean not null default false,
  notes text,
  unique (country_code, scope, color)
);
create index on public.container_schemes (instrument_id);

create table public.ghs_pictograms (
  code text primary key,
  name_es text not null,
  name_en text not null,
  meaning_es text not null,
  un_symbol text
);

create table public.hazard_types (
  id text primary key,
  name_es text not null,
  description_es text,
  ghs_pictogram text references public.ghs_pictograms(code)
);
create index on public.hazard_types (ghs_pictogram);

create table public.country_hazard_categories (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  code text not null,
  name_es text not null,
  hazard_type text references public.hazard_types(id),
  instrument_id bigint references public.legal_instruments(id),
  verified boolean not null default false,
  unique (country_code, code)
);
create index on public.country_hazard_categories (hazard_type);
create index on public.country_hazard_categories (instrument_id);

-- 3. CONVENIO DE BASILEA ------------------------------------------------------
create table public.basel_groups (
  code text primary key,
  annex text not null check (annex in ('I','II','VIII','IX')),
  name_es text not null,
  name_en text not null
);

create table public.basel_codes (
  code text primary key,
  list text not null check (list in ('A','B','Y')),
  annex text check (annex in ('I','II','VIII','IX')),
  group_code text,
  description_es text not null,
  description_en text,
  hazardous boolean not null,
  status text not null default 'vigente' check (status in ('vigente','derogado')),
  effective_from date,
  effective_to date,
  related_codes text[],
  source text,
  note_es text,
  verified boolean not null default false
);
create index on public.basel_codes (annex, group_code);
create index on public.basel_codes (status);
create index on public.basel_codes (list, status, code);
create index on public.basel_codes using gin (related_codes);
create index on public.basel_codes using gin (description_es extensions.gin_trgm_ops);
create index on public.basel_codes using gin (description_en extensions.gin_trgm_ops);
create index on public.basel_codes using gin (to_tsvector('spanish', description_es));

create table public.basel_hazard_characteristics (
  h_code text primary key,
  un_class text not null,
  name_es text not null,
  name_en text not null,
  description_es text not null,
  description_en text not null,
  hazard_type text references public.hazard_types(id)
);
create index on public.basel_hazard_characteristics (hazard_type);

create table public.basel_disposal_operations (
  code text primary key,
  section text not null check (section in ('A','B')),
  description_es text not null,
  description_en text not null
);

create table public.basel_annex_notes (
  annex text not null,
  ord int not null,
  text_es text not null,
  text_en text not null,
  primary key (annex, ord)
);

-- 4. LISTADOS NACIONALES Y EQUIVALENCIAS CON BASILEA --------------------------
create table public.country_waste_listings (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  instrument_id bigint not null references public.legal_instruments(id),
  listing_code text not null,
  listing_name text not null,
  entry_key text not null,
  cas text,
  description text not null,
  hazard_codes text[] not null default '{}',
  group_label text,
  subgroup_label text,
  basel_code text references public.basel_codes(code),
  verified boolean not null default true,
  notes text,
  unique (instrument_id, listing_code, entry_key)
);
create index on public.country_waste_listings (country_code);
create index on public.country_waste_listings (instrument_id, listing_code);
create index on public.country_waste_listings (basel_code);
create index on public.country_waste_listings (entry_key);
create index on public.country_waste_listings (cas) where cas is not null;
create index on public.country_waste_listings using gin (hazard_codes);
create index on public.country_waste_listings using gin (description extensions.gin_trgm_ops);

create table public.basel_country_map (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  basel_code text not null references public.basel_codes(code),
  local_code text,
  local_name text,
  instrument_id bigint references public.legal_instruments(id),
  listing_id bigint references public.country_waste_listings(id),
  map_type text check (map_type in ('adopta','exacto','parcial','inferido')),
  confidence text check (confidence in ('alta','media','baja')),
  basis text check (basis in ('texto_oficial','inferencia')),
  verified boolean not null default false,
  notes text,
  unique (country_code, basel_code, local_code)
);
create index on public.basel_country_map (basel_code);
create index on public.basel_country_map (instrument_id);
create index on public.basel_country_map (listing_id);
create index on public.basel_country_map (country_code, local_code);
create index on public.basel_country_map (country_code, map_type);

create table public.country_hazard_basel_h (
  country_hazard_category_id bigint not null references public.country_hazard_categories(id) on delete cascade,
  h_code text not null references public.basel_hazard_characteristics(h_code),
  confidence text not null check (confidence in ('alta','media','baja')),
  basis text not null check (basis in ('texto_oficial','inferencia')),
  notes text,
  primary key (country_hazard_category_id, h_code)
);
create index on public.country_hazard_basel_h (h_code);

-- 5. NORMATIVA (RAG) ----------------------------------------------------------
create table public.legal_documents (
  id bigint generated always as identity primary key,
  instrument_id bigint references public.legal_instruments(id),
  title text not null,
  storage_path text,
  source_url text,
  sha256 text,
  downloaded_at timestamptz
);
create index on public.legal_documents (instrument_id);

create table public.norm_chunks (
  id bigint generated always as identity primary key,
  document_id bigint not null references public.legal_documents(id) on delete cascade,
  country_code text not null references public.countries(code),
  article text,
  content text not null,
  embedding extensions.vector(768)
);
create index on public.norm_chunks (document_id);
create index on public.norm_chunks (country_code);
create index on public.norm_chunks using hnsw (embedding extensions.vector_cosine_ops);

-- 6. PERMISOS, CATEGORÍAS DE GENERADOR Y REGLAS -------------------------------
create table public.federal_waste_classes (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  code text not null,
  name_es text not null,
  hazardous boolean,
  instrument_id bigint references public.legal_instruments(id),
  verified boolean not null default false,
  notes text,
  unique (country_code, code)
);
create index on public.federal_waste_classes (instrument_id);

create table public.generator_categories (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  code text not null,
  name_es text not null,
  min_kg_year numeric,
  max_kg_year numeric,
  registration_authority text,
  obligations text[] not null default '{}',
  instrument_id bigint references public.legal_instruments(id),
  verified boolean not null default false,
  unique (country_code, code)
);
create index on public.generator_categories (instrument_id);

create table public.permit_types (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  code text not null,
  name_es text not null,
  authority text,
  procedure_code text,
  required_before_operation boolean not null default true,
  instrument_id bigint references public.legal_instruments(id),
  verified boolean not null default false,
  notes text,
  unique (country_code, code)
);
create index on public.permit_types (instrument_id);

create table public.handling_rules (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  topic text not null check (topic in ('color','etiquetado','almacenamiento','segregacion','envasado')),
  applies_to text,
  rule_es text not null,
  instrument_id bigint references public.legal_instruments(id),
  source_url text,
  verified boolean not null default false,
  notes text,
  created_at timestamptz not null default now()
);
create index on public.handling_rules (country_code, topic);
create index on public.handling_rules (instrument_id);

-- 7. PLANTAS, ACCESOS Y SESIONES ----------------------------------------------
create table public.plants (
  id uuid primary key default gen_random_uuid(),
  country_code text not null references public.countries(code),
  name text not null,
  scope text not null default 'no_municipal' check (scope in ('municipal','no_municipal')),
  active boolean not null default true,
  generator_category_id bigint references public.generator_categories(id),
  created_at timestamptz not null default now()
);
create index on public.plants (country_code);
create index on public.plants (generator_category_id);

create table public.plant_container_overrides (
  id bigint generated always as identity primary key,
  plant_id uuid not null references public.plants(id) on delete cascade,
  waste_type text not null,
  color text not null,
  label text not null,
  unique (plant_id, waste_type)
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role text not null default 'operario' check (role in ('operario','responsable_ambiental','revisor','admin')),
  country_code text references public.countries(code),
  plant_id uuid references public.plants(id),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.profiles (country_code);
create index on public.profiles (plant_id);
create trigger profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

create table public.api_clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  key_hash text not null unique,
  scopes text[] not null default '{}',
  plant_id uuid references public.plants(id),
  active boolean not null default true,
  last_used_at timestamptz,
  created_at timestamptz not null default now()
);
create index on public.api_clients (plant_id);

create table public.device_sessions (
  session_id uuid primary key default gen_random_uuid(),
  device_hash text,
  country_code text references public.countries(code),
  plant_id uuid references public.plants(id),
  platform text,
  app_version text,
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now()
);
create index on public.device_sessions (country_code);
create index on public.device_sessions (plant_id);

create table public.access_logs (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  client_id uuid references public.api_clients(id) on delete set null,
  event text not null,
  success boolean not null default true,
  path text,
  ip_hash text,
  user_agent text,
  created_at timestamptz not null default now()
);
create index on public.access_logs (user_id);
create index on public.access_logs (client_id);
create index on public.access_logs (created_at desc);

-- 8. MACHINE LEARNING (catálogos usados por las clasificaciones) --------------
create table public.ml_models (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  version text not null,
  provider text not null,
  task text not null check (task in ('quality','classification','embedding','followup')),
  status text not null default 'draft' check (status in ('draft','shadow','active','retired')),
  params jsonb not null default '{}',
  created_at timestamptz not null default now(),
  unique (name, version)
);

create table public.prompt_versions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  version text not null,
  content text not null,
  active boolean not null default false,
  created_at timestamptz not null default now(),
  unique (name, version)
);

create table public.ml_datasets (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  country_code text references public.countries(code),
  created_at timestamptz not null default now()
);
create index on public.ml_datasets (country_code);

-- 9. PERMISOS SUBIDOS POR EL USUARIO ------------------------------------------
create table public.operating_permits (
  id uuid primary key default gen_random_uuid(),
  plant_id uuid not null references public.plants(id) on delete cascade,
  country_code text not null references public.countries(code),
  permit_type_id bigint not null references public.permit_types(id),
  generator_category_id bigint references public.generator_categories(id),
  permit_number text,
  issuing_authority text,
  issued_at date,
  expires_at date,
  document_path text,
  status text not null default 'pendiente' check (status in ('pendiente','vigente','vencido','rechazado')),
  uploaded_by uuid references public.profiles(id),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.operating_permits (plant_id);
create index on public.operating_permits (country_code);
create index on public.operating_permits (permit_type_id);
create index on public.operating_permits (generator_category_id);
create index on public.operating_permits (uploaded_by);
create index on public.operating_permits (reviewed_by);
create index on public.operating_permits (status, expires_at);
create trigger operating_permits_updated before update on public.operating_permits
  for each row execute function public.set_updated_at();

create table public.permit_authorized_wastes (
  id bigint generated always as identity primary key,
  permit_id uuid not null references public.operating_permits(id) on delete cascade,
  waste_name text not null,
  federal_class_id bigint references public.federal_waste_classes(id),
  local_code text,
  basel_code text references public.basel_codes(code),
  hazard_codes text[] not null default '{}',
  max_kg_year numeric,
  container_color text,
  handling_notes text,
  created_at timestamptz not null default now()
);
create index on public.permit_authorized_wastes (permit_id);
create index on public.permit_authorized_wastes (federal_class_id);
create index on public.permit_authorized_wastes (basel_code);

-- 10. OPERACIÓN: CLASIFICACIONES, SEGUIMIENTO Y REVISIONES --------------------
create table public.classifications (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.device_sessions(session_id),
  country_code text not null references public.countries(code),
  plant_id uuid references public.plants(id),
  scope text not null default 'no_municipal' check (scope in ('municipal','no_municipal')),
  photo_path text,
  detected text,
  conversation jsonb not null default '[]',
  result jsonb,
  classification text check (classification in ('PELIGROSO','NO_PELIGROSO','NO_SEGURO')),
  container_color text,
  basel_code text references public.basel_codes(code),
  confidence text check (confidence in ('alta','media','baja')),
  precautionary_applied boolean not null default false,
  model text,
  latency_ms int,
  model_id uuid references public.ml_models(id),
  prompt_version_id uuid references public.prompt_versions(id),
  permit_id uuid references public.operating_permits(id),
  authorized_waste_id bigint references public.permit_authorized_wastes(id),
  federal_class_id bigint references public.federal_waste_classes(id),
  matches_permit boolean,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.classifications (country_code);
create index on public.classifications (plant_id);
create index on public.classifications (session_id);
create index on public.classifications (basel_code);
create index on public.classifications (created_at desc);
create index on public.classifications (model_id);
create index on public.classifications (prompt_version_id);
create index on public.classifications (permit_id);
create index on public.classifications (authorized_waste_id);
create index on public.classifications (federal_class_id);
create trigger classifications_updated before update on public.classifications
  for each row execute function public.set_updated_at();

create table public.classification_reviews (
  id bigint generated always as identity primary key,
  classification_id uuid not null references public.classifications(id) on delete cascade,
  reviewer text not null,
  expected_classification text not null check (expected_classification in ('PELIGROSO','NO_PELIGROSO','NO_SEGURO')),
  expected_color text,
  expected_basel text,
  agrees boolean not null,
  notes text,
  reviewed_at timestamptz not null default now()
);
create index on public.classification_reviews (classification_id);

create table public.classification_events (
  id bigint generated always as identity primary key,
  classification_id uuid references public.classifications(id) on delete cascade,
  session_id uuid not null references public.device_sessions(session_id),
  event_type text not null check (event_type in ('photo_uploaded','quality_failed','question_asked','question_answered','summary_confirmed','summary_corrected','result_shown','precaution_applied','error')),
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index on public.classification_events (classification_id);
create index on public.classification_events (session_id);
create index on public.classification_events (created_at desc);

create table public.classification_feedback (
  id bigint generated always as identity primary key,
  classification_id uuid not null references public.classifications(id) on delete cascade,
  helpful boolean not null,
  comment text,
  created_at timestamptz not null default now()
);
create index on public.classification_feedback (classification_id);

create table public.waste_tracking (
  id uuid primary key default gen_random_uuid(),
  classification_id uuid not null references public.classifications(id) on delete cascade,
  plant_id uuid references public.plants(id),
  status text not null default 'generado' check (status in ('generado','acopiado','recolectado','dispuesto')),
  container_color text,
  weight_kg numeric(10,2),
  manifest_number text,
  generated_at timestamptz not null default now(),
  collected_at timestamptz,
  disposed_at timestamptz,
  responsible uuid references public.profiles(id),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.waste_tracking (classification_id);
create index on public.waste_tracking (plant_id);
create index on public.waste_tracking (responsible);
create index on public.waste_tracking (status);
create trigger waste_tracking_updated before update on public.waste_tracking
  for each row execute function public.set_updated_at();

create table public.test_cases (
  id bigint generated always as identity primary key,
  country_code text not null references public.countries(code),
  description text not null,
  expected_classification text not null check (expected_classification in ('PELIGROSO','NO_PELIGROSO','NO_SEGURO')),
  expected_color text,
  expected_basel text[]
);
create index on public.test_cases (country_code);

-- 11. MACHINE LEARNING (muestras, predicciones, evaluaciones, embeddings) -----
create table public.ml_samples (
  id bigint generated always as identity primary key,
  dataset_id uuid not null references public.ml_datasets(id) on delete cascade,
  classification_id uuid references public.classifications(id) on delete set null,
  photo_path text,
  label_classification text not null check (label_classification in ('PELIGROSO','NO_PELIGROSO','NO_SEGURO')),
  label_color text,
  label_basel text references public.basel_codes(code),
  split text not null default 'train' check (split in ('train','val','test')),
  labeled_by text,
  created_at timestamptz not null default now()
);
create index on public.ml_samples (dataset_id);
create index on public.ml_samples (classification_id);
create index on public.ml_samples (label_basel);

create table public.ml_predictions (
  id bigint generated always as identity primary key,
  classification_id uuid not null references public.classifications(id) on delete cascade,
  model_id uuid references public.ml_models(id),
  prompt_version_id uuid references public.prompt_versions(id),
  predicted_classification text check (predicted_classification in ('PELIGROSO','NO_PELIGROSO','NO_SEGURO')),
  predicted_basel text references public.basel_codes(code),
  probabilities jsonb,
  confidence numeric(5,4),
  latency_ms int,
  tokens_in int,
  tokens_out int,
  cost_usd numeric(10,6),
  is_shadow boolean not null default false,
  created_at timestamptz not null default now()
);
create index on public.ml_predictions (classification_id);
create index on public.ml_predictions (model_id);
create index on public.ml_predictions (prompt_version_id);
create index on public.ml_predictions (predicted_basel);

create table public.ml_evaluations (
  id bigint generated always as identity primary key,
  model_id uuid not null references public.ml_models(id) on delete cascade,
  dataset_id uuid references public.ml_datasets(id),
  prompt_version_id uuid references public.prompt_versions(id),
  metric text not null,
  value numeric not null,
  details jsonb,
  evaluated_at timestamptz not null default now()
);
create index on public.ml_evaluations (model_id);
create index on public.ml_evaluations (dataset_id);
create index on public.ml_evaluations (prompt_version_id);

create table public.image_embeddings (
  classification_id uuid primary key references public.classifications(id) on delete cascade,
  model_id uuid references public.ml_models(id),
  embedding extensions.vector(768) not null
);
create index on public.image_embeddings (model_id);
create index on public.image_embeddings using hnsw (embedding extensions.vector_cosine_ops);

-- 12. ESTADÍSTICAS Y VISTAS DE CONSULTA ----------------------------------------
create materialized view public.mv_daily_stats as
select date_trunc('day', created_at)::date as day,
       country_code, plant_id,
       count(*) as total,
       count(*) filter (where classification = 'PELIGROSO') as peligrosos,
       count(*) filter (where classification = 'NO_PELIGROSO') as no_peligrosos,
       count(*) filter (where classification = 'NO_SEGURO') as no_seguros,
       count(*) filter (where precautionary_applied) as precautorios,
       round(avg(latency_ms)) as latencia_ms
from public.classifications
group by 1,2,3;
create unique index on public.mv_daily_stats (day, country_code, plant_id) nulls not distinct;
revoke all on public.mv_daily_stats from anon, authenticated;

create view public.v_review_agreement with (security_invoker = true) as
select c.country_code,
       count(*) as revisadas,
       count(*) filter (where r.agrees) as coinciden,
       round(100.0 * count(*) filter (where r.agrees) / nullif(count(*),0), 1) as concordancia_pct
from public.classification_reviews r
join public.classifications c on c.id = r.classification_id
group by c.country_code;

create view public.v_top_basel with (security_invoker = true) as
select country_code, basel_code, count(*) as veces
from public.classifications
where basel_code is not null
group by country_code, basel_code;

create view public.v_funnel with (security_invoker = true) as
select date_trunc('day', created_at)::date as day, event_type, count(distinct session_id) as sesiones
from public.classification_events
group by 1,2;

create view public.v_basel_by_country with (security_invoker = true) as
select m.country_code, m.basel_code, b.list, b.status, b.description_es, m.local_code, m.local_name,
       m.map_type, m.confidence, m.basis, m.verified, m.listing_id
from public.basel_country_map m
join public.basel_codes b on b.code = m.basel_code;

create view public.v_listing_basel with (security_invoker = true) as
select l.country_code, l.listing_code, l.entry_key, l.cas, l.description, l.hazard_codes,
       l.basel_code, b.description_es as basel_description_es
from public.country_waste_listings l
left join public.basel_codes b on b.code = l.basel_code;

create view public.v_country_hazard_basel with (security_invoker = true) as
select c.country_code, c.code as local_code, c.name_es as local_name, x.h_code, h.name_es as h_name_es,
       x.confidence, x.basis, h.hazard_type
from public.country_hazard_basel_h x
join public.country_hazard_categories c on c.id = x.country_hazard_category_id
join public.basel_hazard_characteristics h on h.h_code = x.h_code;

-- 13. FUNCIONES DE ACCESO Y MANTENIMIENTO --------------------------------------
create or replace function private.refresh_stats() returns void
language sql security definer set search_path = '' as $$
  refresh materialized view concurrently public.mv_daily_stats;
$$;
create or replace function private.user_role() returns text
language sql stable security definer set search_path = '' as $$
  select role from public.profiles where id = (select auth.uid()) and active;
$$;
create or replace function private.user_plant() returns uuid
language sql stable security definer set search_path = '' as $$
  select plant_id from public.profiles where id = (select auth.uid()) and active;
$$;
grant usage on schema private to authenticated;
grant execute on function private.user_role(), private.user_plant() to authenticated;

-- 14. SEGURIDAD (RLS) -----------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['countries','legal_instruments','container_schemes','ghs_pictograms','hazard_types',
    'country_hazard_categories','basel_codes','basel_groups','basel_hazard_characteristics','basel_disposal_operations',
    'basel_annex_notes','country_waste_listings','basel_country_map','country_hazard_basel_h','legal_documents','norm_chunks',
    'federal_waste_classes','generator_categories','permit_types','handling_rules','plants','plant_container_overrides',
    'profiles','api_clients','device_sessions','access_logs','ml_models','prompt_versions','ml_datasets',
    'operating_permits','permit_authorized_wastes','classifications','classification_reviews','classification_events',
    'classification_feedback','waste_tracking','test_cases','ml_samples','ml_predictions','ml_evaluations','image_embeddings']
  loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
  -- catálogos: lectura pública
  foreach t in array array['countries','legal_instruments','container_schemes','ghs_pictograms','hazard_types',
    'country_hazard_categories','basel_codes','basel_groups','basel_hazard_characteristics','basel_disposal_operations',
    'basel_annex_notes','country_waste_listings','basel_country_map','country_hazard_basel_h','federal_waste_classes',
    'generator_categories','permit_types','handling_rules']
  loop
    execute format('create policy "lectura publica" on public.%I for select to anon, authenticated using (true)', t);
  end loop;
  -- tablas internas: solo admin puede leer; el backend usa service_role
  foreach t in array array['access_logs','ml_models','prompt_versions','ml_datasets','ml_samples','ml_predictions',
    'ml_evaluations','api_clients','legal_documents','norm_chunks','test_cases']
  loop
    execute format('create policy "solo admin" on public.%I for select to authenticated using ((select private.user_role()) = ''admin'')', t);
  end loop;
end $$;

create policy "perfil propio o admin" on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select private.user_role()) = 'admin');
create policy "planta propia o admin" on public.plants for select to authenticated
  using (id = (select private.user_plant()) or (select private.user_role()) = 'admin');
create policy "clasificaciones de mi planta" on public.classifications for select to authenticated
  using (plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin');
create policy "revisores ven revisiones" on public.classification_reviews for select to authenticated
  using ((select private.user_role()) in ('responsable_ambiental','revisor','admin'));
create policy "revisores crean revisiones" on public.classification_reviews for insert to authenticated
  with check ((select private.user_role()) in ('responsable_ambiental','revisor','admin'));
create policy "seguimiento de mi planta" on public.waste_tracking for select to authenticated
  using (plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin');
create policy "responsables actualizan seguimiento" on public.waste_tracking for update to authenticated
  using ((select private.user_role()) in ('responsable_ambiental','admin') and (plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin'));
create policy "permisos de mi planta" on public.operating_permits for select to authenticated
  using (plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin');
create policy "responsables suben permisos" on public.operating_permits for insert to authenticated
  with check ((select private.user_role()) in ('responsable_ambiental','admin')
    and (plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin'));
create policy "responsables editan permisos" on public.operating_permits for update to authenticated
  using ((select private.user_role()) in ('responsable_ambiental','admin')
    and (plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin'));
create policy "residuos autorizados de mi planta" on public.permit_authorized_wastes for select to authenticated
  using (exists (select 1 from public.operating_permits p where p.id = permit_id
    and (p.plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin')));
create policy "responsables cargan residuos autorizados" on public.permit_authorized_wastes for insert to authenticated
  with check ((select private.user_role()) in ('responsable_ambiental','admin')
    and exists (select 1 from public.operating_permits p where p.id = permit_id
      and (p.plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin')));
create policy "responsables editan residuos autorizados" on public.permit_authorized_wastes for update to authenticated
  using ((select private.user_role()) in ('responsable_ambiental','admin')
    and exists (select 1 from public.operating_permits p where p.id = permit_id
      and (p.plant_id = (select private.user_plant()) or (select private.user_role()) = 'admin')));
-- Sin políticas a propósito (solo service_role desde n8n): device_sessions, classification_events,
-- classification_feedback, image_embeddings, plant_container_overrides.

-- 15. ALMACENAMIENTO PRIVADO -----------------------------------------------------
insert into storage.buckets (id, name, public) values
  ('waste-photos','waste-photos',false),('legal-docs','legal-docs',false),('permits','permits',false)
on conflict (id) do nothing;
