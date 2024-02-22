-- Drop database if it existed previously
DROP DATABASE IF EXISTS FoodDeliveryDB;

-- Create the database
CREATE DATABASE IF NOT EXISTS FoodDeliveryDB;

-- Use the newly created database
USE FoodDeliveryDB;

-- Create Customer table
CREATE TABLE IF NOT EXISTS Customer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(9) NOT NULL,
    address TEXT NOT NULL,
    updated_at DATETIME
);

-- Create Restaurant table
CREATE TABLE IF NOT EXISTS Restaurant (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    phone VARCHAR(9) NOT NULL
);

-- Create MenuItem table
CREATE TABLE IF NOT EXISTS MenuItem (
    id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (restaurant_id) REFERENCES Restaurant(id)
);

-- Create Order table (we need to add backticks because 'Order' is a reserved keyword)
CREATE TABLE IF NOT EXISTS `Order` (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    restaurant_id INT NOT NULL,
    order_date DATETIME NOT NULL,
    status ENUM('Pending', 'Delivered') NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(id),
    FOREIGN KEY (restaurant_id) REFERENCES Restaurant(id)
);

-- Create OrderItem table
CREATE TABLE IF NOT EXISTS OrderItem (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES `Order`(id),
    FOREIGN KEY (item_id) REFERENCES MenuItem(id)
);

-- Create DeliveryPerson table
CREATE TABLE IF NOT EXISTS DeliveryPerson (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    vehicle_plate VARCHAR(20) NOT NULL,
    country VARCHAR(255) NOT NULL
);

-- Create Review table
CREATE TABLE IF NOT EXISTS Review (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    rating INT NOT NULL,
    comment TEXT,
    FOREIGN KEY (order_id) REFERENCES `Order`(id)
);

-- Create Delivery table
CREATE TABLE IF NOT EXISTS Delivery (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    delivery_person_id INT NOT NULL,
    status ENUM('In Progress', 'Completed') NOT NULL,
    address TEXT NOT NULL,
    delivery_date DATETIME NOT NULL,
    FOREIGN KEY (order_id) REFERENCES `Order`(id),
    FOREIGN KEY (delivery_person_id) REFERENCES DeliveryPerson(id)
);

-- Create Coupon table
CREATE TABLE IF NOT EXISTS Coupon (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(9) NOT NULL,
    discount DECIMAL(10, 2) NOT NULL,
    expiry_date DATETIME NOT NULL
);

-- Create PaymentTransaction table
CREATE TABLE IF NOT EXISTS PaymentTransaction (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    coupon_id INT,
    payment_date DATETIME NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    method ENUM('Card', 'Cash', 'PayPal') NOT NULL,
    FOREIGN KEY (order_id) REFERENCES `Order`(id),
    FOREIGN KEY (coupon_id) REFERENCES Coupon(id)
);

-- Create Log table
CREATE TABLE IF NOT EXISTS Log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    log_timestamp DATETIME NOT NULL,
    description TEXT
);


-- Trigger 1
-- Create a trigger to update the "updated_at" column in the Customer table
DELIMITER //
CREATE TRIGGER UpdateCustomerUpdatedAt
BEFORE UPDATE ON Customer
FOR EACH ROW
BEGIN
    -- Set the "updated_at" column to the current date and time
    SET NEW.updated_at = NOW();
END;
//
DELIMITER ;


-- Trigger 2
-- Create a trigger to log order placements
DELIMITER //
CREATE TRIGGER LogOrderPlacement
AFTER INSERT ON PaymentTransaction
FOR EACH ROW
BEGIN
    -- Insert a log entry with order details
    INSERT INTO Log (log_timestamp, description)
    VALUES (NOW(), CONCAT('Order ', NEW.order_id, ' completed for a total of $', NEW.total));
END;
//
DELIMITER ;

-- Trigger 3
-- Create a trigger to use discounts on payment transactions
DELIMITER //

CREATE TRIGGER ApplyPaymentDiscount
BEFORE INSERT ON PaymentTransaction
FOR EACH ROW
BEGIN
    DECLARE coupon_discount DECIMAL(10,2);
    DECLARE coupon_expiry_date DATETIME;

    -- Check if there is a corresponding coupon
    SELECT discount, expiry_date INTO coupon_discount, coupon_expiry_date
    FROM Coupon
    WHERE id = NEW.coupon_id;

    -- If a coupon is found and the expiry date is not in the past, apply the discount to the total
    IF coupon_discount IS NOT NULL THEN
		IF coupon_expiry_date > NOW() THEN
			SET NEW.total = GREATEST(NEW.total - coupon_discount, 0);
            SET NEW.coupon_id = null;
            
            -- Delete coupon row so it can't be used twice
            DELETE FROM Coupon WHERE id = NEW.coupon_id;
		ELSE
			-- Signal an error for expired coupons
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Error: Coupon is expired.';
		END IF;
    END IF;
END;
//

DELIMITER ;

