import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createApp, validateInput, validateCards } from './server.mjs';
import { Readable } from 'node:stream';

const token = 'test-token-longer-than-24-characters';
const input = { text: 'Modelo: representa datos y reglas del dominio.', subject: 'Software', consent: true };
const cards = { cards: [{ question: '¿Qué representa el modelo?', answer: 'Datos y reglas del dominio.' }] };

// Exercise the actual HTTP handler in memory, without binding a network port.
function request(app, body, auth = token, origin) {
  return new Promise(resolve => {
    const req = Readable.from([Buffer.from(JSON.stringify(body))]);
    req.method = 'POST'; req.url = '/cards';
    req.socket = { remoteAddress: '127.0.0.1' };
    req.headers = { 'content-type': 'application/json', authorization: `Bearer ${auth}`,
      ...(origin ? { origin } : {}) };
    const headers = new Map();
    const res = {
      writableEnded: false,
      setHeader(name, value) { headers.set(name.toLowerCase(), value); },
      writeHead(status, values) { this.status = status; Object.entries(values).forEach(([k,v]) => this.setHeader(k,v)); },
      end(text) { this.writableEnded = true; resolve({ status: this.status, headers,
        json: async () => JSON.parse(text), text: async () => text }); }
    };
    app.emit('request', req, res);
  });
}

test('Rejects missing consent, extra fields, oversized input and empty model output', () => {
  assert.throws(() => validateInput({ ...input, consent: false }));
  assert.throws(() => validateInput({ ...input, photo: 'private-image' }));
  assert.throws(() => validateInput({ ...input, text: 'a'.repeat(12001) }));
  assert.throws(() => validateCards({ cards: [] }));
  assert.throws(() => validateCards({ cards: [{ question: ' ', answer: 'A' }] }));
  assert.deepEqual(validateCards(cards), cards);
});

test('API requires auth and consent; only text reaches provider; errors are sanitized', async () => {
  let calls = 0;
  const app = createApp({ token, origins: ['https://apuntia.example'], provider: async value => {
    calls++; assert.deepEqual(Object.keys(value).sort(), ['subject', 'text']); return cards;
  }});
  assert.equal((await request(app, input, 'wrong')).status, 401);
  assert.equal((await request(app, input, token, 'https://untrusted.example')).status, 403);
  assert.equal((await request(app, { ...input, consent: false })).status, 400);
  assert.equal(calls, 0);
  const result = await request(app, input, token, 'https://apuntia.example');
  assert.equal(result.status, 200);
  assert.equal(result.headers.get('cache-control'), 'no-store');
  assert.deepEqual(await result.json(), cards);
  assert.equal(calls, 1);
  for (let i = 0; i < 4; i++) await request(app, input);
  assert.equal((await request(app, input)).status, 429);
});

test('Provider failures never expose credentials or provider details', async () => {
  const app = createApp({ token, provider: async () => { throw Error('secret API key or private text'); } });
  const result = await request(app, input);
  assert.equal(result.status, 502);
  assert.doesNotMatch(await result.text(), /secret|private/);
});
