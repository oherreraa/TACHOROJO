import json,re
rows=json.load(open('nom_rows.json'))
KEY=re.compile(r'^(E\d+/\d+|NE ?\d+|H\d+|T\d+|RP ?\d+/\d+)$')
def q(s): return 'null' if s is None else "'" + s.replace("'", "''") + "'"
def arr(a): return "array[" + ",".join(q(x) for x in a) + "]::text[]" if a else "'{}'::text[]"
def cpr(s): return [x.strip() for x in s.strip('() ').split(',') if x.strip()]
main5={'1':'Baterías, celdas y pilas','2':'Catalizadores gastados','3':'Escorias','4':'Lodos','5':'Lodos de tratamiento de aguas residuales','6':'Polvos','7':'Otros residuos','8':'Soluciones gastadas'}
MAINH={'BATERIAS, CELDAS Y PILAS','CATALIZADORES GASTADOS','ESCORIAS','LODOS','LODOS DE TRATAMIENTO DE AGUAS RESIDUALES','POLVOS','OTROS RESIDUOS','SOLUCIONES GASTADAS'}
out={'L1':[], 'L3':[], 'L4':[], 'L5':[]}
giro=None; sub=None
for pg,r in rows:
    if len(r)>=3 and r[-1] and KEY.match(r[-1]):
        key=r[-1]; c=cpr(r[-2]); dsc=' '.join(x for x in r[:-2] if x)
        if key.startswith('E'):
            out['L1'].append((key, None, dsc, c, giro, None, None))
        elif key.startswith('H'):
            cas=r[0].replace('–','-'); cas=re.sub(r'^\(\d\)\s*','',cas)
            out['L3'].append((key, cas, r[1], c, 'Tóxicos agudos', None, 'A4140'))
        elif key.startswith('T'):
            cas=r[0].replace('–','-'); cas=re.sub(r'^\(\d\)\s*','',cas)
            out['L4'].append((key, cas, r[1], c, 'Tóxicos crónicos', None, 'A4140'))
        elif key.startswith('RP'):
            n=key.split()[1].split('/')[0]
            bc={'1':'A1170','2':'A2030'}.get(n)
            out['L5'].append((key, None, dsc, c, main5[n], sub, bc))
    elif len(r)==3 and r[1]=='' and r[2]=='' and r[0].startswith('GIRO'):
        giro=r[0].split(':',1)[1].strip().capitalize() if ':' in r[0] else r[0]
        giro='Giro '+r[0].split(':')[0].split()[1]+': '+giro
    elif pg>=22 and len(r)==3 and r[1]=='' and r[2]=='' and r[0] and r[0] not in ('Residuo',):
        if r[0] not in MAINH: sub=r[0].capitalize()
        else: sub=None
for k,v in out.items(): print(k,len(v))
LN={'L1':('LISTADO-1','Listado 1 · Residuos peligrosos por fuente específica'),'L3':('LISTADO-3','Listado 3 · Productos químicos fuera de especificaciones o caducos (tóxicos agudos)'),'L4':('LISTADO-4','Listado 4 · Productos químicos fuera de especificaciones o caducos (tóxicos crónicos)'),'L5':('LISTADO-5','Listado 5 · Residuos sujetos a condiciones particulares de manejo')}
HEAD="insert into public.country_waste_listings (country_code, instrument_id, listing_code, listing_name, entry_key, cas, description, hazard_codes, group_label, subgroup_label, basel_code, verified, notes)\nselect 'MX', i.id, v.lc, v.ln, v.k, v.cas, v.d, v.h, v.g, v.s, v.bc, true, v.n\nfrom (values\n"
TAIL="\n) v(lc,ln,k,cas,d,h,g,s,bc,n)\njoin public.legal_instruments i on i.code = 'NOM-052-SEMARNAT-2005'\non conflict (instrument_id, listing_code, entry_key) do nothing;\n"
def vals(k, chunk):
    lc,ln=LN[k]; res=[]
    for key,cas,d,c,g,s,bc in chunk:
        note = "Equivalencia con Basilea inferida" if bc else None
        res.append("(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"%(q(lc),q(ln),q(key),q(cas),q(d.strip()),arr(c),q(g),q(s),q(bc),q(note)))
    return ",\n".join(res)
# partes
def write(name, k, chunk): open(name,'w').write(HEAD+vals(k,chunk)+TAIL); print(name,len(chunk),len(open(name).read()))
write('mx_L1.sql','L1',out['L1'])
write('mx_L3.sql','L3',out['L3'])
write('mx_L4a.sql','L4',out['L4'][:125]); write('mx_L4b.sql','L4',out['L4'][125:])
write('mx_L5.sql','L5',out['L5'])

# ---- compacto ----
def hs(c): return q(','.join(c))
def wr(name, lc, ln, rows, const_g=None, const_bc=None, per_row=False):
    if per_row:
        head=("insert into public.country_waste_listings (country_code, instrument_id, listing_code, listing_name, entry_key, cas, description, hazard_codes, group_label, subgroup_label, basel_code, verified, notes)\n"
              "select 'MX', i.id, %s, %s, v.k, v.cas, v.d, string_to_array(v.h, ','), v.g, v.s, v.bc, true, case when v.bc is not null then 'Equivalencia con Basilea inferida' end\nfrom (values\n")%(q(lc),q(ln))
        body=",\n".join("(%s,%s,%s,%s,%s,%s,%s)"%(q(k),q(cas),q(d.strip()),hs(c),q(g),q(s),q(bc)) for k,cas,d,c,g,s,bc in rows)
        tail="\n) v(k,cas,d,h,g,s,bc)\njoin public.legal_instruments i on i.code = 'NOM-052-SEMARNAT-2005'\non conflict (instrument_id, listing_code, entry_key) do nothing;\n"
    else:
        head=("insert into public.country_waste_listings (country_code, instrument_id, listing_code, listing_name, entry_key, cas, description, hazard_codes, group_label, basel_code, verified, notes)\n"
              "select 'MX', i.id, %s, %s, v.k, v.cas, v.d, string_to_array(v.h, ','), %s, %s, true, 'Equivalencia con Basilea inferida'\nfrom (values\n")%(q(lc),q(ln),q(const_g),q(const_bc))
        body=",\n".join("(%s,%s,%s,%s)"%(q(k),q(cas),q(d.strip()),hs(c)) for k,cas,d,c,g,s,bc in rows)
        tail="\n) v(k,cas,d,h)\njoin public.legal_instruments i on i.code = 'NOM-052-SEMARNAT-2005'\non conflict (instrument_id, listing_code, entry_key) do nothing;\n"
    open(name,'w').write(head+body+tail); print(name,len(rows),len(head+body+tail))
wr('m1.sql','LISTADO-1',LN['L1'][1],out['L1'],per_row=True)
wr('m3.sql','LISTADO-3',LN['L3'][1],out['L3'],'Tóxicos agudos','A4140')
wr('m4a.sql','LISTADO-4',LN['L4'][1],out['L4'][:125],'Tóxicos crónicos','A4140')
wr('m4b.sql','LISTADO-4',LN['L4'][1],out['L4'][125:],'Tóxicos crónicos','A4140')
wr('m5.sql','LISTADO-5',LN['L5'][1],out['L5'],per_row=True)
