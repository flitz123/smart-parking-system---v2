CREATE DATABASE IF NOT EXISTS smart_parking;
USE smart_parking;

CREATE TABLE IF NOT EXISTS slots (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(10) NOT NULL,
  status ENUM('empty', 'reserved', 'occupied') DEFAULT 'empty',
  reserved_by VARCHAR(20),
  reserved_until DATETIME,
  start_time DATETIME,
  end_time DATETIME
);

CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  slot_id INT,
  plate_number VARCHAR(20),
  phone VARCHAR(20),
  start_time DATETIME,
  end_time DATETIME,
  amount DECIMAL(10,2),
  paid BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS payments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  slot_id INT,
  phone VARCHAR(32),
  amount DECIMAL(10,2),
  mpesa_receipt VARCHAR(128),
  status VARCHAR(32),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
