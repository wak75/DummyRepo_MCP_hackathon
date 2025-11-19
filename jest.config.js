export default {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'server.js'
  ],
  testMatch: [
    '**/*.test.js'
  ],
  transform: {},
  testPathIgnorePatterns: ['/node_modules/']
};
