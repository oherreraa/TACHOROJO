import pdfplumber, logging, json, re
logging.disable(logging.CRITICAL)
p = pdfplumber.open('/tmp/norms/nom052.pdf')
rows=[]
for i in range(8, len(p.pages)):
    pg=p.pages[i]
    txt=pg.extract_text() or ''
    for t in pg.extract_tables():
        for r in t:
            rows.append((i,[ (c or '').replace('\n',' ').strip() for c in r]))
json.dump(rows, open('nom_rows.json','w'), ensure_ascii=False)
from collections import Counter
print(len(rows), Counter(len(r) for _,r in rows))
import itertools
for i,r in rows[:6]: print(i,r)
for i,r in rows[300:306]: print(i,r)
for i,r in rows[-8:]: print(i,r)
# distinct clave prefixes
c=Counter(re.sub(r'[\d/ ]+','#',r[-1]) for _,r in rows)
print(c.most_common(20))
