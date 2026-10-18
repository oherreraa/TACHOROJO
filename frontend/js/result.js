// Arma la tarjeta de resultado (contrato del README, sección 6) a partir de los catálogos.
const COLOR_HEX = {
  rojo: '#d32f2f', azul: '#1976d2', blanco: '#f5f5f5', amarillo: '#fbc02d', 'marrón': '#6d4c41', 'café': '#6d4c41',
  plomo: '#9e9e9e', 'gris claro': '#b0b0b0', 'gris oscuro': '#424242', negro: '#212121', verde: '#388e3c',
  beige: '#d7ccc8', burdeo: '#880e4f'
};
export const colorHex = c => COLOR_HEX[(c || '').toLowerCase()] || '#9e9e9e';

const KIND_LABEL = {
  papel: /papel|cart/i, plastico: /pl[aá]stic/i, metal: /metal/i, vidrio: /vidrio/i, madera: /madera|org[aá]nic/i,
  organico: /org[aá]nic/i, escombro: /no aprovechable|otros/i, neumatico: /no aprovechable|otros/i, noaprovechable: /no aprovechable|otros/i
};

const LEGAL = {
  PE: 'D.S. 014-2017-MINAM (art. 30 y anexos) · NTP 900.058:2019',
  CL: 'DS 148 (MINSAL) · NCh 3322:2013',
  MX: 'LGPGIR · NOM-052-SEMARNAT-2005'
};

const TIPS = {
  peligroso: 'Un envase que contuvo algo peligroso sigue siendo peligroso aunque esté vacío.',
  papel: 'El papel mojado con aceite o químicos ya no se recicla: pasa a ser peligroso.',
  plastico: 'Un plástico limpio y de un solo tipo se recicla mucho mejor.',
  metal: 'La chatarra limpia se vende y se recicla; con aceite o pintura hay que tratarla como peligrosa.',
  vidrio: 'El vidrio se recicla infinitas veces sin perder calidad.',
  madera: 'La madera tratada con preservantes es peligrosa; la madera limpia no.',
  organico: 'Separar los orgánicos permite hacer compost y evita malos olores.',
  default: 'Separar en el lugar donde se genera evita errores costosos después.'
};

const HAZ_TEXT = { inflamable: 'inflamable', ecotoxico: 'tóxico para el ambiente', toxico: 'tóxico', corrosivo: 'corrosivo', explosivo: 'explosivo', reactivo: 'reactivo', patogeno: 'infeccioso', salud_cronica: 'daño crónico a la salud', gas_presion: 'gas a presión', comburente: 'comburente', nocivo: 'nocivo' };

function containerFor(cat, ctx, d) {
  const schemes = (cat.container_schemes || []).filter(s => s.country_code === ctx.country && s.scope === ctx.scope && !/RPBI/i.test(s.label));
  if (d.hazardous) {
    const h = schemes.find(s => s.hazardous);
    if (h) return { color: h.color, label: h.label, note: null };
    return { color: 'rojo', label: 'Peligrosos', note: 'En este país no hay una norma de colores confirmada para residuos industriales: el rojo es la convención recomendada. Sigue el esquema de tu planta.' };
  }
  const re = KIND_LABEL[d.kind];
  const norm = s => s.label.toLowerCase();
  let m = re ? schemes.find(s => !s.hazardous && re.test(s.label)) : null;
  if (!m && ctx.country === 'PE' && ctx.scope === 'municipal' && ['papel', 'plastico', 'vidrio', 'metal', 'madera'].includes(d.kind)) m = schemes.find(s => /^aprovechables/i.test(norm(s)));
  if (m) return { color: m.color, label: m.label, note: null };
  const gen = schemes.find(s => /no aprovechable|otros/i.test(s.label));
  if (gen) return { color: gen.color, label: gen.label, note: null };
  return { color: 'negro', label: 'Residuos generales', note: 'No hay un color normado confirmado para este material en este país. Usa el contenedor de residuos generales de tu planta.' };
}

function actionsFor(d, c) {
  if (d.hazardous) {
    const a = ['Colócalo en el contenedor ' + c.color + ', bien cerrado.', 'No lo mezcles con residuos comunes ni con otros residuos peligrosos.', 'Rotula el nombre del residuo y la fecha, y avisa al responsable ambiental.'];
    if (d.kind === 'peligroso' && /biocontaminado/.test(d.label || '')) a[0] = 'Colócalo en el recipiente rígido rojo para punzocortantes o en la bolsa roja o amarilla, según corresponda.';
    return a;
  }
  return ['Deposítalo en el contenedor ' + c.color + '.', 'Verifica que esté limpio y seco.', 'Si se ensucia con aceite, pintura o químicos, vuelve a clasificarlo.'];
}

export function buildResult(cat, ctx, d) {
  const container = containerFor(cat, ctx, d);
  const basel = d.code ? (cat.basel_codes || []).find(b => b.code === d.code) : null;
  const hz = (d.hazard || []).map(h => HAZ_TEXT[h] || h);
  const extra = [];
  if (ctx.country === 'MX' && d.hazardous) extra.push('Si tu planta tiene registro de generador ante SEMARNAT, revisa que este residuo esté en tu permiso.');
  if (d.alt && ['A1181', 'Y49'].includes(d.alt)) extra.push('Los equipos electrónicos peligrosos se clasifican hoy como A1181; algunos países aún citan A1180.');
  if (container.note) extra.push(container.note);
  return {
    classification: d.hazardous ? 'PELIGROSO' : 'NO_PELIGROSO',
    container: { color: container.color, label: container.label, hex: colorHex(container.color) },
    basel: d.code && basel ? { code: basel.code, description: basel.description_es, confidence: d.conf || 'media' } : null,
    hazard: hz.length ? 'Es ' + hz.join(' y ') + '.' : null,
    actions: [...actionsFor(d, container), ...extra],
    legal_basis: LEGAL[ctx.country] || '',
    did_you_know: TIPS[d.hazardous ? 'peligroso' : d.kind] || TIPS.default,
    precautionary_applied: false
  };
}

export function precautionResult(cat, ctx, reason) {
  const container = containerFor(cat, ctx, { hazardous: true });
  return {
    classification: 'PELIGROSO',
    container: { color: container.color, label: container.label, hex: colorHex(container.color) },
    basel: null,
    hazard: 'No hay datos suficientes para descartar que sea peligroso.',
    actions: ['Colócalo en el contenedor ' + container.color + ', bien cerrado, hasta confirmar.', 'Consulta al responsable ambiental antes de decidir otro destino.', reason || ''].filter(Boolean),
    legal_basis: LEGAL[ctx.country] || '',
    did_you_know: 'Ante la duda, se trata como peligroso: es más barato equivocarse hacia el lado seguro.',
    precautionary_applied: true
  };
}
