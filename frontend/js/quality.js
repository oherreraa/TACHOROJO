// Control de calidad de la foto en el celular, antes de clasificar: tamaño, luz, contraste y nitidez.
async function toBitmap(file) {
  if (window.createImageBitmap) {
    try { return await createImageBitmap(file); } catch { /* sigue con Image */ }
  }
  const url = URL.createObjectURL(file);
  try {
    const img = new Image();
    img.src = url;
    await img.decode();
    return img;
  } finally { URL.revokeObjectURL(url); }
}

export async function checkImage(file) {
  const src = await toBitmap(file);
  const w0 = src.width, h0 = src.height;
  if (Math.min(w0, h0) < 240) return { ok: false, issue: 'La foto es muy pequeña.', tip: 'Acércate al residuo y usa la cámara trasera.', metrics: { w0, h0 } };
  const scale = Math.min(1, 320 / Math.max(w0, h0));
  const w = Math.max(8, Math.round(w0 * scale)), h = Math.max(8, Math.round(h0 * scale));
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  const ctx = c.getContext('2d', { willReadFrequently: true });
  ctx.drawImage(src, 0, 0, w, h);
  const d = ctx.getImageData(0, 0, w, h).data;
  const g = new Float32Array(w * h);
  let sum = 0;
  for (let i = 0; i < w * h; i++) { g[i] = 0.299 * d[4 * i] + 0.587 * d[4 * i + 1] + 0.114 * d[4 * i + 2]; sum += g[i]; }
  const mean = sum / (w * h);
  let v = 0;
  for (let i = 0; i < g.length; i++) v += (g[i] - mean) ** 2;
  const std = Math.sqrt(v / g.length);
  // Varianza del laplaciano: baja = borrosa
  let lsum = 0, lsq = 0, n = 0;
  for (let y = 1; y < h - 1; y++) for (let x = 1; x < w - 1; x++) {
    const i = y * w + x;
    const l = 4 * g[i] - g[i - 1] - g[i + 1] - g[i - w] - g[i + w];
    lsum += l; lsq += l * l; n++;
  }
  const lap = lsq / n - (lsum / n) ** 2;
  const metrics = { mean: Math.round(mean), std: Math.round(std), sharpness: Math.round(lap) };
  if (mean < 45) return { ok: false, issue: 'Hay poca luz.', tip: 'Prueba junto a una ventana o con más iluminación.', metrics };
  if (mean > 225) return { ok: false, issue: 'Hay demasiada luz o un reflejo.', tip: 'Evita el flash y el contraluz.', metrics };
  if (std < 14) return { ok: false, issue: 'No se distingue el residuo.', tip: 'Acércate a 30–50 cm y deja un fondo despejado.', metrics };
  if (lap < 20) return { ok: false, issue: 'La foto está borrosa.', tip: 'Mantén quieto el celular y toca la pantalla para enfocar.', metrics };
  return { ok: true, issue: null, tip: null, metrics };
}
