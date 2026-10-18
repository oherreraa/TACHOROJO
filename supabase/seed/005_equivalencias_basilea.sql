-- Equivalencias entre Basilea y las normas de cada país.
-- Perú y Chile adoptan los códigos de las Listas A y B; Chile equipara sus Listas I y II con el Anexo I (categorías Y).
-- México tiene su propio sistema (NOM-052): las equivalencias son por concepto y quedan marcadas como inferencia.

-- Chile: Listas I, II y III -> categorías Y y códigos A
insert into public.basel_country_map (country_code, basel_code, local_code, local_name, instrument_id, listing_id, map_type, confidence, basis, verified, notes)
select 'CL', l.basel_code, l.entry_key, left(l.description, 160), l.instrument_id, l.id,
  case when l.listing_code = 'LISTA-III' then 'parcial' else 'exacto' end,
  case when l.listing_code = 'LISTA-III' then 'media' else 'alta' end,
  case when l.listing_code = 'LISTA-III' then 'inferencia' else 'texto_oficial' end,
  l.listing_code <> 'LISTA-III',
  case when l.listing_code = 'LISTA-III' then 'Equivalencia inferida; validar con Jazmín' else 'Misma categoría y orden que el Anexo I de Basilea' end
from public.country_waste_listings l
where l.country_code = 'CL' and l.basel_code is not null
on conflict do nothing;

-- Perú: Anexo III (Lista A) y Anexo V (Lista B) del D.S. 014-2017-MINAM
insert into public.basel_country_map (country_code, basel_code, local_code, local_name, instrument_id, map_type, confidence, basis, verified, notes)
select 'PE', b.code, b.code, left(b.description_es, 160), i.id, 'adopta', 'alta', 'texto_oficial', true,
  case when b.list = 'A' then 'Anexo III (Lista A) del D.S. 014-2017-MINAM' else 'Anexo V (Lista B) del D.S. 014-2017-MINAM' end
from public.basel_codes b cross join public.legal_instruments i
where i.code = 'DS-014-2017-MINAM' and b.code = any(array['A1010','A1020','A1030','A1040','A1050','A1060','A1070','A1080','A1090','A1100','A1110','A1120','A1130','A1140','A1150','A1160','A1170','A1180','A1190','A2010','A2020','A2030','A2040','A2050','A2060','A3010','A3020','A3030','A3040','A3050','A3060','A3070','A3080','A3090','A3100','A3110','A3120','A3130','A3140','A3150','A3160','A3170','A3180','A3190','A3200','A4010','A4020','A4030','A4040','A4050','A4060','A4070','A4080','A4090','A4100','A4110','A4120','A4130','A4140','A4150','A4160','B1010','B1020','B1030','B1031','B1040','B1050','B1060','B1070','B1080','B1090','B1100','B1110','B1115','B1120','B1130','B1140','B1150','B1160','B1170','B1180','B1190','B1200','B1210','B1220','B1230','B1240','B1250','B2010','B2020','B2030','B2040','B2050','B2060','B2070','B2080','B2090','B2100','B2110','B2120','B2130','B3010','B3020','B3026','B3027','B3030','B3035','B3040','B3050','B3060','B3065','B3070','B3080','B3090','B3100','B3110','B3120','B3130','B3140','B4010','B4020','B4030'])
on conflict do nothing;

-- Chile: Lista A y Lista B del DS 148 (art. 90 original, art. 104 en el texto de 2021)
insert into public.basel_country_map (country_code, basel_code, local_code, local_name, instrument_id, map_type, confidence, basis, verified, notes)
select 'CL', b.code, b.code, left(b.description_es, 160), i.id, 'adopta', 'alta', 'texto_oficial', true,
  case when b.list = 'A' then 'Lista A del DS 148 (art. 90 original, art. 104 en el texto de 2021)' else 'Lista B del DS 148 (art. 90 original, art. 104 en el texto de 2021)' end
from public.basel_codes b cross join public.legal_instruments i
where i.code = 'DS-148-2003-MINSAL' and b.code = any(array['A1010','A1020','A1030','A1040','A1050','A1060','A1070','A1080','A1090','A1100','A1110','A1120','A1130','A1140','A1150','A1160','A1170','A1180','A2010','A2020','A2030','A2040','A2050','A2060','A3010','A3020','A3030','A3040','A3050','A3060','A3070','A3080','A3090','A3100','A3110','A3120','A3130','A3140','A3150','A3160','A3170','A3180','A3190','A4010','A4020','A4030','A4040','A4050','A4060','A4070','A4080','A4090','A4100','A4110','A4120','A4130','A4140','A4150','A4160','B1010','B1020','B1030','B1040','B1050','B1060','B1070','B1080','B1090','B1100','B1110','B1120','B1130','B1140','B1150','B1160','B1170','B1180','B1190','B1200','B1210','B1220','B1230','B1240','B2010','B2020','B2030','B2040','B2050','B2060','B2070','B2080','B2090','B2100','B2110','B2120','B3010','B3020','B3030','B3040','B3050','B3060','B3070','B3080','B3090','B3100','B3110','B3120','B3130','B3140','B4010','B4020','B4030'])
on conflict do nothing;

-- México: NOM-052 -> Basilea (por concepto, inferido)
insert into public.basel_country_map (country_code, basel_code, local_code, local_name, instrument_id, map_type, confidence, basis, verified, notes)
select 'MX', v.bc, v.lc, v.ln, i.id, v.mt, v.conf, 'inferencia', false, v.nt
from (values
 ('A4140','Listado 3','Productos químicos fuera de especificaciones o caducos (tóxicos agudos)','parcial','media','Categoría equivalente en concepto; NOM-052 lista sustancias concretas por CAS'),
 ('A4140','Listado 4','Productos químicos fuera de especificaciones o caducos (tóxicos crónicos)','parcial','media','Categoría equivalente en concepto; NOM-052 lista sustancias concretas por CAS'),
 ('A2050','NE 01-NE 03','Residuos de asbesto de fuente no específica','parcial','alta','Equivalencia por el contenido (asbesto)'),
 ('A4050','NE 04, NE 07-NE 09, NE 11','Residuos con cianuros de tratamiento térmico y galvanoplastia','parcial','media','Equivalencia por el contenido (cianuros)'),
 ('A1050','NE 05','Lodos de tratamiento de aguas residuales de galvanoplastia','parcial','media','Basilea A1050 = lodos galvánicos'),
 ('A1170','RP 1/01-RP 1/02','Baterías, celdas y pilas del Listado 5','parcial','media','Las pilas Ni-Cd y Zn-Ag corresponden a baterías sin clasificar'),
 ('A2030','RP 2/01-RP 2/05','Catalizadores gastados del Listado 5','parcial','media','Equivalencia por el tipo de residuo')
) v(bc,lc,ln,mt,conf,nt)
join public.legal_instruments i on i.code = 'NOM-052-SEMARNAT-2005'
on conflict do nothing;
