import re, json
BULCH = '•▪o-–'
ENTRY = re.compile(r'^(\s*)([AB]\d{4})(?:\s+|$)(.*)$')
GROUP = re.compile(r'^\s*([AB]\d)\s+(\S.*)$')
PAGE = re.compile(r'^\s*(=====PAGE \d+=====|\|?\s*\d+\s*\|?)\s*$')

def isbul(s): return len(s) > 1 and s[0] in BULCH and s[1] == ' '

def join(parts):
    out = ''
    for p in parts:
        p = p.strip()
        if not p: continue
        if out.endswith('-') and p[:1].islower() and not out.endswith(' -'): out = out[:-1] + p
        else: out = (out + ' ' + p) if out else p
    return out

def parse(fn):
    lines = open(fn, encoding='utf-8').read().split('\n')
    s = next(i for i,l in enumerate(lines) if re.search(r'(ANNEX|ANEXO)\s+VIII', l))
    lines = lines[s:]
    entries, order, groups = {}, [], {}
    cur = curg = None; dcol = None; stop = False
    for raw in lines:
        l = raw.rstrip()
        if not l.strip() or PAGE.match(l): continue
        if stop: break
        m = ENTRY.match(l)
        if m and not l.strip().upper().startswith('LIST'):
            c0, code, rest = len(m.group(1)), m.group(2), m.group(3)
            dcol = c0 + 6
            if code not in entries:
                entries[code] = {'group':curg, 'pre':[], 'items':[], 'post':[]}; order.append(code)
            cur = code
            if rest.strip():
                entries[code]['pre' if not entries[code]['items'] else 'post'].append(rest) if not isbul(rest.strip()) else entries[code]['items'].append(rest.strip()[2:])
            continue
        s2 = l.strip(); ind = len(l) - len(l.lstrip())
        g = GROUP.match(l)
        if g and re.match(r'^[AB]\d\s+[A-ZÁÉÍÓÚÑ(]', s2) and not re.match(r'^[AB]\d{4}', s2) and sum(ch.islower() for ch in s2) < 3:
            curg = g.group(1); groups[curg] = g.group(2).strip(); cur = None; continue
        if cur is None:
            if curg and s2.upper() == s2 and len(s2) > 8 and not s2.startswith(('LIST','LISTA')): groups[curg] += ' ' + s2
            continue
        e = entries[cur]
        if cur == 'B4030' and (s2.upper() == s2 or 'PROTOCOL' in s2): stop = True; continue
        if isbul(s2):
            e['items'].append(s2[2:].strip())
        elif e['items'] and ind > dcol + 1:
            e['items'][-1] += ' ' + s2
        elif e['items']:
            e['post'].append(s2)
        else:
            e['pre'].append(s2)
    out = []
    for c in order:
        e = entries[c]
        pre, post = join(e['pre']), join(e['post'])
        items = [re.sub(r'\s+', ' ', i) for i in e['items']]
        d = pre
        if items: d = (d + ' ' if d else '') + '; '.join(items)
        if post: d = (d + ('. ' if d and d[-1] not in '.;:' else ' ') + post)
        d = re.sub(r'\s+', ' ', d).replace(' ,', ',').replace(' .', '.').strip()
        out.append({'code':c, 'group':e['group'], 'desc':d})
    return out, groups

for lang in ('en','es'):
    o, g = parse(f'{lang}L.txt')
    json.dump({'entries':o,'groups':g}, open(f'{lang}.json','w'), ensure_ascii=False, indent=1)
    print(lang, len(o), sum(1 for x in o if x['code'][0]=='A'), sum(1 for x in o if x['code'][0]=='B'))
