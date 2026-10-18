# Pendientes de la base de datos

## Datos por completar
- **Prompt v1 y modelos de IA**: `prompt_versions` y `ml_models` están vacías. El prompt con las reglas del README está redactado pero no se cargó.
- **Perú y Chile no incluyen** A1181, A3210 ni B3011 (sus anexos son anteriores a 2021). Perú modificó su reglamento en 2022 (D.S. 001-2022-MINAM): hay que revisar si actualizó los anexos.
- **México no tiene equivalencia código a código** con Basilea: la NOM-052 usa sus propias claves. Las 7 equivalencias cargadas son por concepto.
- **Listado 3 y 4 de la NOM-052**: todas las entradas apuntan a A4140 por concepto (productos químicos caducos). Si un residuo concreto tiene un código de Basilea más específico, hay que refinarlo.
- **Sin norma federal de colores en México** para residuos industriales: el rojo es una convención de la planta, no una obligación legal.
- **NCh 3322 (Chile)**: falta leer el texto oficial para confirmar la tabla, los códigos RAL y si es obligatoria.
- **NTP 900.058 (Perú)**: falta contrastar las tablas 1 y 2 con el PDF oficial de INACAL.

- **Rubros**: los 115 perfiles de `sector_waste_profiles` son un borrador (`verified = false`). Jazmín debe revisar qué residuos son típicos de cada rubro y ajustar los códigos de Basilea. Los rubros no están ligados a normas por país: una planta mexicana de minería aún no se cruza con el Listado 1 de la NOM-052.

## Correcciones sobre el texto oficial
- **A3160**: la primera fuente consultada repetía A3150 en esa entrada; el texto oficial confirma A3160.
- **A1190 (español)**: el texto oficial en español está truncado; se completó traduciendo el inglés. Es el único código con `verified = false`.
- **B3026 (español)**: decía "anexo II"; se corrigió a "anexo III" según el inglés.
- **B1120**: la lista de elementos se reordenó porque el original está en dos columnas.
- **Y48, Y49, A1181 y B3011**: se guardaron en una sola línea; en el original son listas con viñetas.
- **NOM-052, Listado 3**: algunas fórmulas quedaron con espacios de los subíndices ("H AsO 3 4"). La clave T210 aparece dos veces en el Listado 4 (tetracloroetileno); solo se guardó una.

## Cambios que no llegaron a aplicarse
Cinco actualizaciones de filas existentes se cancelaron dos veces seguidas (marcas de verificación y notas de fuente de NOM-052, DS 148, D.S. 014-2017, categorías de Chile y nota de los colores no municipales de Perú). Están en [`supabase/pending/ajustes_pendientes.sql`](../supabase/pending/ajustes_pendientes.sql).

## Validación
- Jazmín debe validar todo lo `verified = false` y las equivalencias `inferencia` antes de usar la app en producción.
- Hay que confirmar con un asesor mexicano el registro de generador y el plazo de almacenamiento.
