import type { Config } from 'jest';

const config: Config = {
  testEnvironment: 'node',
  rootDir: 'src',
  testMatch: ['**/*.test.ts'],
  transform: {
    '^.+\\.(t|j)sx?$': '@swc/jest',
  },
};

export default config;
