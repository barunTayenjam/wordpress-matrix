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

const {
  app,
  server,
  validateSiteName,
  validatePhpVersion,
  validateRelativeFilePath,
  parseJsonOutput,
} = require('../app');

afterAll((done) => {
  if (server.listening) {
    server.close(done);
  } else {
    done();
  }
});

beforeEach(() => {
  mockSpawn.mockReset();
});

describe('shared validation helpers', () => {
  it('validates site names using the real app helper', () => {
    expect(validateSiteName('mysite').valid).toBe(true);
    expect(validateSiteName('my-site_2').valid).toBe(true);
    expect(validateSiteName('123site').valid).toBe(false);
    expect(validateSiteName('my site').valid).toBe(false);
    expect(validateSiteName('frontend').valid).toBe(false);
  });

  it('validates supported PHP versions', () => {
    expect(validatePhpVersion('8.3').valid).toBe(true);
    expect(validatePhpVersion('7.3').valid).toBe(false);
  });

  it('rejects unsafe relative file paths', () => {
    expect(validateRelativeFilePath('backups/site.tar.gz', 'Backup file').valid).toBe(true);
    expect(validateRelativeFilePath('../secret.sql', 'Backup file').valid).toBe(false);
    expect(validateRelativeFilePath('/tmp/secret.sql', 'Backup file').valid).toBe(false);
  });

  it('parses JSON output from matrix', () => {
    expect(parseJsonOutput('{"success":true}')).toEqual({ success: true });
  });
});

describe('real API routes', () => {
  it('returns sites from matrix JSON output', async () => {
    mockMatrixResponse({
      stdout: JSON.stringify({
        success: true,
        sites: [{ name: 'demo', status: 'running', port: 8201 }],
        services: [{ name: 'Database', status: 'running' }],
      }),
    });

    const response = await request(app).get('/api/sites').expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.sites[0]).toMatchObject({ name: 'demo', status: 'Running' });
    expect(mockSpawn).toHaveBeenCalledWith(
      expect.stringContaining('/matrix'),
      ['list', '--json'],
      expect.objectContaining({ cwd: expect.stringContaining('wordpress-matrix') })
    );
  });

  it('rejects invalid site actions before spawning matrix', async () => {
    const response = await request(app)
      .post('/api/sites/not-real')
      .send({ siteName: 'demo' })
      .expect(400);

    expect(response.body).toEqual({
      success: false,
      error: { code: 'INVALID_ACTION', message: 'Invalid site action: not-real' },
    });
    expect(mockSpawn).not.toHaveBeenCalled();
  });

  it('rejects invalid site names before spawning matrix', async () => {
    const response = await request(app)
      .post('/api/sites/create')
      .send({ siteName: '123demo', phpVersion: '8.3' })
      .expect(400);

    expect(response.body.error.code).toBe('INVALID_NAME');
    expect(mockSpawn).not.toHaveBeenCalled();
  });

  it('runs create with validated PHP version', async () => {
    mockMatrixResponse({ stdout: 'Site created\n' });

    const response = await request(app)
      .post('/api/sites/create')
      .send({ siteName: 'demo', phpVersion: '8.3' })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(mockSpawn).toHaveBeenCalledWith(
      expect.stringContaining('/matrix'),
      ['create', 'demo', '--php-version=8.3'],
      expect.any(Object)
    );
  });

  it('rejects unsupported PHP versions on edit', async () => {
    const response = await request(app)
      .post('/api/sites/edit')
      .send({ siteName: 'demo', phpVersion: '7.3' })
      .expect(400);

    expect(response.body.error.code).toBe('INVALID_INPUT');
    expect(mockSpawn).not.toHaveBeenCalled();
  });

  it('normalizes command failures into structured errors', async () => {
    mockMatrixResponse({ stderr: 'boom', code: 1 });

    const response = await request(app)
      .post('/api/sites/start')
      .send({ siteName: 'demo' })
      .expect(500);

    expect(response.body).toEqual({
      success: false,
      error: { code: 'COMMAND_FAILED', message: 'boom' },
    });
  });

  it('allows only known environment actions and forwards safe args', async () => {
    mockMatrixResponse({ stdout: 'ok' });

    await request(app)
      .post('/api/environment/status')
      .send({ args: ['--verbose'] })
      .expect(200);

    expect(mockSpawn).toHaveBeenCalledWith(
      expect.stringContaining('/matrix'),
      ['status', '--verbose'],
      expect.any(Object)
    );
  });
});
