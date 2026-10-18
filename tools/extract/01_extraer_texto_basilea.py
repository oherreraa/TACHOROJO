import sys, pdfplumber, logging
logging.disable(logging.CRITICAL)
src, out, a, b = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
p = pdfplumber.open(src)
res=[]
for i in range(a, min(b, len(p.pages))):
    pg = p.pages[i].filter(lambda o: o.get('object_type')!='char' or o.get('size',10) > 9)
    res.append(f'=====PAGE {i}=====\n' + (pg.extract_text(layout=True) or ''))
open(out,'w').write('\n'.join(res))
