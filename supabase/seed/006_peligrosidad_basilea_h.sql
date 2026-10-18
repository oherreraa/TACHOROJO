-- Peligrosidad nacional <-> características H de Basilea (requiere 001 y 002)
insert into public.country_hazard_basel_h (country_hazard_category_id, h_code, confidence, basis, notes)
select c.id, v.h, v.conf, 'inferencia', v.nt
from (values
 ('MX','C','H8','alta',null),('MX','R','H4.3','media',null),('MX','R','H5.1','media',null),('MX','R','H5.2','media',null),('MX','R','H10','media',null),
 ('MX','E','H1','alta',null),('MX','T','H6.1','media',null),('MX','T','H11','media',null),('MX','T','H12','media',null),
 ('MX','Te','H12','media',null),('MX','Th','H6.1','alta',null),('MX','Tt','H11','media',null),
 ('MX','I','H3','alta',null),('MX','I','H4.1','alta',null),('MX','B','H6.2','alta',null),
 ('PE','explosividad','H1','alta',null),('PE','inflamabilidad','H3','alta',null),('PE','inflamabilidad','H4.1','alta',null),('PE','inflamabilidad','H4.2','media',null),
 ('PE','corrosividad','H8','alta',null),('PE','reactividad','H4.3','media',null),('PE','reactividad','H5.1','media',null),('PE','reactividad','H5.2','media',null),('PE','reactividad','H10','media',null),
 ('PE','toxicidad','H6.1','alta',null),('PE','toxicidad','H11','media',null),('PE','toxicidad','H12','media',null),('PE','patogenicidad','H6.2','alta',null),
 ('CL','toxicidad_aguda','H6.1','alta','DS 148 art. 12'),('CL','toxicidad_cronica','H11','media','DS 148 art. 13'),
 ('CL','toxicidad_extrinseca','H13','alta','DS 148 art. 14: test de toxicidad por lixiviación'),('CL','toxicidad_extrinseca','H11','media','DS 148 art. 14: test de toxicidad por lixiviación'),
 ('CL','toxicidad','H6.1','media','Categoría general; el decreto la divide en aguda, crónica y extrínseca'),
 ('CL','inflamabilidad','H3','alta',null),('CL','inflamabilidad','H4.1','alta',null),('CL','inflamabilidad','H5.1','media',null),
 ('CL','reactividad','H1','media',null),('CL','reactividad','H4.3','alta',null),('CL','reactividad','H10','alta',null),('CL','corrosividad','H8','alta',null)
) v(cc,code,h,conf,nt)
join public.country_hazard_categories c on c.country_code = v.cc and c.code = v.code;

