import 'dotenv/config';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: './prisma/schema/',
  migrations: {
    path: './prisma/migration',
  },
  datasource: {
    url: process.env.DATABASE_URL,
  },
});
