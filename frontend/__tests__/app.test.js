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
  constants: { ALLOWED_SITE_ACTIONS, ALLOWED_ENV_ACTIONS },
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

describe('contract: action registry', () => {
  it('includes rest, xdebug, repair in allowed site actions', () => {
    expect(ALLOWED_SITE_ACTIONS.has('rest')).toBe(true);
    expect(ALLOWED_SITE_ACTIONS.has('xdebug')).toBe(true);
    expect(ALLOWED_SITE_ACTIONS.has('repair')).toBe(true);
  });

  it('includes all required lifecycle actions', () => {
    for (const action of ['start', 'stop', 'restart', 'create', 'remove', 'delete', 'rm']) {
      expect(ALLOWED_SITE_ACTIONS.has(action)).toBe(true);
    }
  });

  it('includes all data operations', () => {
    for (const action of ['backup', 'restore', 'export-db', 'import-db', 'clone', 'reset']) {
      expect(ALLOWED_SITE_ACTIONS.has(action)).toBe(true);
    }
  });

  it('includes info and monitoring actions', () => {
    for (const action of ['info', 'url', 'logs', 'check']) {
      expect(ALLOWED_SITE_ACTIONS.has(action)).toBe(true);
    }
  });

  it('includes all env actions for site operations', () => {
    for (const action of ['update', 'update-core', 'cache', 'cache-clear', 'search-replace', 'install']) {
      expect(ALLOWED_ENV_ACTIONS.has(action)).toBe(true);
    }
  });
});

describe('contract: new endpoint validation', () => {
  it('rejects rest endpoint with missing site name', async () => {
    const response = await request(app)
      .post('/api/sites/rest')
      .send({})
      .expect(400);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('INVALID_NAME');
  });

  it('rejects rest endpoint with invalid site name', async () => {
    const response = await request(app)
      .post('/api/sites/rest')
      .send({ siteName: '123invalid' })
      .expect(400);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('INVALID_NAME');
  });

  it('rejects xdebug endpoint with missing site name', async () => {
    const response = await request(app)
      .post('/api/sites/xdebug')
      .send({})
      .expect(400);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('INVALID_NAME');
  });

  it('rejects repair endpoint with missing site name', async () => {
    const response = await request(app)
      .post('/api/sites/repair')
      .send({})
      .expect(400);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('INVALID_NAME');
  });

  it('rejects wp-cli with missing site name', async () => {
    const response = await request(app)
      .post('/api/sites/wp-cli')
      .send({ command: 'core version' })
      .expect(400);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('INVALID_NAME');
  });

  it('rejects wp-cli with empty command', async () => {
    const response = await request(app)
      .post('/api/sites/wp-cli')
      .send({ siteName: 'demo', command: '' })
      .expect(400);
    expect(response.body.success).toBe(false);
  });

  it('rejects wp-cli with shell metacharacters', async () => {
    const response = await request(app)
      .post('/api/sites/wp-cli')
      .send({ siteName: 'demo', command: 'core version; rm -rf /' })
      .expect(400);
    expect(response.body.success).toBe(false);
    expect(response.body.error.code).toBe('INVALID_INPUT');
  });

  it('rejects wp-cli with overly long command', async () => {
    const response = await request(app)
      .post('/api/sites/wp-cli')
      .send({ siteName: 'demo', command: 'x'.repeat(501) })
      .expect(400);
    expect(response.body.success).toBe(false);
  });

  it('executes rest endpoint on valid site name', async () => {
    mockMatrixResponse({ stdout: JSON.stringify({ routes: { '/wp/v2/posts': {} } }) });

    const response = await request(app)
      .post('/api/sites/rest')
      .send({ siteName: 'demo' })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(mockSpawn).toHaveBeenCalledWith(
      expect.stringContaining('/matrix'),
      ['rest', 'demo'],
      expect.any(Object)
    );
  });

  it('executes wp-cli on valid command', async () => {
    mockMatrixResponse({ stdout: 'WP-CLI 2.10.0\n' });

    const response = await request(app)
      .post('/api/sites/wp-cli')
      .send({ siteName: 'demo', command: 'core version' })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(mockSpawn).toHaveBeenCalledWith(
      expect.stringContaining('/matrix'),
      ['wp', 'demo', 'core', 'version'],
      expect.any(Object)
    );
  });
});

describe('contract: tab visibility invariants', () => {
  it('panel-in animation does not leave content hidden', () => {
    const fs = require('fs');
    const css = fs.readFileSync(require('path').join(__dirname, '../public/css/style.css'), 'utf8');

    const revealVisible = css.match(/\.reveal\.visible\s*\{[^}]*\}/);
    expect(revealVisible).toBeTruthy();
    expect(revealVisible[0]).toContain('opacity: 1');
  });

  it('shell does not have overflow hidden (would clip dropdowns)', () => {
    const fs = require('fs');
    const css = fs.readFileSync(require('path').join(__dirname, '../public/css/style.css'), 'utf8');

    const shellRule = css.match(/\.shell\s*\{[^}]*\}/);
    expect(shellRule).toBeTruthy();
    expect(shellRule[0]).not.toContain('overflow');
  });

  it('.reveal is immediately overridable by active panel', () => {
    const fs = require('fs');
    const css = fs.readFileSync(require('path').join(__dirname, '../public/css/style.css'), 'utf8');

    const revealVisible = css.match(/\.reveal\.visible\s*\{[^}]*\}/);
    expect(revealVisible).toBeTruthy();
    expect(revealVisible[0]).toContain('opacity: 1');
    expect(revealVisible[0]).not.toContain('transform');
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
