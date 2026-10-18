-- Cambios sobre filas ya existentes que se intentaron aplicar y quedaron cancelados. Ejecutar a mano si se aprueban.

update public.legal_instruments set verified = true,
  source_url = 'https://www.gob.mx/cms/uploads/attachment/file/680163/NOM-052-SEMARNAT-2005.pdf',
  notes = 'Vigente según el Catálogo Mexicano de Normas. Publicada en el DOF el 23/6/2006; en vigor desde el 21/9/2006. Texto leído: Tabla 1 (CPR: C, R, E, T con Te/Th/Tt, I, B) y Listados 1 a 5'
  where code = 'NOM-052-SEMARNAT-2005';

update public.legal_instruments set verified = true,
  notes = 'Texto oficial leído (ed. consolidada con la modificación 2021). Lista I/II/III: art. 18 en el decreto original y art. 20 en el texto de 2021; Lista A/B: art. 90 original y art. 104 en 2021'
  where code = 'DS-148-2003-MINSAL';

update public.legal_instruments set verified = true,
  notes = 'Publicado el 21/12/2017. Anexo III = Lista A (Basilea), Anexo IV = características de peligrosidad H1-H13, Anexo V = Lista B. Modificado por D.S. 001-2022-MINAM: confirmar la versión vigente de los anexos'
  where code = 'DS-014-2017-MINAM';

update public.country_hazard_categories set verified = true where country_code = 'CL';

update public.container_schemes
  set notes = 'Coincide en 3 fuentes secundarias (resumen de la tabla 2 y un procedimiento minero que cita la norma); falta contrastar con el PDF oficial'
  where country_code = 'PE' and scope = 'no_municipal';
