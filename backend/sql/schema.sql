CREATE TABLE slots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    status ENUM (
        'available',
        'occupied',
        'reserved'
    ) DEFAULT 'available',
    reserved_by VARCHAR(50),
    reserved_until DATETIME,
    start_time DATETIME,
    end_time DATETIME
);

CREATE TABLE transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    slot_id INT NOT NULL,
    plate_number VARCHAR(15),
    phone VARCHAR(15),
    start_time DATETIME,
    end_time DATETIME,
    amount DECIMAL(10, 2),
    paid BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (slot_id) REFERENCES slots (id)
);

CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    slot_id INT NOT NULL,
    phone VARCHAR(15),
    amount DECIMAL(10, 2),
    mpesa_receipt VARCHAR(50),
    status ENUM (
        'pending',
        'confirmed',
        'failed'
    ) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (slot_id) REFERENCES slots (id)
);

CREATE USER 'smart_user' @'localhost' IDENTIFIED BY 'password123';

GRANT ALL PRIVILEGES ON smart_parking.* TO 'smart_user' @'localhost';

FLUSH PRIVILEGES;