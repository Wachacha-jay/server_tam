import mysql from 'mysql2/promise';
import fs from 'fs/promises';
import path from 'path';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load env from server/.env
dotenv.config({ path: path.join(__dirname, '../.env') });

async function runMigrations() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'business_management',
    multipleStatements: true,
  });

  console.log('🚀 Starting professional migration runner...');

  try {
    // 1. Create migrations table if not exists
    await connection.query(`
      CREATE TABLE IF NOT EXISTS _migrations (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // 2. Get executed migrations
    const [rows]: any = await connection.query('SELECT name FROM _migrations');
    const executedMigrations = new Set(rows.map((r: any) => r.name));

    // 3. Read migration files
    const migrationsDir = path.join(__dirname, '../../database/migrations');
    const files = await fs.readdir(migrationsDir);
    const migrationFiles = files
      .filter(f => f.endsWith('.sql'))
      .sort(); // Ensure order

    console.log(`Found ${migrationFiles.length} migration files.`);

    for (const file of migrationFiles) {
      if (executedMigrations.has(file)) {
        console.log(`✅ Skipping already executed: ${file}`);
        continue;
      }

      console.log(`⏳ Executing migration: ${file}...`);
      const sql = await fs.readFile(path.join(migrationsDir, file), 'utf8');

      // Split by semicolon and filter out empty statements/comments
      // NOTE: multipleStatements: true is enabled, but we might want to log progress
      try {
        await connection.query(sql);
        
        // Record migration
        await connection.query('INSERT INTO _migrations (name) VALUES (?)', [file]);
        console.log(`✨ Successfully executed: ${file}`);
      } catch (err: any) {
        console.error(`❌ Error executing ${file}:`, err.message);
        process.exit(1);
      }
    }

    console.log('\n🏁 All migrations are up to date.');
  } catch (error) {
    console.error('💥 Migration failed:', error);
    process.exit(1);
  } finally {
    await connection.end();
  }
}

runMigrations();
