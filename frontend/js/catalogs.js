import { CONFIG } from './config.js';

// Catálogos públicos (contenedores, rubros, Basilea). Primero Supabase; si no hay red, el archivo incluido.
export async function loadCatalogs() {
  const bundled = await fetch('data/catalogs.json').then(r => r.json());
  if (!CONFIG.supabaseUrl || !navigator.onLine) return { ...bundled, source: 'incluido' };
  try {
    const ctl = new AbortController();
    const t = setTimeout(() => ctl.abort(), 4000);
    const h = { apikey: CONFIG.supabaseKey, Authorization: 'Bearer ' + CONFIG.supabaseKey };
    const get = p => fetch(CONFIG.supabaseUrl + '/rest/v1/' + p, { headers: h, signal: ctl.signal }).then(r => { if (!r.ok) throw new Error(r.status); return r.json(); });
    const [container_schemes, industry_sectors, sector_waste_profiles, handling_rules] = await Promise.all([
      get('container_schemes?select=country_code,scope,color,label,hazardous,verified&order=country_code,scope,color'),
      get('industry_sectors?select=id,name_es,description_es,prompt_context_es,display_order&active=eq.true&order=display_order'),
      get('sector_waste_profiles?select=sector_id,waste_name_es,examples_es,primary_basel_code,alt_basel_codes,hazard_type_ids,hazardous_typical,frequency,question_hint_es'),
      get('handling_rules?select=country_code,topic,applies_to,rule_es,verified')
    ]);
    clearTimeout(t);
    return { ...bundled, container_schemes, industry_sectors, sector_waste_profiles, handling_rules, source: 'Supabase' };
  } catch {
    return { ...bundled, source: 'incluido' };
  }
}
