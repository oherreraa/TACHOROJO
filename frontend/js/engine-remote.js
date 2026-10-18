// Motor real: llama a los webhooks de n8n (ver docs/ARQUITECTURA.md, sección 5). La foto y las claves de IA nunca están en el navegador.
import { CONFIG } from './config.js';
import { checkImage } from './quality.js';
import { precautionResult } from './result.js';

const STAGES = ['quality_check', 'context', 'follow_up', 'summary', 'result'];

function validate(res) {
  if (!res || typeof res !== 'object' || !STAGES.includes(res.stage)) throw new Error('Respuesta inválida');
  if (res.stage === 'follow_up' && !(res.follow_up && res.follow_up.question)) throw new Error('Falta la pregunta');
  if (res.stage === 'summary' && !res.summary) throw new Error('Falta el resumen');
  if (res.stage === 'result') {
    const r = res.result;
    if (!r || !['PELIGROSO', 'NO_PELIGROSO', 'NO_SEGURO'].includes(r.classification) || !r.container || !Array.isArray(r.actions)) throw new Error('Resultado inválido');
  }
  return res;
}

async function post(path, body, isForm) {
  const headers = { 'X-Client-Key': CONFIG.clientKey };
  if (!isForm) headers['Content-Type'] = 'application/json';
  const ctl = new AbortController();
  const t = setTimeout(() => ctl.abort(), 60000);
  try {
    const r = await fetch(CONFIG.n8nBaseUrl.replace(/\/$/, '') + path, { method: 'POST', headers, body: isForm ? body : JSON.stringify(body), signal: ctl.signal });
    if (!r.ok) throw new Error('HTTP ' + r.status);
    return await r.json();
  } finally { clearTimeout(t); }
}

// README sección 6: si el JSON es inválido se reintenta una vez; si vuelve a fallar, regla precautoria.
async function withRetry(fn, onFail) {
  try { return validate(await fn()); } catch {
    try { return validate(await fn()); } catch (e) { return onFail(e); }
  }
}

export function createRemoteEngine(cat, ctx) {
  let sessionId = null, classificationId = null;
  const fail = reason => () => ({ stage: 'result', result: precautionResult(cat, ctx, reason) });
  return {
    mode: 'remote',
    async start() {
      let hash = null;
      try { hash = localStorage.getItem('tr_device') || crypto.randomUUID(); localStorage.setItem('tr_device', hash); } catch { hash = crypto.randomUUID(); }
      const r = await post('/v1/session', { device_hash: hash, platform: navigator.userAgent.includes('Android') ? 'android' : /iPhone|iPad/.test(navigator.userAgent) ? 'ios' : 'web', app_version: CONFIG.appVersion, country: ctx.country });
      sessionId = r.session_id;
      return r;
    },
    async photo(file) {
      const quality = await checkImage(file); // primer filtro en el celular
      if (!quality.ok) return { stage: 'quality_check', quality };
      const fd = new FormData();
      fd.append('photo', file, 'residuo.jpg');
      fd.append('session_id', sessionId);
      fd.append('country', ctx.country);
      fd.append('scope', ctx.scope);
      if (ctx.sector) fd.append('sector', ctx.sector);
      const res = await withRetry(() => post('/v1/photo', fd, true), e => { throw e; });
      classificationId = res.classification_id || classificationId;
      return res;
    },
    async answer(text) {
      return withRetry(() => post('/v1/classify', { classification_id: classificationId, answer: text }), fail('No se pudo completar la consulta con el servidor.'));
    },
    async confirm() {
      return withRetry(() => post('/v1/classify', { classification_id: classificationId, confirm: true }), fail('No se pudo completar la consulta con el servidor.'));
    },
    async correct() { /* el servidor conserva el historial; el usuario vuelve a contar */ }
  };
}
