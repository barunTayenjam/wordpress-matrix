// Phase 8 (T8.4/T8.5): dashboard token auth policy pins.
// Policy under test:
//   - token absent → open behavior + X-Matrix-Auth-Warning banner header
//   - token set → /api/* guarded (401 without, 200 with);
//     /health exempt; static + dashboard shell exempt

const EventEmitter = require('events');
const request = require('supertest');

const mockSpawn = jest.fn();

jest.mock('child_process', () => ({
  spawn: (...args) => mockSpawn(...args),
}));

const mockMatrixResponse = ({ stdout = '', code = 0 } = {}) => {
  mockSpawn.mockImplementationOnce(() => {
    const child = new EventEmitter();
    child.stdout = new EventEmitter();
    child.stderr = new EventEmitter();
    child.kill = jest.fn();
    process.nextTick(() => {
      if (stdout) child.stdout.emit('data', Buffer.from(stdout));
      child.emit('close', code);
    });
    return child;
  });
};

const loadApp = () => {
  jest.resetModules();
  return require('../app');
};

afterEach(() => {
  mockSpawn.mockReset();
  delete process.env.MATRIX_DASHBOARD_TOKEN;
});

describe('T8.4 auth policy: token absent (open mode)', () => {
  beforeEach(() => {
    process.env.MATRIX_DASHBOARD_TOKEN = '';
  });

  it('GET / returns 200 with warning banner header', async () => {
    const { app, server } = loadApp();
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
    expect(res.headers['x-matrix-auth-warning']).toMatch(/no-dashboard-token/);
    if (server.listening) server.close();
  });

  it('/api/sites stays open without a token', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify({ success: true, sites: [], services: [] }) });
    const res = await request(app).get('/api/sites');
    expect(res.status).toBe(200);
    if (server.listening) server.close();
  });
});

describe('T8.4 auth policy: token set (guarded mode)', () => {
  const TOKEN = 'test-dashboard-token-123';

  beforeEach(() => {
    process.env.MATRIX_DASHBOARD_TOKEN = TOKEN;
  });

  it('/api/sites without token → 401', async () => {
    const { app, server } = loadApp();
    const res = await request(app).get('/api/sites');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
    if (server.listening) server.close();
  });

  it('/api/sites with Bearer token → 200', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify({ success: true, sites: [{ name: 'demo', status: 'running' }], services: [] }) });
    const res = await request(app).get('/api/sites').set('Authorization', `Bearer ${TOKEN}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    if (server.listening) server.close();
  });

  it('/api/sites with wrong token → 401', async () => {
    const { app, server } = loadApp();
    const res = await request(app).get('/api/sites').set('Authorization', 'Bearer wrong-token');
    expect(res.status).toBe(401);
    if (server.listening) server.close();
  });

  it('/health is exempt', async () => {
    const { app, server } = loadApp();
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    if (server.listening) server.close();
  });

  it('static assets and dashboard shell are exempt (pinned policy)', async () => {
    const { app, server } = loadApp();
    const shell = await request(app).get('/');
    expect(shell.status).toBe(200);
    if (server.listening) server.close();
  });
});

describe('T8.5 token never logged', () => {
  it('token value does not appear in startup/middleware output', () => {
    const TOKEN = 'super-secret-token-do-not-log-42';
    process.env.MATRIX_DASHBOARD_TOKEN = TOKEN;
    const logSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
    const warnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {});
    const { createAuthMiddleware, tokenEquals } = require('../middleware/auth');
    const middleware = createAuthMiddleware({ token: TOKEN });
    // exercise middleware on a guarded path with a valid token
    const req = { path: '/api/sites', get: () => `Bearer ${TOKEN}` };
    const res = { setHeader: jest.fn(), status: jest.fn().mockReturnThis(), json: jest.fn() };
    const next = jest.fn();
    middleware(req, res, next);
    expect(next).toHaveBeenCalled();
    // startup + middleware logs must not carry the token
    const logged = [...logSpy.mock.calls, ...warnSpy.mock.calls].flat().join('\n');
    expect(logged).not.toContain(TOKEN);
    // helper sanity: equality works but is not echoed anywhere
    expect(tokenEquals(TOKEN, TOKEN)).toBe(true);
    logSpy.mockRestore();
    warnSpy.mockRestore();
  });
});
