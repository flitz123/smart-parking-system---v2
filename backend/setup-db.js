const mysql = require('mysql2/promise');
require('dotenv').config();

async function setupDatabase() {
  let connection;
  try {
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASS || '',
    });

    console.log('✓ Connected to MySQL server');

    await connection.execute(`CREATE DATABASE IF NOT EXISTS ${process.env.DB_NAME || 'smart_parking'}`);
    console.log('✓ Database created/verified');

    await connection.execute(`USE ${process.env.DB_NAME || 'smart_parking'}`);

    await connection.execute(`
      CREATE TABLE IF NOT EXISTS slots (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(20) NOT NULL UNIQUE,
        status ENUM('available', 'occupied', 'reserved') DEFAULT 'available',
        reserved_by VARCHAR(50),
        reserved_until DATETIME,
        start_time DATETIME,
        end_time DATETIME,
        plate VARCHAR(15),
        phone VARCHAR(15),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      )
    `);
    console.log('✓ Slots table created/verified');

    await connection.execute(`
      CREATE TABLE IF NOT EXISTS transactions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        slot_id INT NOT NULL,
        plate_number VARCHAR(15),
        phone VARCHAR(15),
        start_time DATETIME,
        end_time DATETIME,
        amount DECIMAL(10, 2),
        paid BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (slot_id) REFERENCES slots (id)
      )
    `);
    console.log('✓ Transactions table created/verified');

    await connection.execute(`
      CREATE TABLE IF NOT EXISTS payments (
        id INT AUTO_INCREMENT PRIMARY KEY,
        slot_id INT NOT NULL,
        phone VARCHAR(15),
        amount DECIMAL(10, 2),
        mpesa_receipt VARCHAR(50),
        status ENUM('pending', 'confirmed', 'failed') DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (slot_id) REFERENCES slots (id)
      )
    `);
    console.log('✓ Payments table created/verified');

    const [rows] = await connection.execute('SELECT COUNT(*) as count FROM slots');
    if (rows[0].count === 0) {
      const sampleSlots = [
        ['A1', 'available'],
        ['A2', 'available'],
        ['A3', 'available'],
        ['B1', 'available'],
        ['B2', 'available'],
        ['B3', 'available'],
      ];

      for (const [name, status] of sampleSlots) {
        await connection.execute(
          'INSERT INTO slots (name, status) VALUES (?, ?)',
          [name, status]
        );
      }
      console.log('✓ Sample parking slots inserted');
    }

    console.log('\n✅ Database setup complete!');
    console.log('Database:', process.env.DB_NAME || 'smart_parking');
    console.log('Host:', process.env.DB_HOST || 'localhost');
    console.log('User:', process.env.DB_USER || 'root');

  } catch (error) {
    console.error('❌ Database setup failed:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

setupDatabase();
