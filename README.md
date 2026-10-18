# TachoRojo

> Clasificador de residuos industriales por foto, según la NTP 900.058:2019 y el D.S. 014-2017-MINAM.
> Este archivo es también el contexto para el agente de código: léelo completo antes de cambiar nada.

## 1. Qué es

TachoRojo es una app web, pensada primero para celular, que ayuda a un trabajador de una central de generación eléctrica a disponer correctamente un residuo en el momento en que lo genera.

El trabajador toma una foto y responde una conversación corta. La IA le dice:

- en qué contenedor va, según la NTP 900.058:2019;
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

### Marco normativo
- **D.L. 1278:** Ley de Gestión Integral de Residuos Sólidos.
- **D.S. 014-2017-MINAM:** su reglamento. El art. 30 define los residuos peligrosos; los anexos contienen las listas.
- **NTP 900.058:2019:** código de colores para contenedores.
- **D.S. 002-2022-VIVIENDA:** residuos de construcción y demolición. Aplica a obras dentro de la planta. Ante dudas de peligrosidad, el generador pide opinión técnica al MINAM (art. 8.2).
- **Obligaciones del generador no municipal:** reportar la Declaración anual y los Manifiestos de peligrosos en Sigersol. La omisión puede multarse hasta con 3 UIT por incumplimiento.

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

## 9. Arquitectura propuesta: frontend + n8n + IA gratuita

Objetivo: operar con costo cero o mínimo en la etapa de prototipo.

```
[Frontend web móvil]  --foto + texto (HTTPS)-->  [Webhook n8n]
                                                     |
                      +------------------------------+
                      v
        [Nodo de calidad de foto]  -> Gemini (visión, tier gratuito)
        [Nodo de clasificación]    -> Gemini / modelo alterno, con tabla de Basilea en el prompt
        [Validación JSON (Code)]   -> reintento 1 vez; si falla, regla precautoria
                      |
                      v
        Respuesta JSON al frontend  (+ log opcional en Google Sheets / Supabase)
```

**Piezas**
- **Frontend:** app web móvil (hoy, el export de AI Studio). Llama únicamente al webhook de n8n; no contiene claves.
- **n8n (self-hosted o cloud):** orquesta el flujo. Un webhook por etapa o un único webhook con `stage`. La conversación (máx. 3 preguntas) se mantiene reenviando el historial en cada llamada o con un `sessionId` y memoria.
- **IA gratuita:**
  - Gemini API (Google AI Studio) con tier gratuito para visión y texto. Sujeto a límites de cuota; verificar condiciones vigentes.
  - Alternativas para el mismo nodo HTTP/LLM de n8n: modelos de visión en Hugging Face Inference, OpenRouter (modelos `:free`) u Ollama local (por ejemplo, un modelo multimodal) si hay servidor propio.
  - Un nodo de entrada intercambiable permite cambiar de proveedor sin tocar el frontend.
- **GitHub:** repo del código y de los workflows de n8n exportados (`/n8n/*.json`, sin credenciales). GitHub Actions puede correr los tests de la sección 7 contra el webhook de pruebas. GitHub Pages sirve el frontend estático.
- **Datos de referencia:** la tabla de Basilea y los colores viven en `/data/` (JSON) y se inyectan al prompt desde n8n. Si crece, pasar a RAG.

**Estructura de repo sugerida**

```
/README.md
/frontend/        app web móvil
/n8n/             workflows exportados (sin credenciales)
/prompts/         prompts del sistema versionados
/data/            basilea.json, colores_ntp.json
/tests/           casos de la sección 7 y set de fotos
```

## 10. Hoja de ruta

1. Subir el código exportado de AI Studio a `/frontend` y ordenarlo.
2. Crear el workflow n8n (webhook → calidad → clasificación → validación) con Gemini gratuito.
3. Mover la llamada a Gemini del cliente al webhook; rotar la clave expuesta si hubo alguna.
4. Validar el JSON con esquema y automatizar los tests de la sección 7.
5. Configuración por planta: lista y colores propios.
6. Historial de clasificaciones y exportación para el manifiesto.
7. Canal por WhatsApp (n8n lo facilita).
8. Selector de país (Perú / México: CRETIB y NOM-052-SEMARNAT-2005).

## 11. Preguntas abiertas

- ¿Qué stack quedó en el código exportado de AI Studio? Revisar antes de proponer cambios grandes.
- ¿Dónde se desplegará n8n y el frontend: servidor propio, n8n Cloud, Vercel, GitHub Pages u otro?
- ¿Qué proveedor gratuito de visión da mejor concordancia con el criterio de Jazmín? Comparar con el set de fotos.
- ¿La tabla de Basilea debe vivir en el prompt o en una base de datos consultada por RAG?
