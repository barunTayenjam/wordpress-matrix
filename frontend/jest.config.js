module.exports = {
  testEnvironment: 'node',
  coverageDirectory: '../tests/coverage',
  collectCoverageFrom: [
    'app.js',
    '!**/node_modules/**',
    '!**/tests/**'
  ],
  coverageThreshold: {
    global: {
      branches: 35,
      functions: 35,
      lines: 40,
      statements: 40
    }
  },
  testMatch: [
    '**/__tests__/**/*.test.js',
    '**/*.test.js'
  ],
  verbose: true,
  testTimeout: 10000,
  moduleFileExtensions: ['js', 'json'],
  roots: ['<rootDir>']
};
