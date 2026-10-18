import json, re
from data_static import *
# correcciones de texto oficial
A3210_ES_OFF = "Desechos plásticos, incluidas mezclas de esos desechos, que contengan constituyentes del anexo I, o estén contaminados con ellos, en tal grado que presenten una de las características del anexo III (véanse las entradas conexas Y48 en el anexo II y en la lista B B3011)"
NOTES[6] = ("IX",1,"Desechos que no estarán sujetos a lo dispuesto en el apartado a) del párrafo 1 del Artículo 1 del Convenio de Basilea, a menos que contengan materiales incluidos en el anexo I en una cantidad tal que les confiera una de las características del anexo III.", NOTES[6][3])
NOTES[7] = ("IX",2,"Aunque inicialmente exista una contaminación de bajo nivel con materiales del anexo I, los procesos subsiguientes, incluidos los de reciclado, pueden dar como resultado fracciones separadas que contengan una concentración considerablemente mayor de esos materiales del anexo I (nota de la entrada B1050).", NOTES[7][3])
en = json.load(open('en.json')); es = json.load(open('es.json'))
E = {e['code']:e for e in en['entries']}; S = {e['code']:e for e in es['entries']}
def fix(d):
    d = re.sub(r'(Thallium|Talio)\.\s+(but|pero)', r'\1, \2', d)
    d = re.sub(r'\bPCB- ', 'PCB ', d)
    return d.replace(' ;', ';').replace(' :', ':')
def q(s): 
    if s is None: return 'null'
    return "'" + s.replace("'", "''") + "'"
def arr(a): return 'null' if not a else "array[" + ",".join("'%s'" % x for x in a) + "]::text[]"
S['A1190']['desc'] = A1190_ES
S['B3026']['desc'] = S['B3026']['desc'].replace('características del anexo II:', 'características del anexo III:')
status = {'A1180':('derogado',None,'2024-12-31','Vigente hasta el 31/12/2024; reemplazada por A1181 (decisión BC-15/18)'),
          'B1110':('derogado',None,'2024-12-31','Eliminada del Anexo IX el 1/1/2025 (decisión BC-15/18); ver A1181 y Y49'),
          'B4030':('derogado',None,'2024-12-31','Eliminada del Anexo IX el 1/1/2025 (decisión BC-15/18)'),
          'B3010':('derogado',None,'2020-12-31','Vigente hasta el 31/12/2020; reemplazada por B3011 (decisión BC-14/12)')}
rows = []
def row(code, lst, annex, gc, gn_es, gn_en, d_es, d_en, hz, st='vigente', ef=None, et=None, rel=None, src='Convenio de Basilea, texto oficial (Secretaría)', note=None, ver=True):
    rows.append((code,lst,annex,gc,gn_es,gn_en,d_es,d_en,hz,st,ef,et,rel,src,note,ver))
for n in range(1,48):
    c = f'Y{n}'
    if n<=18: g=('Y-A','Corrientes de desechos','Waste streams'); an='I'
    elif n<=45: g=('Y-B','Desechos que tengan como constituyentes','Wastes having as constituents'); an='I'
    else: g=('Y-II','Categorías de desechos que requieren una consideración especial','Categories of wastes requiring special consideration'); an='II'
    row(c,'Y',an,g[0],g[1],g[2],Y_ES[n],Y_EN[n], an=='I')
row('Y48','Y','II','Y-II','Categorías de desechos que requieren una consideración especial','Categories of wastes requiring special consideration',Y48_ES,Y48_EN,False,ef='2021-01-01',rel=['A3210','B3011'],src='Decisión BC-14/12 (texto aplanado)',note='Las Partes pueden imponer requisitos más estrictos')
row('Y49','Y','II','Y-II','Categorías de desechos que requieren una consideración especial','Categories of wastes requiring special consideration',Y49_ES,Y49_EN,False,ef='2025-01-01',rel=['A1181'],src='Decisión BC-15/18 (texto aplanado)',note='Las Partes pueden imponer requisitos más estrictos')
def relcodes(code, txt):
    return sorted(set(re.findall(r'\b([AB]\d{4}|Y\d{2})\b', txt)) - {code}) or None
for code in sorted(E):
    lst = code[0]; annex = 'VIII' if lst=='A' else 'IX'
    gcode = E[code]['group']; ge = en['groups'][gcode]; gs = es['groups'][gcode]
    d_en = fix(E[code]['desc']); d_es = fix(S[code]['desc'])
    st, ef, et, nt = status.get(code, ('vigente',None,None,None))
    rel = relcodes(code, d_en)
    src = 'Convenio de Basilea, texto oficial (Secretaría)'
    ver = True
    if code=='A1190': src += '; texto en español completado por traducción del inglés (el original está truncado)'; ver=False
    if code=='B3026': src += '; se corrigió "anexo II" por "anexo III" en el texto en español'
    row(code,lst,annex,gcode,gs.title() if False else gs,ge,d_es,d_en,lst=='A',st,ef,et,rel,src,nt,ver)
# nuevos
row('A1181','A','VIII','A1','DESECHOS METÁLICOS O QUE CONTENGAN METALES',en['groups']['A1'],A1181_ES,A1181_EN,True,ef='2025-01-01',rel=['Y49'],src='Decisión BC-15/18 (texto aplanado)',note='Reemplaza a A1180')
row('A3210','A','VIII','A3','DESECHOS QUE CONTENGAN PRINCIPALMENTE CONSTITUYENTES ORGÁNICOS, QUE PUEDAN CONTENER METALES Y MATERIA INORGÁNICA',en['groups']['A3'],A3210_ES_OFF,A3210_EN,True,ef='2021-01-01',rel=['B3011','Y48'],src='Decisión BC-14/12')
row('B3011','B','IX','B3','DESECHOS QUE CONTENGAN PRINCIPALMENTE CONSTITUYENTES ORGÁNICOS, QUE PUEDEN CONTENER METALES Y MATERIALES INORGÁNICOS',en['groups']['B3'],B3011_ES,B3011_EN,False,ef='2021-01-01',rel=['A3210','Y48'],src='Decisión BC-14/12 (texto aplanado)',note='Reemplaza a B3010')
out = []
def cols(r):
    return "(" + ",".join([q(r[0]),q(r[1]),q(r[2]),q(r[3]),q(r[4]),q(r[5]),q(r[6]),q(r[7]),'true' if r[8] else 'false',q(r[9]),q(r[10]),q(r[11]),arr(r[12]),q(r[13]),q(r[14]),'true' if r[15] else 'false']) + ")"
def esc(c):  # fechas
    return c.replace("$q$"+"2020-12-31"+"$q$","'2020-12-31'::date")
HEAD = "insert into public.basel_codes (code,list,annex,group_code,group_name_es,group_name_en,description_es,description_en,hazardous,status,effective_from,effective_to,related_codes,source,note_es,verified) values\n"
TAIL = "\non conflict (code) do update set list=excluded.list,annex=excluded.annex,group_code=excluded.group_code,group_name_es=excluded.group_name_es,group_name_en=excluded.group_name_en,description_es=excluded.description_es,description_en=excluded.description_en,hazardous=excluded.hazardous,status=excluded.status,effective_from=excluded.effective_from::date,effective_to=excluded.effective_to::date,related_codes=excluded.related_codes,source=excluded.source,note_es=excluded.note_es,verified=excluded.verified;\n"
def sqlrows(rs):
    vals = []
    for r in rs:
        v = cols(r).replace("$q$None$q$","null")
        vals.append(v)
    return vals
chunks = {'Y':[r for r in rows if r[1]=='Y'], 'A':[r for r in rows if r[1]=='A'], 'B':[r for r in rows if r[1]=='B']}
for k,rs in chunks.items():
    vals = sqlrows(rs)
    open(f'sql_{k}.sql','w').write(HEAD + ",\n".join(vals) + TAIL)
    print(k, len(rs), sum(len(v) for v in vals))
# H, D, notas
hv = ",\n".join("(%s,%s,%s,%s,%s,%s,%s,%s)" % (q(h[0]),q(h[1]),q(h[2]),q(h[3]),q(h[4]),q(h[5]),q(h[6]),q(h[7])) for h in [(a,b,c,d,e,f,g,h_) for (a,b,c,d,e,f,h_) in [(x[0],x[1],x[2],x[3],x[4],x[5],x[6]) for x in H] for g in [None]][:0]) if False else None
hv = ",\n".join("(%s,%s,%s,%s,%s,%s,%s)" % (q(x[0]),q(x[1]),q(x[2]),q(x[3]),q(x[4]),q(x[5]),q(x[6])) for x in H)
dv = ",\n".join("(%s,%s,%s,%s)" % (q(x[0]),q(x[1]),q(x[2]),q(x[3])) for x in D)
nv = ",\n".join("(%s,%s,%s,%s)" % (q(x[0]),x[1],q(x[2]),q(x[3])) for x in NOTES)
open('sql_HDN.sql','w').write(
 "insert into public.basel_hazard_characteristics (h_code,un_class,name_es,name_en,description_es,description_en,hazard_type) values\n"+hv+"\non conflict (h_code) do nothing;\n"
 "insert into public.basel_disposal_operations (code,section,description_es,description_en) values\n"+dv+"\non conflict (code) do nothing;\n"
 "insert into public.basel_annex_notes (annex,ord,text_es,text_en) values\n"+nv+"\non conflict (annex,ord) do nothing;\n")

# ---- versión compacta ----
STD = 'Convenio de Basilea, texto oficial (Secretaría)'
def cols2(r):
    src = None if r[13]==STD else r[13]
    return "(" + ",".join([q(r[0]),q(r[1]),q(r[2]),q(r[3]),q(r[6]),q(r[7]),'true' if r[8] else 'false',q(r[9]),q(r[10]),q(r[11]),arr(r[12]),q(src),q(r[14]),'true' if r[15] else 'false']) + ")"
HEAD2 = "insert into public.basel_codes (code,list,annex,group_code,description_es,description_en,hazardous,status,effective_from,effective_to,related_codes,source,note_es,verified) values\n"
TAIL2 = "\non conflict (code) do update set list=excluded.list,annex=excluded.annex,group_code=excluded.group_code,description_es=excluded.description_es,description_en=excluded.description_en,hazardous=excluded.hazardous,status=excluded.status,effective_from=excluded.effective_from,effective_to=excluded.effective_to,related_codes=excluded.related_codes,source=coalesce(excluded.source,'Convenio de Basilea, texto oficial (Secretaría)'),note_es=excluded.note_es,verified=excluded.verified;\n"
for k,rs in chunks.items():
    if k=='B':
        half = len(rs)//2
        parts = {'B1':rs[:half],'B2':rs[half:]}
    elif k=='A':
        half = len(rs)//2
        parts = {'A1':rs[:half],'A2':rs[half:]}
    else: parts = {k:rs}
    for n,pr in parts.items():
        v = ",\n".join(cols2(r) for r in pr)
        open(f'c_{n}.sql','w').write(HEAD2 + v + TAIL2)
        print(n, len(pr), len(HEAD2+v+TAIL2))
groups = [('Y-A','I','Corrientes de desechos','Waste streams'),('Y-B','I','Desechos que tengan como constituyentes','Wastes having as constituents'),
  ('Y-II','II','Categorías de desechos que requieren una consideración especial','Categories of wastes requiring special consideration')]
for g in ('A1','A2','A3','A4'): groups.append((g,'VIII',S_g:=es['groups'][g],en['groups'][g]))
for g in ('B1','B2','B3','B4'): groups.append((g,'IX',es['groups'][g],en['groups'][g]))
open('c_G.sql','w').write("insert into public.basel_groups (code,annex,name_es,name_en) values\n" + ",\n".join("(%s,%s,%s,%s)"%(q(a),q(b),q(c),q(d)) for a,b,c,d in groups) + "\non conflict (code) do nothing;\n")
print(open('c_G.sql').read()[:900])
