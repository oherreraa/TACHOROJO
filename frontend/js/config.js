// Configuración pública. Nunca pongas aquí claves secretas (service_role, claves de IA): viven solo en n8n.
export const CONFIG = {
  appVersion: '0.1.0',
  // Supabase: la clave "publishable" solo puede leer catálogos (RLS). Es pública por diseño.
  supabaseUrl: 'https://ltavdcgtlrspneukyhfz.supabase.co',
  supabaseKey: 'sb_publishable_m8TH285A_8UYSy_pMKgMaA_iTb49XdF',
  // URL base de los webhooks de n8n, por ejemplo 'https://n8n.midominio.com/webhook'.
  // Vacío = modo demo: reglas simples en el navegador, sin IA y sin enviar la foto a ningún servidor.
  n8nBaseUrl: '',
  clientKey: '' // valor de X-Client-Key registrado en api_clients (hash en la base)
};
