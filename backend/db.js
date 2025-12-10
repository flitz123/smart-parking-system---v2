const mysql = require('mysql2/promise');
const Database = require('better-sqlite3');
const path = require('path');
require('dotenv').config();

const useMySQL = process.env.DB_TYPE === 'mysql' || process.env.NODE_ENV === 'production';

let pool = null;
let db = null;

if (useMySQL) {
  pool = mysql.createPool({
    host: 'localhost',
    user: 'smart_user',
    password: 'password123',
    database: 'smart_parking',
    waitForConnections: true,
    connectionLimit: 10,
  });

  module.exports = pool;
} else {
  const dbPath = path.join(__dirname, 'parking.db');
  db = new Database(dbPath);

  db.pragma('foreign_keys = ON');

  db.exec(`
    CREATE TABLE IF NOT EXISTS slots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      status TEXT DEFAULT 'available' CHECK(status IN ('available', 'occupied', 'reserved')),
      reserved_by TEXT,
      reserved_until TEXT,
      start_time TEXT,
      end_time TEXT,
      plate TEXT,
      phone TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      slot_id INTEGER NOT NULL,
      plate_number TEXT,
      phone TEXT,
      start_time TEXT,
      end_time TEXT,
      amount REAL,
      paid INTEGER DEFAULT 0,
      FOREIGN KEY (slot_id) REFERENCES slots (id)
    );

    CREATE TABLE IF NOT EXISTS payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      slot_id INTEGER NOT NULL,
      phone TEXT,
      amount REAL,
      mpesa_receipt TEXT,
      status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'confirmed', 'failed')),
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (slot_id) REFERENCES slots (id)
    );
  `);

  const count = db.prepare('SELECT COUNT(*) as cnt FROM slots').get().cnt;
  if (count === 0) {
    const insert = db.prepare('INSERT INTO slots (name, status) VALUES (?, ?)');
    const sampleSlots = [
      ['A1', 'available'],
      ['A2', 'available'],
      ['A3', 'available'],
      ['B1', 'available'],
      ['B2', 'available'],
      ['B3', 'available'],
    ];

    db.transaction(() => {
      for (const [name, status] of sampleSlots) {
        insert.run(name, status);
      }
    })();

    console.log(`✓ SQLite database initialized at ${dbPath}`);
  }

  class SQLitePool {
    async query(sql, params = []) {
      try {
        const sanitize = (p) => {
          if (p === undefined) return null;
          if (p instanceof Date) return p.toISOString();
          return p;
        };
        const safeParams = Array.isArray(params) ? params.map(sanitize) : [sanitize(params)];
        if (sql.toUpperCase().startsWith('SELECT')) {
          const stmt = db.prepare(sql);
          const rows = stmt.all(...safeParams);
          return [rows];
        } else {
          const stmt = db.prepare(sql);
          const info = stmt.run(...safeParams);
          return [{ affectedRows: info.changes, insertId: info.lastInsertRowid }];
        }
      } catch (err) {
        console.error('SQLite query error', { sql, params, safeParams, err: err && err.message });
        throw err;
      }
    }

    async execute(sql, params = []) {
      return this.query(sql, params);
    }

    async getConnection() {
      return this;
    }

    async release() {
    }
  }

  pool = new SQLitePool();
  module.exports = pool;
}
