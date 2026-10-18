# TachoRojo

> Clasificador de residuos industriales por foto para Perú, Chile y México: contenedor según la norma del país, peligrosidad, código de Basilea y base legal.
> Este archivo es también el contexto para el agente de código: léelo completo antes de cambiar nada.

## 1. Qué es

TachoRojo es una app web, pensada primero para celular, que ayuda a un trabajador a disponer correctamente un residuo en el momento en que lo genera. Funciona en **Perú, Chile y México**, para residuos municipales y no municipales, y se ajusta a **10 rubros** (generación eléctrica, minería, transporte, oficinas, etc.). El rubro elegido orienta las preguntas de la IA.

El trabajador toma una foto y responde una conversación corta. La IA le dice:

- en qué contenedor va, según la norma del país (NTP 900.058:2019 en Perú, NCh 3322 en Chile, convención de planta en México);
- si el residuo es peligroso;
- el código del Convenio de Basilea más probable;
- qué hacer con el residuo;
- una pequeña enseñanza.

Nació como prototipo en la ideathon **Sueñ-IA en Grande** (UTEC, Lima, 17 oct 2026), isla Sostenibilidad y Medio Ambiente. La primera versión se construyó en Google AI Studio (modo Build) con Gemini.

**Equipo**
- Oscar Herrera: químico, Mg. en Ciencias Ambientales. Construye la app.
- Jazmín Calderón: ingeniera ambiental. Valida el criterio normativo.

## 2. Problema que resuelve

- En plantas industriales (ámbito **no municipal**), quien genera el residuo es quien lo dispone en el contenedor. No hay un intermediario que lo revise.
- Esa persona suele ser un técnico de mantenimiento o de una contratista que rota entre plantas. Decide en segundos si el residuo es peligroso, sin la hoja de seguridad (FDS) ni el reglamento a mano.
- El error no se ve ese día. Aparece después, en el manifiesto de residuos peligrosos (Sigersol) o en una supervisión del OEFA.
- Las soluciones con IA que ya existen (tachos inteligentes, apps de reciclaje) solo separan reciclables domésticos. No clasifican residuos peligrosos industriales según la norma peruana.

**Usuarios**
- **Principal:** técnico u operario de mantenimiento en una central eléctrica, sin formación en normativa.
- **Secundario:** residente de obra de una contratista que trabaja dentro de la planta (pinturas, solventes, desmonte).
- **Supervisión:** el responsable ambiental de la planta, que revisa y valida.

**Fuera de alcance:** residuos municipales, domicilios, talleres o pequeños negocios. Esos casos van a la recolección municipal y casi no generan peligrosos.

## 3. Flujo de la app (4 pantallas)

### Pantalla 1 · Bienvenida
- Saludo: "¡Hola! Te ayudo a disponer tu residuo en el tacho correcto en menos de un minuto."
- 3 pasos con íconos: 1) Toma una foto, 2) Cuéntanos de dónde salió, 3) Recibe dónde va y por qué.
- Tarjeta "Para una buena foto":
  - buena luz, sin contraluz ni flash que refleje;
  - residuo completo dentro del encuadre;
  - etiqueta visible, si tiene;
  - fondo despejado;
  - a 30–50 cm;
  - sin personas ni logos.
- Botón "Empezar".

### Pantalla 2 · Foto
- Botones "Tomar foto" y "Subir foto".
- **Control de calidad antes de clasificar.** Si la foto está borrosa, oscura, cortada o la etiqueta no se lee, la app NO clasifica. Muestra el motivo concreto y una sugerencia, y pide otra foto u otro ángulo. Ejemplos:
  - "La etiqueta no se lee. Acércate y toma la foto de frente al rótulo."
  - "Hay poca luz. Prueba junto a una ventana o con más iluminación."

### Pantalla 3 · Contexto (conversación tipo chat)
1. Muestra la miniatura de la foto y lo que la IA reconoció ("Veo un trapo con manchas oscuras").
2. Hace **una** pregunta abierta: "Cuéntame de dónde salió este residuo y qué estabas haciendo." Texto de ejemplo en el campo: "Ej.: lo usé para limpiar una fuga en una bomba". Micrófono opcional.
3. Con la foto y esa respuesta, la IA decide si ya puede clasificar con confianza.
4. Si le falta información, hace preguntas de seguimiento **de una en una, con un máximo de 3**. Cada pregunta:
   - es específica sobre lo que se ve y lo que dijo el usuario, nunca genérica ni repetida;
   - busca solo un dato que pueda cambiar la clasificación: qué contuvo o tocó, si está contaminado o limpio, o su estado (líquido, sólido, lodo, envase);
   - es corta y en lenguaje simple;
   - ofrece 2–4 botones de respuesta rápida, más "Otro" (texto libre) y "No sé".
5. Si con la primera respuesta ya basta, pasa directo al resultado.
6. Mientras pregunta, muestra un indicador discreto: "Pregunta 1 de 3 como máximo".
7. Si el usuario responde "No sé", o se agotan las preguntas sin certeza, se aplica la regla precautoria (ver sección 4).
8. Antes del resultado muestra un resumen: "Entendí: trapo con aceite de motor, de mantenimiento de una bomba", con los botones "Correcto, clasificar" y "Corregir".

Ejemplos del estilo de pregunta esperado:
- "¿La mancha del trapo es de aceite o de agua?"
- "¿El envase todavía tiene restos del producto o está seco?"
- "¿La etiqueta decía ácido, solvente o pintura?"

### Pantalla 4 · Resultado (tarjeta)
1. **Contenedor** según la NTP 900.058:2019 para el ámbito no municipal, con un círculo de color (ver sección 5).
2. **Clasificación:** PELIGROSO / NO PELIGROSO / NO ESTOY SEGURO.
3. **Código de Basilea más probable**, de la Lista A (peligrosos) o la Lista B (no peligrosos), con descripción corta y confianza (alta, media o baja). Si ningún código encaja con seguridad, la app lo dice y no inventa uno.
4. **Característica de peligrosidad**, si aplica (inflamable, corrosivo, reactivo, tóxico, ecotóxico…), en una frase simple.
5. **"Qué hacer ahora":** 2–3 pasos concretos (envase cerrado, no mezclar, rotular, llevar al punto de acopio).
6. **Base legal** en una línea: D.S. 014-2017-MINAM (art. 30 y anexos) y NTP 900.058:2019.
7. **"¿Sabías que…?":** una enseñanza breve y amigable, de máximo 2 líneas.
8. Etiqueta: "Sugerencia de IA · verificar con el responsable ambiental".
- Botón "Clasificar otro residuo".

## 4. Reglas de clasificación (no negociables)

- **Regla precautoria:** si la confianza es baja o hay señales de contaminación (manchas, olor descrito, restos), el resultado es PELIGROSO, contenedor rojo, con la recomendación de consultar al responsable ambiental.
- Un envase que contuvo una sustancia peligrosa es peligroso aunque esté vacío (D.S. 014-2017-MINAM, art. 30).
- Un residuo es peligroso si presenta al menos una característica de peligrosidad.
- Si la foto y lo que dice el usuario se contradicen, la app lo señala y aplica la regla precautoria.
- Nunca hace más de 3 preguntas de seguimiento por residuo.
- Lenguaje simple y respuestas cortas.
- La app sugiere; la decisión final es de la persona y del responsable ambiental.

## 5. Datos de referencia

### Colores NTP 900.058:2019 (ámbito no municipal)

| Color | Tipo de residuo |
|---|---|
| Rojo | Peligrosos |
| Azul | Papel y cartón |
| Blanco | Plásticos |
| Amarillo | Metales |
| Marrón | Orgánicos |
| Plomo | Vidrio |
| Negro | No aprovechables |

### Alcance multipaís (resumen)

| País | Peligroso / no peligroso | Colores | Observación |
|---|---|---|---|
| Perú | D.S. 014-2017-MINAM (Anexos III, IV, V) | NTP 900.058:2019: 4 colores municipal, 7 no municipal | Referencia de los colores de la tabla de arriba |
| Chile | DS 148 (Listas I, II, III; Lista A/B) | NCh 3322:2013 (rótulos de peligro) y NCh 2190 | Los colores de contenedor no son uniformes por ley |
| México | NOM-052-SEMARNAT-2005 (CPR: C, R, E, T, I, B; Listados 1–5), NOM-087 (RPBI) | **No existe norma federal de colores industriales**; rojo es convención de planta | Los generadores registran residuos y obtienen autorización (SEMARNAT-07-017): la app prevé subir ese permiso y clasificar con él |

Todo esto vive en la base de datos (ver sección 12), con indicador `verified` para lo que Jazmín aún debe validar.

### Códigos de Basilea frecuentes en generación eléctrica (semilla)

> **PENDIENTE:** Jazmín debe validar esta tabla contra los Anexos III y V del D.S. 014-2017-MINAM antes de usarla en producción.

| Código | Descripción |
|---|---|
| A3020 | Aceites minerales usados |
| A4060 | Mezclas de aceite y agua o de hidrocarburos y agua |
| A4130 | Envases y contenedores con restos de sustancias peligrosas |
| A1160 | Acumuladores de plomo de desecho |
| A1180 | Aparatos eléctricos y electrónicos con componentes peligrosos |
| A1030 | Residuos con mercurio (por ejemplo, lámparas fluorescentes) |
| A3180 | Residuos con PCB |
| A2050 | Asbesto |
| A4070 | Residuos de pinturas y barnices |
| A4090 | Soluciones ácidas o básicas de desecho |
| A3140 | Solventes orgánicos no halogenados |
| A4160 | Carbón activado gastado |
| B1010 | Chatarra metálica limpia |
| B3020 | Papel y cartón |
| B3010 | Plásticos |
| B3050 | Madera no tratada |

### Basilea completo y su relación con cada país

La base incluye el catálogo completo del Convenio (Anexos I, II, III, IV, VIII y IX, con las enmiendas BC-14/12 y BC-15/18), los listados nacionales (NOM-052, DS 148, D.S. 014-2017-MINAM) y las equivalencias país↔Basilea con tipo (`adopta`, `exacto`, `parcial`, `inferido`), confianza y base (texto oficial o inferencia). Las de México son por concepto y están sin verificar.

### Marco normativo
- **D.L. 1278:** Ley de Gestión Integral de Residuos Sólidos.
- **D.S. 014-2017-MINAM:** su reglamento. El art. 30 define los residuos peligrosos; los anexos contienen las listas.
- **NTP 900.058:2019:** código de colores para contenedores.
- **D.S. 002-2022-VIVIENDA:** residuos de construcción y demolición. Aplica a obras dentro de la planta. Ante dudas de peligrosidad, el generador pide opinión técnica al MINAM (art. 8.2).
- **Chile:** DS 148 (reglamento de residuos peligrosos), NCh 3322:2013 y NCh 2190. **México:** LGPGIR y RLGPGIR (categorías de generador: micro ≤400 kg/año, pequeño <10 t, gran ≥10 t), NOM-052, NOM-087.
- **Obligaciones del generador no municipal (Perú):** reportar la Declaración anual y los Manifiestos de peligrosos en Sigersol. La omisión puede multarse hasta con 3 UIT por incumplimiento.

## 6. Contrato de la IA (JSON)

El modelo debe devolver JSON estructurado. Esquema sugerido:

```json
{
  "stage": "quality_check | follow_up | result",
  "quality": { "ok": true, "issue": null, "tip": null },
  "detected": "trapo con manchas oscuras",
  "follow_up": {
    "question": "¿La mancha es de aceite o de agua?",
    "options": ["Aceite", "Agua", "Grasa", "No sé"],
    "index": 1
  },
  "summary": "Trapo con aceite de motor, de mantenimiento de una bomba",
  "result": {
    "classification": "PELIGROSO | NO_PELIGROSO | NO_SEGURO",
    "container": { "color": "rojo", "label": "Peligrosos" },
    "basel": { "code": "A3020", "description": "Aceites minerales usados", "confidence": "alta | media | baja" },
    "hazard": "Inflamable y tóxico para el agua",
    "actions": ["Colócalo en el contenedor rojo", "No lo mezcles con trapos limpios"],
    "legal_basis": "D.S. 014-2017-MINAM, art. 30 · NTP 900.058:2019",
    "did_you_know": "Un litro de aceite usado puede contaminar…",
    "precautionary_applied": false
  }
}
```

- Valida la salida con un esquema (Zod o similar) antes de pintar la tarjeta.
- Si el JSON es inválido, reintenta una sola vez. Si vuelve a fallar, aplica la regla precautoria.

## 7. Casos de prueba mínimos

| Entrada | Esperado |
|---|---|
| Trapo con aceite de motor | PELIGROSO · rojo · A3020 (o A4060 según el contexto) |
| Envase vacío de solvente | PELIGROSO · rojo · A4130 |
| Caja de cartón limpia | NO PELIGROSO · azul · B3020 |
| Lata con restos de pintura | PELIGROSO · rojo · A4070 / A4130 |
| Retazo de madera limpia | NO PELIGROSO · marrón o negro (según el criterio de la planta) · B3050 |
| Fluorescente roto | PELIGROSO · rojo · A1030 |
| Foto borrosa u oscura | No clasifica; pide otra foto con un motivo concreto |
| Usuario responde "No sé" 3 veces | Regla precautoria: PELIGROSO · rojo |

**Meta de calidad:** llegar a un set de 50–100 fotos reales clasificadas por Jazmín y medir la concordancia de la app con su criterio.

## 8. Restricciones técnicas y de privacidad

- La clave de API nunca va en el cliente: va en el servidor, en una función o en las credenciales de n8n.
- No guardar fotos con personas ni logos. Mostrar el aviso en la pantalla de foto.
- No incluir nombres de empresas reales en el código, los textos ni los datos de ejemplo.
- Pensada para celular, con botones grandes. Debe funcionar con conexión lenta.
- Sin login en esta etapa. Pie de página: "Demo · datos simulados".

## 9. Arquitectura: frontend + n8n + Supabase + IA gratuita

Diagramas completos y los 12 workflows en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

```
[PWA móvil] --HTTPS--> [Webhooks n8n] --> [IA de visión/texto gratuita (Gemini u otra)]
     |                       |
     | (solo lectura)        +--> [Supabase: catálogos, sesiones, clasificaciones, permisos, ML]
     +-----------------------+
```

- **Frontend** (`/frontend`): PWA sin dependencias. No tiene claves de IA; solo la clave pública de Supabase, que lee catálogos. Con `n8nBaseUrl` vacío corre en modo demo.
- **n8n:** orquestador. Webhooks `/v1/session`, `/v1/photo`, `/v1/classify`, feedback y permisos. Etapas: `quality_check`, `context`, `follow_up`, `summary`, `result`. Máximo 3 preguntas, un reintento de validación JSON y luego regla precautoria.
- **Supabase** (Postgres 17): 43 tablas, 7 vistas, 1 vista materializada, RLS, pgvector y pg_trgm. Detalle en [`docs/BASE_DE_DATOS.md`](docs/BASE_DE_DATOS.md).
- **IA gratuita:** Gemini (tier gratuito) u alternativas (Hugging Face, OpenRouter `:free`, Ollama), intercambiables en el nodo de n8n.
- **Publicación móvil:** como PWA se instala desde el navegador. Para Play Store: TWA con Bubblewrap. Para App Store: Capacitor, un Mac con Xcode y cuenta de desarrollador de pago.

**Estructura del repo**

```
/README.md
/frontend/    PWA (ver frontend/README.md)
/supabase/    migraciones, semillas y ajustes pendientes
/docs/        arquitectura, base de datos, fuentes, pendientes
/tools/       scripts de extracción de normas
/n8n/         workflows exportados (pendiente)
```

## 10. Hoja de ruta

| # | Tarea | Estado |
|---|---|---|
| 1 | Base de datos en Supabase con catálogos de Perú, Chile y México | Hecho |
| 2 | Catálogo completo de Basilea y equivalencias por país | Hecho (México sin verificar) |
| 3 | Rubros (10) con perfiles de residuos | Hecho (borrador, sin verificar) |
| 4 | Diagramas y contrato de la API | Hecho |
| 5 | Frontend PWA con modo demo | Hecho (v0.1.0) |
| 6 | Workflows de n8n con IA gratuita | Pendiente |
| 7 | Cargar `prompt_versions` y `ml_models` | Pendiente |
| 8 | Validación de datos por Jazmín (`verified=false`) | Pendiente |
| 9 | Tests automáticos de la sección 7 | Pendiente |
| 10 | Permisos de México: subir autorización y clasificar con ella | Tablas listas; flujo pendiente |
| 11 | Historial, exportación para manifiesto, canal WhatsApp | Pendiente |
| 12 | Publicar en Play Store / App Store | Pendiente |

## 11. Preguntas abiertas

- ¿Dónde se desplegarán n8n y el frontend: servidor propio, n8n Cloud, Vercel, GitHub Pages u otro?
- ¿Qué proveedor gratuito de visión concuerda mejor con el criterio de Jazmín? Comparar con un set de fotos.
- ¿Los perfiles por rubro y las equivalencias de México deben ser validados antes del piloto? (hoy `verified=false`)
- ¿Se confirma que en Chile no se impone un color único de contenedor industrial?
- Hay cinco ajustes pendientes de aplicar en la base: [`supabase/pending/ajustes_pendientes.sql`](supabase/pending/ajustes_pendientes.sql).

## 12. Base de datos

La base vive en Supabase (proyecto TachoRojo). Modelo y relaciones: [`docs/BASE_DE_DATOS.md`](docs/BASE_DE_DATOS.md). Fuentes: [`docs/FUENTES.md`](docs/FUENTES.md). Pendientes: [`docs/PENDIENTES.md`](docs/PENDIENTES.md). Esquema y datos reproducibles en [`supabase/`](supabase/).

## 13. Correr el frontend

```bash
cd frontend && python3 -m http.server 8080
```

Detalles en [`frontend/README.md`](frontend/README.md).
