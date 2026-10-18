import { CONFIG } from './config.js';
import { loadCatalogs } from './catalogs.js';
import { createEngine } from './engine.js';
import { precautionResult } from './result.js';

const $ = s => document.querySelector(s);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const store = {
  get(k, d) { try { return localStorage.getItem(k) ?? d; } catch { return d; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch { /* sin almacenamiento */ } }
};

const S = {
  screen: 'welcome', cat: null, engine: null, busy: false,
  country: store.get('tr_country', 'PE'), scope: store.get('tr_scope', 'no_municipal'), sector: store.get('tr_sector', 'energia_electrica'),
  photoUrl: null, quality: null, chat: [], pending: null, result: null, error: null, other: false
};

const SCOPE_NAME = { no_municipal: 'No municipal (industrial)', municipal: 'Municipal' };
const COUNTRY_NAME = { PE: 'Perú', CL: 'Chile', MX: 'México' };
const SR = window.SpeechRecognition || window.webkitSpeechRecognition;

function ctx() { return { country: S.country, scope: S.scope, sector: S.sector || null }; }

function go(screen) { S.screen = screen; render(); window.scrollTo(0, 0); }

// ---------- pantallas ----------
function welcome() {
  const sectors = S.cat.industry_sectors.map(s => `<option value="${esc(s.id)}" ${s.id === S.sector ? 'selected' : ''}>${esc(s.name_es)}</option>`).join('');
  const countries = S.cat.countries.map(c => `<option value="${c.code}" ${c.code === S.country ? 'selected' : ''}>${esc(c.name)}</option>`).join('');
  const scopes = Object.entries(SCOPE_NAME).map(([k, v]) => `<option value="${k}" ${k === S.scope ? 'selected' : ''}>${v}</option>`).join('');
  return `
    <h1>¡Hola! Te ayudo a disponer tu residuo en el tacho correcto en menos de un minuto.</h1>
    <ol class="steps card">
      <li><span class="n">1</span> Toma una foto</li>
      <li><span class="n">2</span> Cuéntanos de dónde salió</li>
      <li><span class="n">3</span> Recibe dónde va y por qué</li>
    </ol>
    <div class="card">
      <label class="f" for="sel-country">País</label><select id="sel-country">${countries}</select>
      <label class="f" for="sel-scope">Ámbito</label><select id="sel-scope">${scopes}</select>
      <label class="f" for="sel-sector">Rubro</label><select id="sel-sector">${sectors}</select>
    </div>
    <div class="card">
      <h2>Para una buena foto</h2>
      <ul class="tips">
        <li>Buena luz, sin contraluz ni flash que refleje.</li>
        <li>El residuo completo dentro del encuadre.</li>
        <li>La etiqueta visible, si tiene.</li>
        <li>Un fondo despejado y a 30–50 cm.</li>
        <li>Sin personas ni logos.</li>
      </ul>
    </div>
    <button class="btn" data-act="start" ${S.busy ? 'disabled' : ''}>${S.busy ? '<span class="spin"></span>Conectando…' : 'Empezar'}</button>
    ${S.error ? `<div class="card err"><p>${esc(S.error)}</p></div>` : ''}`;
}

function photo() {
  const q = S.quality;
  return `
    <h1>Foto del residuo</h1>
    ${q && !q.ok ? `<div class="card err" role="alert"><h2>No pude usar esta foto</h2><p>${esc(q.issue)}</p><p class="muted">${esc(q.tip)}</p></div>` : ''}
    <div class="row">
      <label class="btn" for="f-cam" role="button">Tomar foto</label>
      <label class="btn alt" for="f-up" role="button">Subir foto</label>
    </div>
    <input id="f-cam" type="file" accept="image/*" capture="environment">
    <input id="f-up" type="file" accept="image/*">
    ${S.busy ? '<p class="loading"><span class="spin"></span>Revisando la foto…</p>' : ''}
    ${S.error ? `<div class="card err" role="alert"><p>${esc(S.error)}</p></div>` : ''}
    <p class="muted">No fotografíes personas ni logos. ${CONFIG.n8nBaseUrl ? 'La foto se envía de forma segura al servidor.' : 'En modo demo la foto se queda en tu celular.'}</p>`;
}

function chat() {
  const msgs = S.chat.map(m => `<div class="msg ${m.from}">${esc(m.text)}</div>`).join('');
  const p = S.pending;
  let ctl = '';
  if (S.busy) ctl = '<p class="loading"><span class="spin"></span>Pensando…</p>';
  else if (p?.type === 'open') {
    ctl = `<textarea id="txt" placeholder="Ej.: lo usé para limpiar una fuga en una bomba" aria-label="Tu respuesta"></textarea>
      <div class="row"><button class="btn" data-act="send">Enviar</button>${SR ? '<button class="btn alt" data-act="mic">🎤 Hablar</button>' : ''}</div>`;
  } else if (p?.type === 'follow') {
    const opts = [...p.options];
    if (!opts.some(o => /no s[eé]/i.test(o))) opts.push('No sé');
    ctl = `<p class="progress">Pregunta ${p.index} de ${p.max} como máximo</p>
      <div class="chips">${opts.map(o => `<button class="chip ${/no s[eé]/i.test(o) ? 'sec' : ''}" data-act="opt" data-v="${esc(o)}">${esc(o)}</button>`).join('')}<button class="chip sec" data-act="other">Otro…</button></div>
      ${S.other ? '<input id="txt" type="text" placeholder="Escribe tu respuesta" aria-label="Otra respuesta"><button class="btn" data-act="send">Enviar</button>' : ''}`;
  } else if (p?.type === 'summary') {
    ctl = `<div class="card"><h2>${esc(p.summary)}</h2></div>
      <button class="btn" data-act="ok">Correcto, clasificar</button>
      <button class="btn alt" data-act="fix">Corregir</button>`;
  }
  return `<h1>Cuéntame más</h1>
    ${S.photoUrl ? `<img class="thumb" src="${S.photoUrl}" alt="Foto del residuo">` : ''}
    <div>${msgs}</div>${ctl}`;
}

function result() {
  const r = S.result;
  const hex = r.container.hex || '#9e9e9e';
  const light = ['#f5f5f5', '#fbc02d', '#d7ccc8'].includes(hex);
  const badgeText = { PELIGROSO: 'PELIGROSO', NO_PELIGROSO: 'NO PELIGROSO', NO_SEGURO: 'NO ESTOY SEGURO' }[r.classification];
  const b = r.basel;
  return `<div class="card result">
      <div class="bin" style="background:${hex};${light ? 'border-color:#666' : ''}" aria-hidden="true">🗑️</div>
      <h2>Contenedor ${esc(r.container.color)}</h2>
      <p class="muted">${esc(r.container.label)}</p>
      <span class="badge ${r.classification}">${badgeText}</span>
      ${r.precautionary_applied ? '<p class="muted" style="margin-top:8px">Regla precautoria aplicada: ante la duda, se trata como peligroso.</p>' : ''}
      <div class="kv"><b>Código de Basilea</b>${b ? `${esc(b.code)} · ${esc(b.description)} <span class="muted">(confianza ${esc(b.confidence)})</span>` : '<span class="muted">Ningún código encaja con seguridad.</span>'}</div>
      ${r.hazard ? `<div class="kv"><b>Peligrosidad</b>${esc(r.hazard)}</div>` : ''}
      <div class="kv"><b>Qué hacer ahora</b><ol class="actions">${r.actions.map(a => `<li>${esc(a)}</li>`).join('')}</ol></div>
      <div class="kv"><b>Base legal</b><span class="legal">${esc(r.legal_basis)}</span></div>
      <div class="kv"><b>¿Sabías que…?</b>${esc(r.did_you_know)}</div>
      <span class="tag">${CONFIG.n8nBaseUrl ? 'Sugerencia de IA' : 'Modo demo: reglas simples, sin IA ni análisis de la foto'} · verificar con el responsable ambiental</span>
    </div>
    <button class="btn" data-act="again">Clasificar otro residuo</button>`;
}

function render() {
  const el = $('#app');
  if (!S.cat) { el.innerHTML = '<p class="loading">Cargando…</p>'; return; }
  el.innerHTML = { welcome, photo, chat, result }[S.screen]();
  $('#btn-home').hidden = S.screen === 'welcome';
  $('#mode-badge').textContent = CONFIG.n8nBaseUrl ? 'Conectado' : 'Modo demo (sin IA)';
  const t = $('#txt'); if (t && !S.busy) t.focus({ preventScroll: true });
}

// ---------- acciones ----------
async function safe(fn) {
  S.busy = true; S.error = null; render();
  try { await fn(); } catch (e) {
    console.error(e);
    S.error = 'No pude completar la consulta. Revisa tu conexión e inténtalo de nuevo.';
    if (S.screen === 'chat') {
      S.result = precautionResult(S.cat, ctx(), 'No hubo conexión con el servidor.');
      S.screen = 'result';
    }
  } finally { S.busy = false; render(); }
}

function applyStep(res) {
  if (res.stage === 'follow_up') {
    S.chat.push({ from: 'ia', text: res.follow_up.question });
    S.pending = { type: 'follow', ...res.follow_up, options: res.follow_up.options || [] };
    S.other = false;
  } else if (res.stage === 'summary') {
    S.chat.push({ from: 'ia', text: res.summary });
    S.pending = { type: 'summary', summary: res.summary };
  } else if (res.stage === 'result') {
    S.result = res.result; S.pending = null; S.screen = 'result';
  }
}

async function onPhoto(file) {
  if (!file) return;
  await safe(async () => {
    const res = await S.engine.photo(file);
    if (res.stage === 'quality_check') { S.quality = res.quality; S.photoUrl = null; return; }
    S.quality = null;
    if (S.photoUrl) URL.revokeObjectURL(S.photoUrl);
    S.photoUrl = URL.createObjectURL(file);
    S.chat = [];
    if (res.detected) S.chat.push({ from: 'ia', text: res.detected });
    if (res.stage === 'follow_up' || res.stage === 'summary' || res.stage === 'result') { applyStep(res); S.screen = res.stage === 'result' ? 'result' : 'chat'; return; }
    S.chat.push({ from: 'ia', text: 'Cuéntame de dónde salió este residuo y qué estabas haciendo.' });
    S.pending = { type: 'open' };
    S.screen = 'chat';
  });
}

async function send(text) {
  const v = (text || '').trim();
  if (!v) return;
  S.chat.push({ from: 'user', text: v });
  S.pending = null;
  await safe(async () => applyStep(await S.engine.answer(v)));
}

function reset() {
  S.photoUrl = null; S.quality = null; S.chat = []; S.pending = null; S.result = null; S.error = null; S.other = false;
}

document.addEventListener('click', async e => {
  const b = e.target.closest('[data-act]');
  if (!b || S.busy) return;
  const act = b.dataset.act;
  if (act === 'start') {
    await safe(async () => { S.engine = createEngine(S.cat, ctx()); await S.engine.start(); reset(); S.screen = 'photo'; });
  } else if (act === 'send') { await send($('#txt')?.value); }
  else if (act === 'opt') { await send(b.dataset.v); }
  else if (act === 'other') { S.other = true; render(); }
  else if (act === 'ok') { S.chat.push({ from: 'user', text: 'Correcto, clasificar' }); S.pending = null; await safe(async () => applyStep(await S.engine.confirm())); }
  else if (act === 'fix') {
    await S.engine.correct();
    S.chat.push({ from: 'user', text: 'Corregir' }, { from: 'ia', text: 'De acuerdo. Cuéntame otra vez de dónde salió y qué es.' });
    S.pending = { type: 'open' }; render();
  } else if (act === 'again') { reset(); S.screen = 'photo'; render(); }
  else if (act === 'mic') {
    const rec = new SR(); rec.lang = { PE: 'es-PE', CL: 'es-CL', MX: 'es-MX' }[S.country] || 'es';
    rec.onresult = ev => { const t = $('#txt'); if (t) t.value = ev.results[0][0].transcript; };
    rec.onerror = () => {}; rec.start();
  }
});

document.addEventListener('change', e => {
  const t = e.target;
  if (t.id === 'sel-country') { S.country = t.value; store.set('tr_country', t.value); }
  else if (t.id === 'sel-scope') { S.scope = t.value; store.set('tr_scope', t.value); }
  else if (t.id === 'sel-sector') { S.sector = t.value; store.set('tr_sector', t.value); }
  else if (t.id === 'f-cam' || t.id === 'f-up') { onPhoto(t.files[0]); t.value = ''; }
});

$('#btn-home').addEventListener('click', () => { reset(); S.screen = 'welcome'; render(); });

// ---------- arranque ----------
(async function init() {
  render();
  S.cat = await loadCatalogs();
  render();
  if ('serviceWorker' in navigator && location.protocol !== 'file:') navigator.serviceWorker.register('sw.js').catch(() => {});
})();
