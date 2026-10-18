# Base de datos (Supabase)

Proyecto **TachoRojo**, región `sa-east-1`. Las claves nunca van en el repo: `service_role` solo en las credenciales de n8n.

## Cómo reconstruirla

1. `migrations/0001_esquema.sql`: tablas, índices, vistas, funciones, RLS y buckets.
2. Seeds, en este orden (cada uno depende del anterior):

| Archivo | Contenido |
|---|---|
| `seed/001_referencias_base.sql` | Países, normas, contenedores, GHS, peligrosidad, permisos, reglas, casos de prueba |
| `seed/002_basilea.sql` | Catálogo completo de Basilea (Anexos I a IV, VIII y IX) |
| `seed/003_listados_chile.sql` | DS 148: Listas I, II y III |
| `seed/004_listados_mexico_nom052.sql` | NOM-052: Listados 1, 3, 4 y 5 |
| `seed/004b_listado2_mexico.sql` | NOM-052: Listado 2 |
| `seed/005_equivalencias_basilea.sql` | Perú, Chile y México contra Basilea |
| `seed/006_peligrosidad_basilea_h.sql` | Peligrosidad de cada país contra las características H |

3. `pending/ajustes_pendientes.sql`: cambios que no llegaron a aplicarse en la base real (ver `docs/PENDIENTES.md`).

En la base real el esquema se aplicó en varias migraciones; este archivo lo deja consolidado. La extensión `vector` (pgvector) la trae Supabase.
