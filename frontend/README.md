# TachoRojo · aplicación web (PWA)

App para celular, sin dependencias ni paso de compilación: HTML, CSS y JavaScript con módulos.

## Probarla

```bash
cd frontend
python3 -m http.server 8080
# abrir http://localhost:8080 (en el celular: la IP de tu computador; la cámara exige HTTPS fuera de localhost)
```

Para publicarla basta cualquier hosting estático (GitHub Pages, Vercel, Netlify). Una vez abierta, se puede instalar desde el navegador y abre sin conexión.

## Dos modos

| Modo | Cuándo | Qué hace |
|---|---|---|
| **Demo** | `n8nBaseUrl` vacío en `js/config.js` | Reglas simples en el navegador. **No usa IA ni mira la foto**; solo revisa su calidad (luz, nitidez, tamaño). La foto no sale del celular. Sirve para probar el flujo y los catálogos. |
| **Conectado** | `n8nBaseUrl` apunta a los webhooks de n8n | Llama a `/v1/session`, `/v1/photo` y `/v1/classify` (ver `docs/ARQUITECTURA.md`). La IA y las claves viven solo en n8n. |

## Qué lee de la base

Los catálogos públicos de Supabase (contenedores por país y ámbito, rubros, perfiles de residuos y reglas de manejo) con la clave pública, que solo puede leer. Si no hay red usa `data/catalogs.json`, una copia incluida. Para refrescar esa copia, vuelve a ejecutar el script que la genera (ver `tools/`).

## Estructura

| Archivo | Función |
|---|---|
| `index.html`, `css/styles.css` | Estructura y estilos, pensados para celular con botones grandes |
| `js/app.js` | Las 4 pantallas: bienvenida, foto, conversación y resultado |
| `js/engine*.js` | `engine-demo.js` (reglas locales) y `engine-remote.js` (n8n), con la misma interfaz |
| `js/quality.js` | Control de calidad de la foto en el celular |
| `js/result.js` | Arma la tarjeta de resultado y la regla precautoria |
| `js/catalogs.js` | Carga de catálogos (Supabase o copia incluida) |
| `sw.js`, `manifest.webmanifest` | Instalación y uso sin conexión |

## Reglas que cumple

- Máximo 3 preguntas de seguimiento, una por vez, con botones, "Otro…" y "No sé".
- Si hay duda o el usuario dice "No sé", resultado PELIGROSO en contenedor rojo (regla precautoria).
- Si el servidor falla o devuelve un JSON inválido, reintenta una vez y luego aplica la regla precautoria.
- Si no hay una norma de colores confirmada para un material o país, lo dice en vez de inventar un color.
