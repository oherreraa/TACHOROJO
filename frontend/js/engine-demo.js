// Motor de demostración: reglas simples en el navegador, SIN IA y sin mirar la foto.
// Sirve para probar el flujo completo antes de conectar n8n. No reemplaza al motor real.
import { checkImage } from './quality.js';
import { buildResult, precautionResult } from './result.js';

const norm = s => (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');
const has = (t, stems) => stems.some(s => new RegExp('\\b' + s).test(t));

// Contaminantes: si el residuo los tocó, se trata como peligroso.
const CONTAMINANTS = [
  { id: 'aceite', stems: ['aceit', 'grasa', 'lubric', 'hidrocarb', 'diesel', 'petroleo', 'combustible', 'gasolina', 'derrame', 'dielectric'], code: 'A3020', hazard: ['inflamable', 'ecotoxico'], label: 'aceite o combustible' },
  { id: 'pintura', stems: ['pintur', 'barniz', 'laca', 'esmalte', 'anticorrosiv'], code: 'A4070', hazard: ['inflamable', 'toxico'], label: 'pintura o barniz' },
  { id: 'solvente', stems: ['solvent', 'thinner', 'tinner', 'diluyente', 'acetona', 'desengras'], code: 'A3140', hazard: ['inflamable', 'toxico'], label: 'solvente' },
  { id: 'plaguicida', stems: ['plaguicid', 'herbicid', 'pesticid', 'fungicid', 'insecticid', 'agroquimic'], code: 'A4030', hazard: ['toxico', 'ecotoxico'], label: 'plaguicida' },
  { id: 'acido', stems: ['acido', 'soda caustica', 'alcali', 'lejia', 'corrosiv'], code: 'A4090', hazard: ['corrosivo'], label: 'ácido o base' },
  { id: 'quimico', stems: ['quimic', 'reactivo', 'detergente', 'desinfect', 'fertiliz', 'cianuro', 'resina', 'adhesivo', 'pegamento'], code: 'A4140', hazard: ['toxico'], label: 'producto químico' }
];

// Residuos peligrosos por sí mismos (no dependen de qué los ensució).
const STRONG = [
  { id: 'bateria_plomo', stems: ['bateria', 'acumulador'], need: ['plomo', 'acid', 'auto', 'ups', 'vehicul', 'montacarga'], code: 'A1160', hazard: ['toxico', 'corrosivo'], label: 'batería de plomo-ácido', kind: 'peligroso' },
  { id: 'pila', stems: ['pilas?\\b', 'bateria', 'litio'], code: 'A1170', hazard: ['toxico', 'corrosivo'], label: 'pilas o baterías', kind: 'peligroso' },
  { id: 'fluorescente', stems: ['fluorescent', 'mercurio', 'lampara de vapor', 'tubo fluorescent', 'foco ahorrador'], code: 'A1030', alt: 'A1181', hazard: ['toxico', 'ecotoxico'], label: 'lámpara con mercurio', kind: 'peligroso' },
  { id: 'asbesto', stems: ['asbesto', 'amianto', 'fibrocemento', 'eternit'], code: 'A2050', hazard: ['salud_cronica'], label: 'material con asbesto', kind: 'peligroso' },
  { id: 'pcb', stems: ['pcb', 'bifenil'], code: 'A3180', hazard: ['toxico', 'ecotoxico', 'salud_cronica'], label: 'residuo con PCB', kind: 'peligroso' },
  { id: 'aerosol', stems: ['aerosol', 'spray'], code: 'A4130', hazard: ['gas_presion', 'inflamable'], label: 'aerosol', kind: 'peligroso' },
  { id: 'medicamento', stems: ['medicament', 'farmac', 'vacuna', 'citostatic'], code: 'A4010', alt: 'Y3', hazard: ['toxico'], label: 'medicamento vencido', kind: 'peligroso' },
  { id: 'biocontaminado', stems: ['jeringa', 'aguja', 'bisturi', 'punzocortante', 'biocontaminad', 'infeccios', 'sangre', 'gasa con'], code: 'A4020', alt: 'Y1', hazard: ['patogeno'], label: 'residuo biocontaminado', kind: 'peligroso' },
  { id: 'explosivo', stems: ['explosiv', 'detonador', 'polvora', 'cordon detonante'], code: 'A4080', hazard: ['explosivo'], label: 'material explosivo', kind: 'peligroso' },
  { id: 'toner', stems: ['toner', 'cartucho de tinta', 'cartucho de toner'], code: 'Y12', alt: 'A4070', hazard: ['toxico'], label: 'tóner o tinta', kind: 'peligroso' },
  { id: 'electronico', stems: ['electronic', 'computadora', 'laptop', 'impresora', 'celular', 'raee', 'monitor', 'cargador', 'placa electron'], code: 'A1181', alt: 'Y49', hazard: ['toxico'], label: 'equipo electrónico', kind: 'peligroso' },
  { id: 'cianuro', stems: ['cianuro'], code: 'A4050', hazard: ['toxico', 'ecotoxico'], label: 'residuo con cianuro', kind: 'peligroso' }
];

// Materiales que normalmente no son peligrosos si están limpios.
const MATERIALS = [
  { id: 'papel', stems: ['carton', 'papel', 'periodico', 'revista', 'caja de carton', 'archivo', 'folder'], code: 'B3020', label: 'papel o cartón', kind: 'papel' },
  { id: 'plastico', stems: ['plastic', 'pet\\b', 'film', 'bolsa', 'envoltura', 'botella plastica', 'bidon plastico', 'polietileno', 'stretch'], code: 'B3011', alt: 'B3010', label: 'plástico', kind: 'plastico' },
  { id: 'vidrio', stems: ['vidrio', 'botella de vidrio', 'frasco de vidrio', 'cristal'], code: 'B2020', label: 'vidrio', kind: 'vidrio' },
  { id: 'metal', stems: ['metal', 'chatarra', 'fierro', 'acero', 'aluminio', 'cobre', 'alambre', 'lata', 'viruta', 'tuberia', 'perfil'], code: 'B1010', label: 'metal', kind: 'metal' },
  { id: 'cable', stems: ['cable'], code: 'B1115', alt: 'B1010', label: 'cable', kind: 'metal' },
  { id: 'madera', stems: ['madera', 'pallet', 'tarima', 'tabla', 'aserrin', 'encofrado'], code: 'B3050', label: 'madera', kind: 'madera' },
  { id: 'organico', stems: ['organic', 'comida', 'alimento', 'cascara', 'poda', 'restos de cocina', 'bagazo', 'fruta', 'verdura'], code: null, label: 'residuo orgánico', kind: 'organico' },
  { id: 'escombro', stems: ['escombro', 'concreto', 'ladrillo', 'mortero', 'cemento roto'], code: 'B2040', label: 'escombro o concreto', kind: 'escombro' },
  { id: 'neumatico', stems: ['neumatic', 'llanta'], code: 'B3140', label: 'neumático', kind: 'neumatico' }
];

// Objetos que se ensucian: la clasificación depende de lo que tocaron.
const SOILED = ['trapo', 'pano', 'guante', 'epp', 'absorbente', 'aserrin', 'filtro', 'estopa', 'waipe', 'wipe', 'tela', 'ropa'];
const CONTAINER = ['envase', 'bidon', 'tambor', 'frasco', 'tarro', 'galon', 'lata', 'saco', 'balde', 'cilindro', 'botella'];
const CLEAN_WORDS = ['limpio', 'limpia', 'sin restos', 'seco', 'seca', 'vacio y limpio', 'nuevo'];

export function analyze(text) {
  const t = norm(text);
  const edible = /comestible|freir|fritura|cocina|freidora/.test(t) && has(t, ['aceit', 'grasa']);
  let contaminants = CONTAMINANTS.filter(c => has(t, c.stems));
  if (edible) contaminants = contaminants.filter(c => c.id !== 'aceite');
  const hits = STRONG.filter(s => has(t, s.stems));
  const batt = hits.some(s => s.id === 'bateria_plomo' || s.id === 'pila');
  const other = hits.find(s => s.id !== 'bateria_plomo' && s.id !== 'pila');
  let strong = other || null;
  if (!strong && batt) strong = has(t, STRONG[0].need) ? STRONG[0] : STRONG[1];
  const materials = MATERIALS.filter(m => has(t, m.stems));
  if (edible) materials.unshift({ id: 'aceite_comestible', code: 'B3065', label: 'aceite de cocina usado', kind: 'noaprovechable' });
  return {
    t,
    contaminants,
    strong,
    materials,
    soiled: has(t, SOILED),
    container: has(t, CONTAINER),
    clean: CLEAN_WORDS.some(w => t.includes(w)),
    unknown: /\bno se\b|\bno sabe\b|\bni idea\b|\bno estoy seguro\b/.test(t)
  };
}

function bestProfile(text, sector, profiles) {
  const t = norm(text);
  const toks = new Set(t.split(/[^a-z0-9]+/).filter(w => w.length > 3));
  let best = null, score = 0;
  for (const p of profiles.filter(p => !sector || p.sector_id === sector)) {
    const words = norm(p.waste_name_es + ' ' + (p.examples_es || '')).split(/[^a-z0-9]+/).filter(w => w.length > 3);
    const s = words.filter(w => toks.has(w)).length;
    if (s > score) { score = s; best = p; }
  }
  return score >= 1 ? best : null;
}

const Q_CONTENT = { id: 'content', question: '¿Qué contuvo el envase?', options: ['Aceite o combustible', 'Pintura o solvente', 'Otro químico o plaguicida', 'Alimento, agua o nada', 'No sé'] };
const Q_SOILED = { id: 'soiled', question: '¿Con qué se ensució?', options: ['Aceite o grasa', 'Pintura o solvente', 'Otro producto químico', 'Solo agua o polvo', 'No sé'] };
const Q_CLEAN = { id: 'clean', question: '¿Está limpio, sin restos de aceite, pintura o químicos?', options: ['Sí, está limpio', 'Tiene restos de aceite o grasa', 'Tiene restos de pintura o químicos', 'No sé'] };
const Q_GENERIC = { id: 'generic', question: '¿Qué tipo de residuo es?', options: ['Aceite, grasa o combustible', 'Pintura, solvente o químico', 'Papel, cartón, plástico o metal', 'Equipo electrónico, pila o batería', 'No sé'] };

export function createDemoEngine(cat, ctx) {
  const st = { texts: [], asked: [], q: 0, summary: null, lastHyp: null };
  const joined = () => st.texts.join(' . ');

  function precaution(reason) {
    return { stage: 'result', result: precautionResult(cat, ctx, reason) };
  }

  function decide() {
    const f = analyze(joined());
    if (f.unknown && st.q > 0) return precaution('Dijiste que no sabes qué es o qué tocó.');
    // 1. peligrosos por sí mismos
    if (f.strong) return { type: 'done', code: f.strong.code, alt: f.strong.alt, hazard: f.strong.hazard, label: f.strong.label, hazardous: true, kind: f.strong.kind, conf: 'alta' };
    // 2. contaminante identificado en cualquier objeto
    const cont = f.contaminants[0];
    const matCont = f.materials[0];
    if (cont && (f.soiled || f.container || matCont || st.asked.includes('soiled') || st.asked.includes('content') || st.asked.includes('clean'))) {
      const what = f.container ? 'envase con restos de ' + cont.label : (f.soiled ? 'material absorbente con ' + cont.label : (matCont ? matCont.label + ' con restos de ' + cont.label : cont.label));
      return { type: 'done', code: f.container ? 'A4130' : cont.code, alt: f.container ? cont.code : null, hazard: cont.hazard, label: what, hazardous: true, kind: 'peligroso', conf: 'alta' };
    }
    if (cont) return { type: 'done', code: cont.code, hazard: cont.hazard, label: cont.label, hazardous: true, kind: 'peligroso', conf: 'media' };
    // 3. objetos que dependen de lo que tocaron
    if (f.container && !st.asked.includes('content') && !f.clean) return { type: 'ask', q: Q_CONTENT };
    if (f.soiled && !st.asked.includes('soiled') && !f.clean) return { type: 'ask', q: Q_SOILED };
    if ((f.container || f.soiled) && (st.asked.includes('content') || st.asked.includes('soiled'))) {
      const last = norm(st.texts[st.texts.length - 1]);
      if (/agua|polvo|nada|alimento/.test(last)) return { type: 'done', code: null, hazard: [], label: f.container ? 'envase limpio' : 'material con agua o polvo', hazardous: false, kind: 'noaprovechable', conf: 'media' };
    }
    // 4. materiales aprovechables
    if (matCont) {
      if (f.clean || st.asked.includes('clean')) {
        return { type: 'done', code: matCont.code, alt: matCont.alt, hazard: [], label: matCont.label + ' limpio', hazardous: false, kind: matCont.kind, conf: 'media' };
      }
      return { type: 'ask', q: Q_CLEAN };
    }
    // 5. perfil del rubro
    const prof = bestProfile(joined(), ctx.sector, cat.sector_waste_profiles || []);
    if (prof && !st.asked.includes('profile')) {
      st.lastHyp = prof;
      return { type: 'ask', q: { id: 'profile', question: '¿Se parece a «' + prof.waste_name_es + '»' + (prof.examples_es ? ' (' + prof.examples_es + ')' : '') + '?', options: ['Sí, es eso', 'No, es otra cosa', 'No sé'] } };
    }
    if (st.asked.includes('profile') && st.lastHyp && /^si/.test(norm(st.texts[st.texts.length - 1]))) {
      const p = st.lastHyp;
      return { type: 'done', code: p.primary_basel_code, alt: (p.alt_basel_codes || [])[0], hazard: p.hazard_type_ids || [], label: p.waste_name_es.toLowerCase(), hazardous: p.hazardous_typical, kind: p.hazardous_typical ? 'peligroso' : 'noaprovechable', conf: 'media' };
    }
    return { type: 'ask', q: Q_GENERIC };
  }

  function next() {
    const d = decide();
    if (d.stage === 'result') return d;
    if (d.type === 'ask') {
      if (st.q >= 3 || st.asked.includes(d.q.id)) return precaution('No alcanzó la información después de ' + st.q + ' preguntas.');
      st.asked.push(d.q.id);
      st.q++;
      return { stage: 'follow_up', follow_up: { question: d.q.question, options: d.q.options, index: st.q, max: 3 } };
    }
    st.pending = d;
    const where = ctx.sector ? ' (rubro: ' + (cat.industry_sectors.find(s => s.id === ctx.sector) || {}).name_es + ')' : '';
    st.summary = 'Entendí: ' + d.label + where;
    return { stage: 'summary', summary: st.summary };
  }

  return {
    mode: 'demo',
    async start() { return { session_id: 'demo' }; },
    async photo(file) {
      const quality = await checkImage(file);
      if (!quality.ok) return { stage: 'quality_check', quality };
      return { stage: 'context', quality, detected: 'Foto recibida. En modo demo la imagen no se analiza: cuéntame qué es.' };
    },
    async answer(text) {
      st.texts.push(text);
      return next();
    },
    async confirm() {
      const d = st.pending;
      return { stage: 'result', result: buildResult(cat, ctx, d) };
    },
    async correct() {
      st.texts = []; st.asked = []; st.q = 0; st.pending = null; st.lastHyp = null;
    }
  };
}
