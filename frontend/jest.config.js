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
      branches: 70,
      functions: 70,
      lines: 80,
      statements: 80
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
