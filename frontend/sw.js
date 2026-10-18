// Service worker: la app abre sin conexión. Catálogos: red primero, archivo en caché como respaldo.
const V = 'tachorojo-v1';
const STATIC = ['./', 'index.html', 'css/styles.css', 'js/app.js', 'js/config.js', 'js/catalogs.js', 'js/quality.js', 'js/engine.js', 'js/engine-demo.js', 'js/engine-remote.js', 'js/result.js', 'data/catalogs.json', 'manifest.webmanifest', 'icons/icon.svg', 'icons/icon-192.png'];

self.addEventListener('install', e => { e.waitUntil(caches.open(V).then(c => c.addAll(STATIC)).then(() => self.skipWaiting())); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== V).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', e => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET') return; // fotos y webhooks nunca se cachean
  if (u.origin !== location.origin) return; // Supabase y n8n van directo a la red
  e.respondWith(
    fetch(e.request).then(r => { const copy = r.clone(); caches.open(V).then(c => c.put(e.request, copy)); return r; }).catch(() => caches.match(e.request))
  );
});
