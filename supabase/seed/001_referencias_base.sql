-- Datos de referencia (países, normas, contenedores, GHS, peligrosidad, permisos, reglas de manejo).
-- Refleja el estado actual de la base. "verified = false" significa pendiente de validar por Jazmín Calderón.

insert into public.countries (code, name) values ('PE','Perú'),('CL','Chile'),('MX','México');

insert into public.legal_instruments (country_code, code, title, kind, year, source_url, verified, notes) values
('PE','DL-1278','Ley de Gestión Integral de Residuos Sólidos','ley',2016,null,false,'Pendiente de verificar'),
('PE','DS-014-2017-MINAM','Reglamento del D.L. 1278 (art. 30 y anexos)','reglamento',2017,null,false,'Pendiente de verificar'),
('PE','NTP-900.058:2019','Código de colores para contenedores de residuos','norma_tecnica',2019,'https://andina.pe/ingles/noticia-inacal-promueve-uso-codigo-colores-para-segregacion-responsable-residuos-solidos-840364.aspx',false,'2.ª edición, R.D. 003-2019-INACAL/DN (28/3/2019). Cubre ámbitos municipal y no municipal. Texto oficial no leído'),
('PE','DS-002-2022-VIVIENDA','Residuos de construcción y demolición','reglamento',2022,null,false,'Pendiente de verificar'),
('CL','DS-148-2003-MINSAL','Reglamento sanitario sobre manejo de residuos peligrosos','reglamento',2003,null,false,'Por investigar y verificar'),
('CL','LEY-20920','Ley Marco de Gestión de Residuos, REP y Fomento al Reciclaje','ley',2016,null,false,'Por investigar y verificar'),
('MX','LGPGIR','Ley General para la Prevención y Gestión Integral de los Residuos','ley',2003,null,false,'Por investigar y verificar'),
('MX','NOM-052-SEMARNAT-2005','Características, identificación y listados de residuos peligrosos (CRETIB)','norma_tecnica',2005,null,false,'Por investigar y verificar'),
('MX','RLGPGIR','Reglamento de la Ley General para la Prevención y Gestión Integral de los Residuos','reglamento',2006,'https://mley.mx/Reg_LGPGIR/articulo/42/',false,'Art. 42 define las categorías de generador; art. 43, el registro'),
('CL','NCH-3322:2013','Colores de contenedores para identificar distintas fracciones de residuos (INN)','norma_tecnica',2013,'https://www.inn.cl/es-aprobada-norma-tecnica-nacional-nch33222013-colores-de-contenedores-para-identificar-distintas',true,'Norma chilena oficial del INN. Ficha comercial del INN la ubica en residuos sólidos municipales (diseño y operación de instalaciones de recepción y almacenamiento). Fuentes secundarias discrepan sobre si es obligatoria; no confirmado. Tabla exacta y códigos RAL: solo en el texto de pago'),
('CL','NCH-2190','Transporte de sustancias peligrosas: distintivos para identificación de riesgos','norma_tecnica',2003,'https://ispch.cl/sites/default/files/normativa_anamed/establecimientos_autorizacion_y_fiscalizacion/Decreto%20Supremo%20148.pdf',false,'Exigida por el DS 148 para rotular residuos peligrosos. Hay versiones citadas de 1993, 2003 y otra posterior; confirmar la vigente'),
('CL','DS-148-MODIF-2021','Modificación al DS 148 (documento publicado por el MMA, diciembre 2021)','reglamento',2021,'https://mma.gob.cl/wp-content/uploads/2022/02/Modificacion-D_S-N%C2%B0-148-Reglamento-Residuos-Peligrosos-Diciembre-2021.pdf',false,'Según fuentes, agrega etiqueta de al menos 600 cm2. Confirmar decreto y vigencia'),
('MX','NOM-087-SEMARNAT-SSA1-2002','Protección ambiental y salud: residuos peligrosos biológico-infecciosos (RPBI)','norma_tecnica',2002,'https://www.cndh.org.mx/doctr/2016/jur/a70/01/jur-20170331-nor14.pdf',true,'Única norma federal con código de colores de envasado encontrada. Texto leído directamente. Verificar si hay revisión posterior'),
('MX','NOM-054-SEMARNAT-1993','Determinación de la incompatibilidad entre residuos peligrosos','norma_tecnica',1993,'https://www.normasoficiales.mx/nom/nom-054-semarnat-1993',false,'Evita mezclar residuos incompatibles'),
('MX','NADF-024-AMBT-2013','Norma ambiental de la Ciudad de México para separación de residuos','norma_tecnica',2015,null,false,'Solo aplica en CDMX. Publicada en la Gaceta Oficial el 8/7/2015; cuatro categorías de separación');

-- Contenedores. PE: NTP 900.058:2019 · CL: NCh 3322:2013 (colores según guías, sin RAL) · MX: solo NOM-087 (RPBI)
insert into public.container_schemes (country_code, scope, color, label, waste_type, hazardous, instrument_id, verified, notes)
select 'PE','no_municipal', v.color, v.label, v.label, v.hz, i.id, false, null
from (values ('rojo','Peligrosos',true),('azul','Papel y cartón',false),('blanco','Plásticos',false),('amarillo','Metales',false),('marrón','Orgánicos',false),('plomo','Vidrio',false),('negro','No aprovechables',false)) v(color,label,hz)
cross join public.legal_instruments i where i.code='NTP-900.058:2019';

insert into public.container_schemes (country_code, scope, color, label, waste_type, hazardous, instrument_id, verified, notes)
select 'PE','municipal', v.color, v.label, v.label, v.hz, i.id, false, 'Confirmado en el resumen de la tabla 1 y en notas de INACAL/Andina; falta contrastar con el PDF oficial'
from (values ('verde','Aprovechables',false),('negro','No aprovechables',false),('marrón','Orgánicos',false),('rojo','Peligrosos',true)) v(color,label,hz)
cross join public.legal_instruments i where i.code='NTP-900.058:2019';

insert into public.container_schemes (country_code, scope, color, label, waste_type, hazardous, instrument_id, verified, notes)
select 'CL', s.scope, v.color, v.label, v.label, v.hz, i.id, false,
  'Tabla según guías comerciales de NCh 3322; sin RAL. Para residuos no municipales se aplica por analogía, no hay norma de colores específica confirmada'
from (values ('azul','Papel y cartón',false),('amarillo','Plásticos y envases ligeros',false),('verde','Vidrio',false),('gris claro','Metales y latas',false),('beige','Envases tipo tetra pack',false),('rojo','Residuos peligrosos',true),('burdeo','Residuos eléctricos y electrónicos',false),('café','Residuos orgánicos',false)) v(color,label,hz)
cross join (values ('no_municipal'),('municipal')) s(scope)
cross join public.legal_instruments i where i.code='NCH-3322:2013';

insert into public.container_schemes (country_code, scope, color, label, waste_type, hazardous, instrument_id, verified, notes)
select 'MX','no_municipal', v.color, v.label, v.wt, true, i.id, true, v.nt
from (values
 ('rojo','RPBI rojo','Sangre, cultivos y cepas, residuos no anatómicos y objetos punzocortantes','Bolsa de polietileno rojo traslúcido, calibre mínimo 200; punzocortantes y líquidos en recipientes rígidos o herméticos de polipropileno rojo'),
 ('amarillo','RPBI amarillo','Residuos patológicos (sólidos y líquidos)','Bolsa amarilla traslúcida, calibre mínimo 300; líquidos en recipiente hermético amarillo')) v(color,label,wt,nt)
cross join public.legal_instruments i where i.code='NOM-087-SEMARNAT-SSA1-2002';

-- Pictogramas GHS/SGA y tipos de peligrosidad
insert into public.ghs_pictograms (code,name_es,name_en,meaning_es,un_symbol) values
('GHS01','Bomba explotando','Exploding bomb','Explosivo, autorreactivo, peróxido orgánico',null),
('GHS02','Llama','Flame','Inflamable, pirofórico, autocalentable',null),
('GHS03','Llama sobre círculo','Flame over circle','Comburente u oxidante',null),
('GHS04','Bombona de gas','Gas cylinder','Gas a presión',null),
('GHS05','Corrosión','Corrosion','Corrosivo para metales y la piel, daño ocular grave',null),
('GHS06','Calavera y tibias cruzadas','Skull and crossbones','Toxicidad aguda (mortal o tóxico)',null),
('GHS07','Signo de exclamación','Exclamation mark','Irritante, toxicidad aguda leve, sensibilizante',null),
('GHS08','Peligro para la salud','Health hazard','Carcinógeno, mutágeno, tóxico para la reproducción, sensibilizante respiratorio',null),
('GHS09','Medio ambiente','Environment','Peligroso para el medio ambiente acuático',null);

insert into public.hazard_types (id,name_es,description_es,ghs_pictogram) values
('explosivo','Explosivo','Puede explotar por calor, golpe o fricción','GHS01'),
('inflamable','Inflamable','Se enciende con facilidad','GHS02'),
('comburente','Comburente','Favorece la combustión de otros materiales','GHS03'),
('gas_presion','Gas a presión','Envase con gas comprimido','GHS04'),
('corrosivo','Corrosivo','Daña la piel, los ojos o los metales','GHS05'),
('toxico','Tóxico','Dañino o mortal por contacto, ingestión o inhalación','GHS06'),
('nocivo','Nocivo / irritante','Irritante o dañino en menor grado','GHS07'),
('salud_cronica','Daño crónico a la salud','Cancerígeno, mutágeno o tóxico para la reproducción','GHS08'),
('ecotoxico','Ecotóxico','Daña la vida acuática y el ambiente','GHS09'),
('reactivo','Reactivo','Reacciona con agua o aire o es inestable',null),
('patogeno','Biológico-infeccioso','Contiene agentes patógenos',null),
('radiactivo','Radiactivo','Emite radiación',null);

-- Categorías de peligrosidad por país
insert into public.country_hazard_categories (country_code, code, name_es, hazard_type, instrument_id)
select v.cc, v.code, v.nm, v.ht, i.id
from (values
 ('PE','inflamabilidad','Inflamabilidad','inflamable','DS-014-2017-MINAM'),('PE','corrosividad','Corrosividad','corrosivo','DS-014-2017-MINAM'),
 ('PE','reactividad','Reactividad','reactivo','DS-014-2017-MINAM'),('PE','toxicidad','Toxicidad','toxico','DS-014-2017-MINAM'),
 ('PE','explosividad','Explosividad','explosivo','DS-014-2017-MINAM'),('PE','patogenicidad','Patogenicidad','patogeno','DS-014-2017-MINAM'),
 ('MX','C','Corrosivo','corrosivo','NOM-052-SEMARNAT-2005'),('MX','R','Reactivo','reactivo','NOM-052-SEMARNAT-2005'),
 ('MX','E','Explosivo','explosivo','NOM-052-SEMARNAT-2005'),('MX','T','Tóxico ambiental','toxico','NOM-052-SEMARNAT-2005'),
 ('MX','I','Inflamable','inflamable','NOM-052-SEMARNAT-2005'),('MX','B','Biológico-infeccioso','patogeno','NOM-052-SEMARNAT-2005'),
 ('CL','toxicidad','Toxicidad','toxico','DS-148-2003-MINSAL'),('CL','inflamabilidad','Inflamabilidad','inflamable','DS-148-2003-MINSAL'),
 ('CL','reactividad','Reactividad','reactivo','DS-148-2003-MINSAL'),('CL','corrosividad','Corrosividad','corrosivo','DS-148-2003-MINSAL')
) v(cc,code,nm,ht,ic)
join public.legal_instruments i on i.country_code=v.cc and i.code=v.ic;

insert into public.country_hazard_categories (country_code, code, name_es, hazard_type, instrument_id, verified)
select 'MX', v.code, v.nm, v.ht, i.id, true
from (values ('Te','Toxicidad ambiental','ecotoxico'),('Th','Toxicidad aguda','toxico'),('Tt','Toxicidad crónica','salud_cronica')) v(code,nm,ht)
join public.legal_instruments i on i.code = 'NOM-052-SEMARNAT-2005';

insert into public.country_hazard_categories (country_code, code, name_es, hazard_type, instrument_id, verified)
select 'CL', v.code, v.nm, v.ht, i.id, true
from (values ('toxicidad_aguda','Toxicidad aguda','toxico'),('toxicidad_cronica','Toxicidad crónica','salud_cronica'),('toxicidad_extrinseca','Toxicidad extrínseca (por lixiviación)','toxico')) v(code,nm,ht)
join public.legal_instruments i on i.code = 'DS-148-2003-MINSAL';

-- Clasificación federal, categorías de generador y permisos (México)
insert into public.federal_waste_classes (country_code, code, name_es, hazardous, instrument_id, notes)
select 'MX', v.code, v.nm, v.hz, i.id, v.nt
from (values
 ('RP','Residuos peligrosos',true,'Se identifican con la NOM-052-SEMARNAT-2005 (CRETIB y listados)'),
 ('RME','Residuos de manejo especial',false,'Categoría de la LGPGIR; confirmar artículos'),
 ('RSU','Residuos sólidos urbanos',false,'Categoría de la LGPGIR; competencia municipal')) v(code,nm,hz,nt)
join public.legal_instruments i on i.code='LGPGIR';

insert into public.generator_categories (country_code, code, name_es, min_kg_year, max_kg_year, registration_authority, obligations, instrument_id, verified)
select 'MX', v.code, v.nm, v.mn, v.mx, v.ra, v.ob, i.id, true
from (values
 ('micro','Microgenerador',0::numeric,400::numeric,'Autoridades estatales o municipales',array['entregar a centros o transportistas autorizados']),
 ('pequeno','Pequeño generador',400::numeric,10000::numeric,'SEMARNAT',array['registro como generador','bitácora anual','planes de manejo cuando corresponda']),
 ('gran','Gran generador',10000::numeric,null::numeric,'SEMARNAT',array['registro como generador','plan de manejo de residuos peligrosos','bitácora','Cédula de Operación Anual','seguro ambiental'])) v(code,nm,mn,mx,ra,ob)
join public.legal_instruments i on i.code='RLGPGIR';

insert into public.permit_types (country_code, code, name_es, authority, procedure_code, instrument_id, notes)
select 'MX', v.code, v.nm, v.au, v.pc, i.id, v.nt
from (values
 ('MX-REGISTRO-GENERADOR','Registro como generador de residuos peligrosos','SEMARNAT','SEMARNAT-07-017','Previo al inicio de operaciones; la constancia incluye el número de registro'),
 ('MX-MODIF-REGISTRO','Modificación de datos o categoría del registro de generador','SEMARNAT','SEMARNAT-07-031',null),
 ('MX-PLAN-MANEJO','Plan de manejo de residuos peligrosos','SEMARNAT',null,'Obligatorio para gran generador')) v(code,nm,au,pc,nt)
join public.legal_instruments i on i.code='RLGPGIR';

-- Reglas de manejo (color, etiquetado, almacenamiento, segregación)
insert into public.handling_rules (country_code, topic, applies_to, rule_es, instrument_id, source_url, verified, notes)
select r.cc, r.topic, r.ap, r.rule, i.id, r.url, r.ver, r.nt
from (values
 ('CL','color','residuos peligrosos','El rojo identifica los residuos peligrosos en el código de colores NCh 3322','NCH-3322:2013',null,false,'Según guías comerciales'),
 ('CL','etiquetado','residuos peligrosos','Los residuos peligrosos se identifican y etiquetan según la clasificación y tipo de riesgo de la NCh 2190, desde el almacenamiento hasta su valorización o eliminación','DS-148-2003-MINSAL','https://ispch.cl/sites/default/files/normativa_anamed/establecimientos_autorizacion_y_fiscalizacion/Decreto%20Supremo%20148.pdf',false,'Citado en resultados de búsqueda; leer el decreto'),
 ('CL','etiquetado','residuos peligrosos','Etiqueta visible de al menos 600 cm2 con el nombre del residuo, su código, su pictograma y el generador, en español y letra legible','DS-148-MODIF-2021','https://mma.gob.cl/wp-content/uploads/2022/02/Modificacion-D_S-N%C2%B0-148-Reglamento-Residuos-Peligrosos-Diciembre-2021.pdf',false,'Confirmar vigencia de la modificación'),
 ('CL','almacenamiento','residuos peligrosos','El almacenamiento no puede exceder 6 meses; el sitio tiene acceso restringido, señalización NCh 2190 y capacidad de retención de derrames no inferior al contenedor mayor ni al 20 % del volumen total','DS-148-2003-MINSAL','https://ispch.cl/sites/default/files/normativa_anamed/establecimientos_autorizacion_y_fiscalizacion/Decreto%20Supremo%20148.pdf',false,'Citado en resultados de búsqueda; leer el decreto'),
 ('MX','envasado','RPBI','Bolsas de polietileno rojo traslúcido (calibre mínimo 200) para cultivos y no anatómicos, y amarillo traslúcido (calibre mínimo 300) para patológicos; punzocortantes en recipientes rígidos de polipropileno rojo con tapa hermética','NOM-087-SEMARNAT-SSA1-2002','https://www.cndh.org.mx/doctr/2016/jur/a70/01/jur-20170331-nor14.pdf',true,'Leído del texto de la norma de 2002'),
 ('MX','segregacion','residuos peligrosos','No se mezclan residuos peligrosos incompatibles; los contenedores deben permitir segregarlos','NOM-054-SEMARNAT-1993',null,false,'Resumen de fuentes secundarias'),
 ('MX','etiquetado','residuos peligrosos','Todo contenedor lleva etiqueta con el nombre del residuo, la clave de la NOM-052-SEMARNAT-2005 y la fecha de generación','NOM-052-SEMARNAT-2005',null,false,'Fuente comercial; confirmar en el Reglamento de la LGPGIR'),
 ('MX','almacenamiento','gran generador','Almacenamiento temporal máximo de 6 meses, con señalización, contención secundaria, ventilación y acceso controlado','RLGPGIR',null,false,'Cifra de un sitio comercial; no verificada en el Reglamento'),
 ('MX','color','residuos municipales (CDMX)','En la CDMX se separa en cuatro categorías: orgánicos (contenedor verde), inorgánicos reciclables, inorgánicos no reciclables y manejo especial o voluminosos. Solo se confirmó el verde','NADF-024-AMBT-2013',null,false,'Local de la CDMX, no federal'),
 ('MX','color','residuos industriales','No se encontró norma federal de colores para residuos industriales no biológico-infecciosos. El tacho rojo no está respaldado por una norma mexicana','LGPGIR',null,true,'Resultado de búsqueda; Jazmín debe confirmar con un asesor mexicano'),
 ('PE','color','ámbito municipal','Municipal: verde para aprovechables (papel, cartón, vidrio, plástico, textiles, madera, cuero, envases compuestos y metales), negro para no aprovechables, marrón para orgánicos y rojo para peligrosos. Los residuos municipales también pueden usar los colores de la tabla 2','NTP-900.058:2019','https://andina.pe/ingles/noticia-inacal-promueve-uso-codigo-colores-para-segregacion-responsable-residuos-solidos-840364.aspx',false,'Una nota de prensa aplica estos cuatro colores a ambos ámbitos; otras fuentes separan siete colores para el no municipal')
) r(cc,topic,ap,rule,ic,url,ver,nt)
join public.legal_instruments i on i.country_code=r.cc and i.code=r.ic;

-- Casos de prueba mínimos (README, sección 7)
insert into public.test_cases (country_code, description, expected_classification, expected_color, expected_basel) values
('PE','Trapo con aceite de motor','PELIGROSO','rojo','{A3020,A4060}'),
('PE','Envase vacío de solvente','PELIGROSO','rojo','{A4130}'),
('PE','Caja de cartón limpia','NO_PELIGROSO','azul','{B3020}'),
('PE','Lata con restos de pintura','PELIGROSO','rojo','{A4070,A4130}'),
('PE','Retazo de madera limpia','NO_PELIGROSO',null,'{B3050}'),
('PE','Fluorescente roto','PELIGROSO','rojo','{A1030}'),
('PE','Foto borrosa u oscura: no clasifica','NO_SEGURO',null,null),
('PE','Usuario responde No sé 3 veces: regla precautoria','PELIGROSO','rojo',null);
