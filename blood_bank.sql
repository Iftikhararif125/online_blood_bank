-- =================================================================
-- Blood Bank Management System - MySQL Database Schema
-- Optimized for Donor Tracking, Inventory, and Hospital Requests
-- =================================================================
create database blood_bank;
use blood_bank;
-- 1. Donors Table
-- Stores personal and biological information of individuals who donate.
CREATE TABLE donors (
    donor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    date_of_birth DATE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    address TEXT,
    last_donation_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Blood Inventory Table
-- Tracks the current stock levels for each blood group.
CREATE TABLE blood_inventory (
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') PRIMARY KEY,
    units_available INT DEFAULT 0 CHECK (units_available >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 3. Donation Events Table
-- Records every specific instance of blood donation.
CREATE TABLE donations (
    donation_id INT AUTO_INCREMENT PRIMARY KEY,
    donor_id INT NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    units_donated INT DEFAULT 1,
    donation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATE NOT NULL, -- Blood typically expires in 35-42 days
    hemoglobin_level DECIMAL(4,2),
    blood_pressure VARCHAR(20),
    FOREIGN KEY (donor_id) REFERENCES donors(donor_id) ON DELETE CASCADE
);

-- 4. Hospitals / Recipients Table
-- Stores details of entities that request blood from the bank.
CREATE TABLE hospitals (
    hospital_id INT AUTO_INCREMENT PRIMARY KEY,
    hospital_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    address TEXT,
    city VARCHAR(50)
);

-- 5. Blood Requests Table
-- Tracks requests made by hospitals.
CREATE TABLE blood_requests (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    hospital_id INT NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-') NOT NULL,
    units_requested INT NOT NULL,
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    urgency ENUM('Normal', 'High', 'Emergency') DEFAULT 'Normal',
    status ENUM('Pending', 'Approved', 'Distributed', 'Rejected') DEFAULT 'Pending',
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

-- 6. Blood Distribution Table
-- Logs the actual fulfillment of requests.
CREATE TABLE blood_distribution (
    distribution_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    distribution_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    units_distributed INT NOT NULL,
    authorized_by VARCHAR(100),
    FOREIGN KEY (request_id) REFERENCES blood_requests(request_id)
);

-- 7. Reminders Table
-- Automates notification tracking for future donations.
CREATE TABLE donation_reminders (
    reminder_id INT AUTO_INCREMENT PRIMARY KEY,
    donor_id INT NOT NULL,
    reminder_date DATE NOT NULL,
    message_status ENUM('Sent', 'Pending', 'Failed') DEFAULT 'Pending',
    FOREIGN KEY (donor_id) REFERENCES donors(donor_id)
);

-- SELECT * FROM blood_inventory;  -- if you wanna check then bcause already A+ included in blood_inventory

-- =================================================================
-- Initial Data for Blood Inventory
-- =================================================================
INSERT IGNORE INTO blood_inventory (blood_group, units_available) VALUES 
('A+', 0), ('A-', 0), ('B+', 0), ('B-', 0), 
('AB+', 0), ('AB-', 0), ('O+', 0), ('O-', 0);


-- =================================================================
-- Sample Trigger: Update Inventory on New Donation
-- =================================================================
DELIMITER //
CREATE TRIGGER after_donation_insert
AFTER INSERT ON donations
FOR EACH ROW
BEGIN
    UPDATE blood_inventory 
    SET units_available = units_available + NEW.units_donated
    WHERE blood_group = NEW.blood_group;
    
    UPDATE donors 
    SET last_donation_date = DATE(NEW.donation_date)
    WHERE donor_id = NEW.donor_id;
END;
//
DELIMITER ;