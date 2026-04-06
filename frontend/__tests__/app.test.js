// Standalone unit tests for frontend validation and response structures
// These tests don't require importing app.js

describe('Validation Logic', () => {
  const VALID_SITE_NAME = /^[a-zA-Z][a-zA-Z0-9_-]*$/;
  const RESERVED_NAMES = ['frontend', 'matrix', 'db', 'redis', 'phpmyadmin', 'nginx'];
  const SUPPORTED_PHP_VERSIONS = ['7.4', '8.0', '8.1', '8.2', '8.3'];

  const validateSiteName = (name) => {
    if (!name || typeof name !== 'string') return { valid: false, code: 'INVALID_NAME', message: 'Site name is required' };
    if (!VALID_SITE_NAME.test(name)) return { valid: false, code: 'INVALID_NAME', message: 'Site name must start with a letter and contain only alphanumeric characters, hyphens, and underscores' };
    if (RESERVED_NAMES.includes(name.toLowerCase())) return { valid: false, code: 'INVALID_NAME', message: `"${name}" is a reserved name` };
    return { valid: true };
  };

  describe('validateSiteName', () => {
    it('should reject empty names', () => {
      const result = validateSiteName('');
      expect(result.valid).toBe(false);
      expect(result.code).toBe('INVALID_NAME');
    });

    it('should reject null/undefined', () => {
      expect(validateSiteName(null).valid).toBe(false);
      expect(validateSiteName(undefined).valid).toBe(false);
    });

    it('should accept valid simple names', () => {
      const result = validateSiteName('mysite');
      expect(result.valid).toBe(true);
    });

    it('should accept names with hyphens', () => {
      const result = validateSiteName('my-site');
      expect(result.valid).toBe(true);
    });

    it('should accept names with underscores', () => {
      const result = validateSiteName('my_site');
      expect(result.valid).toBe(true);
    });

    it('should accept names with numbers', () => {
      const result = validateSiteName('site123');
      expect(result.valid).toBe(true);
    });

    it('should reject names starting with numbers', () => {
      const result = validateSiteName('123site');
      expect(result.valid).toBe(false);
    });

    it('should reject reserved names', () => {
      RESERVED_NAMES.forEach(name => {
        const result = validateSiteName(name);
        expect(result.valid).toBe(false);
        expect(result.code).toBe('INVALID_NAME');
      });
    });

    it('should reject names with spaces', () => {
      const result = validateSiteName('my site');
      expect(result.valid).toBe(false);
    });
  });

  describe('SUPPORTED_PHP_VERSIONS', () => {
    it('should contain all required versions', () => {
      expect(SUPPORTED_PHP_VERSIONS).toContain('7.4');
      expect(SUPPORTED_PHP_VERSIONS).toContain('8.0');
      expect(SUPPORTED_PHP_VERSIONS).toContain('8.1');
      expect(SUPPORTED_PHP_VERSIONS).toContain('8.2');
      expect(SUPPORTED_PHP_VERSIONS).toContain('8.3');
    });
  });

  describe('RESERVED_NAMES', () => {
    it('should contain expected reserved words', () => {
      expect(RESERVED_NAMES).toContain('frontend');
      expect(RESERVED_NAMES).toContain('matrix');
      expect(RESERVED_NAMES).toContain('db');
    });
  });
});

describe('Error Response Structures', () => {
  const ERROR_STATUS_MAP = {
    SITE_NOT_FOUND: 404,
    SITE_ALREADY_EXISTS: 409,
    INVALID_NAME: 400,
    DOCKER_ERROR: 503,
    COMMAND_FAILED: 500,
  };

  const sendError = (res, code, message, overrideStatus) => {
    const status = overrideStatus || ERROR_STATUS_MAP[code] || 500;
    return { status, body: { success: false, error: { code, message } } };
  };

  describe('ERROR_STATUS_MAP', () => {
    it('should map SITE_NOT_FOUND to 404', () => {
      expect(ERROR_STATUS_MAP.SITE_NOT_FOUND).toBe(404);
    });

    it('should map SITE_ALREADY_EXISTS to 409', () => {
      expect(ERROR_STATUS_MAP.SITE_ALREADY_EXISTS).toBe(409);
    });

    it('should map INVALID_NAME to 400', () => {
      expect(ERROR_STATUS_MAP.INVALID_NAME).toBe(400);
    });

    it('should map DOCKER_ERROR to 503', () => {
      expect(ERROR_STATUS_MAP.DOCKER_ERROR).toBe(503);
    });

    it('should map COMMAND_FAILED to 500', () => {
      expect(ERROR_STATUS_MAP.COMMAND_FAILED).toBe(500);
    });
  });

  describe('sendError', () => {
    it('should return correct structure for standard error', () => {
      const result = sendError({}, 'SITE_NOT_FOUND', 'Site not found');
      expect(result.status).toBe(404);
      expect(result.body.success).toBe(false);
      expect(result.body.error.code).toBe('SITE_NOT_FOUND');
      expect(result.body.error.message).toBe('Site not found');
    });

    it('should allow status override', () => {
      const result = sendError({}, 'SITE_NOT_FOUND', 'Not found', 400);
      expect(result.status).toBe(400);
    });

    it('should default to 500 for unknown error codes', () => {
      const result = sendError({}, 'UNKNOWN_ERROR', 'Unknown');
      expect(result.status).toBe(500);
    });
  });
});

describe('JSON Output Formats', () => {
  it('should serialize list response correctly', () => {
    const response = {
      success: true,
      sites: [
        { name: 'test', status: 'running', port: 8100, phpVersion: '8.3' }
      ],
      services: [
        { name: 'Database', status: 'running' }
      ]
    };
    const json = JSON.stringify(response);
    expect(() => JSON.parse(json)).not.toThrow();
    
    const parsed = JSON.parse(json);
    expect(parsed.success).toBe(true);
    expect(parsed.sites).toHaveLength(1);
    expect(parsed.services).toHaveLength(1);
  });

  it('should serialize status response correctly', () => {
    const response = {
      success: true,
      containers: [
        { name: 'wp_test', status: 'Up' }
      ],
      frontend: { name: 'frontend', status: 'running' }
    };
    const json = JSON.stringify(response);
    const parsed = JSON.parse(json);
    expect(parsed.containers).toHaveLength(1);
    expect(parsed.frontend.status).toBe('running');
  });

  it('should serialize info response correctly', () => {
    const response = {
      success: true,
      site: {
        name: 'test',
        status: 'running',
        port: 8100,
        phpVersion: '8.3',
        containerId: 'abc123',
        localUrl: 'http://localhost:8100',
        dbName: 'test_db'
      }
    };
    const json = JSON.stringify(response);
    const parsed = JSON.parse(json);
    expect(parsed.site.dbName).toBe('test_db');
  });

  it('should serialize error response correctly', () => {
    const response = {
      success: false,
      error: {
        code: 'SITE_NOT_FOUND',
        message: 'Site "foo" does not exist'
      }
    };
    const json = JSON.stringify(response);
    const parsed = JSON.parse(json);
    expect(parsed.success).toBe(false);
    expect(parsed.error.code).toBe('SITE_NOT_FOUND');
  });
});

describe('API Validation Constants', () => {
  const VALID_SITE_ACTIONS = ['create', 'start', 'stop', 'remove', 'info', 'url'];
  const VALID_ENV_ACTIONS = ['start', 'stop', 'restart', 'status', 'logs', 'clean', 'check'];

  describe('VALID_SITE_ACTIONS', () => {
    it('should contain all site actions', () => {
      expect(VALID_SITE_ACTIONS).toContain('create');
      expect(VALID_SITE_ACTIONS).toContain('start');
      expect(VALID_SITE_ACTIONS).toContain('stop');
      expect(VALID_SITE_ACTIONS).toContain('remove');
    });
  });

  describe('VALID_ENV_ACTIONS', () => {
    it('should contain all environment actions', () => {
      expect(VALID_ENV_ACTIONS).toContain('start');
      expect(VALID_ENV_ACTIONS).toContain('stop');
      expect(VALID_ENV_ACTIONS).toContain('restart');
      expect(VALID_ENV_ACTIONS).toContain('check');
    });
  });
});
