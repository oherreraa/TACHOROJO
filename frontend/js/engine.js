import { CONFIG } from './config.js';
import { createDemoEngine } from './engine-demo.js';
import { createRemoteEngine } from './engine-remote.js';

export function createEngine(cat, ctx) {
  return CONFIG.n8nBaseUrl ? createRemoteEngine(cat, ctx) : createDemoEngine(cat, ctx);
}
