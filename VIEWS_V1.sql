USE FoodDeliveryDB;

CREATE OR REPLACE VIEW InvoiceHeader AS
SELECT 
    o.id AS OrderID,
    o.order_date AS OrderDate,
    c.name AS CustomerName,
    c.email AS CustomerEmail,
    c.address AS CustomerAddress,
    r.name AS RestaurantName,
    r.address AS RestaurantAddress,
    SUM(oi.quantity * mi.price) AS TotalOrderAmount
FROM `Order` o
JOIN Customer c ON o.customer_id = c.id
JOIN Restaurant r ON o.restaurant_id = r.id
JOIN OrderItem oi ON o.id = oi.order_id
JOIN MenuItem mi ON oi.item_id = mi.id
GROUP BY o.id, o.order_date, c.name, c.email, c.address, r.name, r.address;

SELECT * FROM InvoiceHeader WHERE OrderID = 28;

CREATE OR REPLACE VIEW InvoiceDetails AS
SELECT 
    o.id AS OrderID,
    mi.name AS ItemName,
    oi.quantity AS Quantity,
    mi.price AS PricePerItem,
    oi.quantity * mi.price AS TotalPrice
FROM `Order` o
JOIN OrderItem oi ON o.id = oi.order_id
JOIN MenuItem mi ON oi.item_id = mi.id;

SELECT * FROM InvoiceDetails WHERE OrderID = 28;
