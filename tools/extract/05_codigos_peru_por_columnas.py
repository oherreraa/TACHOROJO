import pdfplumber, logging, re, json
logging.disable(logging.CRITICAL)
p=pdfplumber.open('/tmp/norms/pe014.pdf')
pages=[]
for i,pg in enumerate(p.pages):
    t=pg.extract_text() or ''
    if re.search(r'A ?(1010|2010|3010|4010)\s+Residuos',t) or 'ANEXO V' in t or re.search(r'B ?\d{4}\.?\s+Residuos',t): pages.append(i)
print(pages)
A=set();B=set(); txt=[]
for i in range(min(pages), max(pages)+1):
    pg=p.pages[i]; w=pg.width
    for box in ((0,0,w/2,pg.height),(w/2,0,w,pg.height)):
        t=pg.crop(box).extract_text() or ''
        txt.append(f'#### page {i}\n'+t)
open('pe_cols.txt','w').write('\n'.join(txt))
