# Scripts de extracción

Reproducen los datos normativos a partir de los PDF oficiales. Se escribieron para trabajar en una carpeta temporal;
las rutas (`/tmp/basel`, `/tmp/norms`) están dentro de cada script y hay que ajustarlas. Requieren `pdfplumber` y `pdftotext` (poppler).

| Script | Qué hace |
|---|---|
| `01_extraer_texto_basilea.py` | Saca el texto de los Anexos del Convenio de Basilea (ES/EN), quitando superíndices y notas al pie por tamaño de letra. |
| `02_parsear_listas_a_b.py` | Separa las entradas de la Lista A (Anexo VIII) y la Lista B (Anexo IX) usando la sangría. |
| `03_extraer_tablas_nom052.py` | Extrae las filas de los Listados 1 a 5 de la NOM-052-SEMARNAT-2005 con detección de tablas. |
| `04_generar_sql_nom052.py` | Convierte esas filas en SQL (`supabase/seed/004_*.sql`). |
| `05_codigos_peru_por_columnas.py` | Lee el D.S. 014-2017-MINAM por columnas para listar los códigos de los Anexos III y V. |
| `06_generar_sql_basilea.py` | Genera el SQL de `basel_codes`. El resultado final lleva correcciones manuales (ver `docs/PENDIENTES.md`). |
| `data_static.py` | Texto oficial de las categorías Y, características H, operaciones D/R y notas, más las enmiendas BC-14/12 y BC-15/18. |

La verdad de los datos es la base de Supabase. Los seeds de `supabase/seed/` se probaron cargándolos desde cero en un Postgres 16 local
y dieron los mismos conteos que la base real.
