// Wiring tests: dashboard routes over the roadmap CLI features
// (Phase 1-8 backend commands exposed via frontend/app.js).
// Harness mirrors app.test.js: mockSpawn returns the CLI's documented JSON shape.

const EventEmitter = require('events');
const request = require('supertest');

const mockSpawn = jest.fn();

jest.mock('child_process', () => ({
  spawn: (...args) => mockSpawn(...args),
}));

const mockMatrixResponse = ({ stdout = '', stderr = '', code = 0 } = {}) => {
  mockSpawn.mockImplementationOnce(() => {
    const child = new EventEmitter();
    child.stdout = new EventEmitter();
    child.stderr = new EventEmitter();
    child.kill = jest.fn();
    process.nextTick(() => {
      if (stdout) child.stdout.emit('data', Buffer.from(stdout));
      if (stderr) child.stderr.emit('data', Buffer.from(stderr));
      child.emit('close', code);
    });
    return child;
  });
};

// Long-lived child for share: emits URL line, stays open until killed.
const mockShareChild = (urlLine) => {
  const child = new EventEmitter();
  child.stdout = new EventEmitter();
  child.stderr = new EventEmitter();
  child.kill = jest.fn(() => child.emit('close', 0));
  process.nextTick(() => {
    child.stdout.emit('data', Buffer.from(`2026-10-12 INFO | ${urlLine}\n`));
  });
  return child;
};

const loadApp = () => {
  jest.resetModules();
  return require('../app');
};

afterEach(() => {
  mockSpawn.mockReset();
});

describe('W1 GET /api/presets', () => {
  it('returns the preset list from matrix preset --json', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify({ success: true, presets: [{ name: 'woocommerce', description: 'WooCommerce with starter theme' }] }) });
    const res = await request(app).get('/api/presets');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.presets[0].name).toBe('woocommerce');
    expect(mockSpawn).toHaveBeenCalledWith(expect.any(String), ['preset', '--json'], expect.anything());
    if (server.listening) server.close();
  });
});

describe('W2 create with roadmap flags', () => {
  it('spawns matrix create with --multisite, --wp-version and --preset', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: 'created' });
    const res = await request(app)
      .post('/api/sites/create')
      .send({ siteName: 'demo', phpVersion: '8.3', multisite: 'subdirectory', wpVersion: '6.4', preset: 'woocommerce' });
    expect(res.status).toBe(200);
    const args = mockSpawn.mock.calls[0][1];
    expect(args).toEqual(['create', 'demo', '--php-version=8.3', '--multisite=subdirectory', '--wp-version=6.4', '--preset=woocommerce']);
    if (server.listening) server.close();
  });

  it('rejects an invalid multisite mode before spawning', async () => {
    const { app, server } = loadApp();
    const res = await request(app)
      .post('/api/sites/create')
      .send({ siteName: 'demo', phpVersion: '8.3', multisite: 'bogus' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVALID_INPUT');
    expect(mockSpawn).not.toHaveBeenCalled();
    if (server.listening) server.close();
  });

  it('rejects an invalid wp version before spawning', async () => {
    const { app, server } = loadApp();
    const res = await request(app)
      .post('/api/sites/create')
      .send({ siteName: 'demo', phpVersion: '8.3', wpVersion: '4.0' });
    expect(res.status).toBe(400);
    expect(mockSpawn).not.toHaveBeenCalled();
    if (server.listening) server.close();
  });

  it('rejects a preset name with path traversal before spawning', async () => {
    const { app, server } = loadApp();
    const res = await request(app)
      .post('/api/sites/create')
      .send({ siteName: 'demo', phpVersion: '8.3', preset: '../evil' });
    expect(res.status).toBe(400);
    expect(mockSpawn).not.toHaveBeenCalled();
    if (server.listening) server.close();
  });
});

describe('W3 POST /api/sites/ssl', () => {
  it('derives the https url from https_port and returns cert source', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify({ success: true, site: 'demo', http_port: 8201, https_port: 9201, cert_source: 'mkcert', fingerprint: 'SHA256:abc' }) });
    const res = await request(app).post('/api/sites/ssl').send({ siteName: 'demo' });
    expect(res.status).toBe(200);
    expect(res.body.url).toBe('https://localhost:9201');
    expect(res.body.certSource).toBe('mkcert');
    expect(mockSpawn.mock.calls[0][1]).toEqual(['ssl', 'demo', '--json']);
    if (server.listening) server.close();
  });

  it('passes --revoke and reports revoked', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify({ success: true, site: 'demo', revoked: true }) });
    const res = await request(app).post('/api/sites/ssl').send({ siteName: 'demo', revoke: true });
    expect(res.status).toBe(200);
    expect(res.body.revoked).toBe(true);
    expect(mockSpawn.mock.calls[0][1]).toEqual(['ssl', 'demo', '--revoke', '--json']);
    if (server.listening) server.close();
  });
});

describe('W4 POST /api/sites/domain', () => {
  it('always passes --yes and an explicit hostname', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify({ success: true, site: 'demo', hostname: 'demo.test' }) });
    const res = await request(app).post('/api/sites/domain').send({ siteName: 'demo', hostname: 'demo.test' });
    expect(res.status).toBe(200);
    expect(res.body.hostname).toBe('demo.test');
    expect(mockSpawn.mock.calls[0][1]).toEqual(['domain', 'demo', 'demo.test', '--yes', '--json']);
    if (server.listening) server.close();
  });

  it('rejects an invalid hostname', async () => {
    const { app, server } = loadApp();
    const res = await request(app).post('/api/sites/domain').send({ siteName: 'demo', hostname: 'bad host!' });
    expect(res.status).toBe(400);
    expect(mockSpawn).not.toHaveBeenCalled();
    if (server.listening) server.close();
  });
});

describe('W5 GET /api/doctor', () => {
  it('returns rows even when doctor exits 1 (any check failed)', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ code: 1, stdout: JSON.stringify([{ check: 'ports', status: 'fail', detail: '8500 busy' }, { check: 'env_file', status: 'ok', detail: '' }]) });
    const res = await request(app).get('/api/doctor');
    expect(res.status).toBe(200);
    expect(res.body.checks).toHaveLength(2);
    expect(res.body.checks[0].status).toBe('fail');
    if (server.listening) server.close();
  });
});

describe('W6 bundle export/import', () => {
  it('export-bundle passes --out and returns bundle path + sha', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify({ success: true, site: 'demo', bundle: 'backups/demo-bundle.tar.gz', db_dump_sha256: 'abc123' }) });
    const res = await request(app).post('/api/sites/export-bundle').send({ siteName: 'demo', outputFile: 'backups/demo-bundle.tar.gz' });
    expect(res.status).toBe(200);
    expect(res.body.bundle).toBe('backups/demo-bundle.tar.gz');
    expect(mockSpawn.mock.calls[0][1]).toEqual(['export', 'demo', '--out', 'backups/demo-bundle.tar.gz', '--json']);
    if (server.listening) server.close();
  });

  it('import-bundle validates the bundle path and passes --yes with force', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify({ success: true, site: 'newsite', 'imported-from': 'demo' }) });
    const res = await request(app)
      .post('/api/sites/import-bundle')
      .send({ bundleFile: 'backups/demo-bundle.tar.gz', destName: 'newsite', force: true });
    expect(res.status).toBe(200);
    expect(res.body.importedFrom).toBe('demo');
    expect(mockSpawn.mock.calls[0][1]).toEqual(['import', 'backups/demo-bundle.tar.gz', 'newsite', '--yes', '--json']);
    if (server.listening) server.close();
  });

  it('import-bundle rejects path traversal', async () => {
    const { app, server } = loadApp();
    const res = await request(app)
      .post('/api/sites/import-bundle')
      .send({ bundleFile: '../outside.tar.gz', destName: 'newsite' });
    expect(res.status).toBe(400);
    expect(mockSpawn).not.toHaveBeenCalled();
    if (server.listening) server.close();
  });
});

describe('W7 POST /api/sites/compat', () => {
  it('builds --wp-versions csv and returns the bare row array', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: JSON.stringify([{ site: 'demo', php: '8.3', wp: '6.4', result: 'ok' }, { site: 'demo', php: '8.3', wp: '6.5', result: 'ok' }]) });
    const res = await request(app).post('/api/sites/compat').send({ siteName: 'demo', wpVersions: ['6.4', '6.5'] });
    expect(res.status).toBe(200);
    expect(res.body.rows).toHaveLength(2);
    expect(mockSpawn.mock.calls[0][1]).toEqual(['test', 'demo', '--wp-versions=6.4,6.5', '--json']);
    if (server.listening) server.close();
  });

  it('rejects a bad version list before spawning', async () => {
    const { app, server } = loadApp();
    const res = await request(app).post('/api/sites/compat').send({ siteName: 'demo', wpVersions: ['banana'] });
    expect(res.status).toBe(400);
    expect(mockSpawn).not.toHaveBeenCalled();
    if (server.listening) server.close();
  });
});

describe('W8 cron dispatch', () => {
  it('routes op=install to matrix cron-install', async () => {
    const { app, server } = loadApp();
    mockMatrixResponse({ stdout: 'installed' });
    const res = await request(app).post('/api/sites/cron').send({ siteName: 'demo', op: 'install' });
    expect(res.status).toBe(200);
    expect(mockSpawn.mock.calls[0][1]).toEqual(['cron-install', 'demo']);
    if (server.listening) server.close();
  });

  it('rejects an unknown op', async () => {
    const { app, server } = loadApp();
    const res = await request(app).post('/api/sites/cron').send({ siteName: 'demo', op: 'nuke' });
    expect(res.status).toBe(400);
    expect(mockSpawn).not.toHaveBeenCalled();
    if (server.listening) server.close();
  });
});

describe('W9 share lifecycle', () => {
  it('start extracts the tunnel URL from streamed stdout', async () => {
    const { app, server } = loadApp();
    mockSpawn.mockImplementationOnce(() => mockShareChild('https://demo-site.trycloudflare.com'));
    const res = await request(app).post('/api/sites/share').send({ siteName: 'demo' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.url).toBe('https://demo-site.trycloudflare.com');
    if (server.listening) server.close();
  });

  it('second share for the same site → 409', async () => {
    const { app, server } = loadApp();
    mockSpawn.mockImplementation(() => mockShareChild('https://again.trycloudflare.com'));
    await request(app).post('/api/sites/share').send({ siteName: 'demo' });
    const second = await request(app).post('/api/sites/share').send({ siteName: 'demo' });
    expect(second.status).toBe(409);
    expect(second.body.error.code).toBe('SHARE_ALREADY_ACTIVE');
    if (server.listening) server.close();
  });

  it('share-stop kills the child and clears the slot', async () => {
    const { app, server } = loadApp();
    let child;
    mockSpawn.mockImplementationOnce(() => (child = mockShareChild('https://killme.trycloudflare.com')));
    await request(app).post('/api/sites/share').send({ siteName: 'demo' });
    const stop = await request(app).post('/api/sites/share-stop').send({ siteName: 'demo' });
    expect(stop.status).toBe(200);
    expect(stop.body.stopped).toBe(true);
    expect(child.kill).toHaveBeenCalled();
    // slot cleared: stopping again → 404
    const again = await request(app).post('/api/sites/share-stop').send({ siteName: 'demo' });
    expect(again.status).toBe(404);
    if (server.listening) server.close();
  });

  it('share-stop with no active tunnel → 404', async () => {
    const { app, server } = loadApp();
    const res = await request(app).post('/api/sites/share-stop').send({ siteName: 'ghost' });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('SHARE_NOT_ACTIVE');
    if (server.listening) server.close();
  });
});
