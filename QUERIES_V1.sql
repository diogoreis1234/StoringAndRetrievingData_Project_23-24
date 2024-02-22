USE FoodDeliveryDB;

-- F. 1.
SELECT c.name as Customer, o.order_date, menui.name as Items
FROM customer c
JOIN `order` o ON o.customer_id = c.id
JOIN orderitem oi ON oi.order_id = o.id
JOIN menuitem menui ON oi.item_id = menui.id
WHERE o.order_date > '2022-01-01' AND o.order_date < '2023-01-01';

-- F.2.
SELECT c.name AS CustomerName, SUM(pt.total) AS TotalSpent
FROM Customer c
JOIN `Order` o ON c.id = o.customer_id
JOIN PaymentTransaction pt ON o.id = pt.order_id
GROUP BY c.id
ORDER BY TotalSpent DESC
LIMIT 3;

-- F. 3.
SELECT
    CONCAT('PeriodOfSales: ', '2022-01-01', ' – ', '2025-01-01') AS PeriodOfSales,
    SUM(pt.total) AS "TotalSales",
    SUM(pt.total) / 3 AS "YearlyAverage",
    SUM(pt.total) / (3 * 12) AS "MonthlyAverage"
FROM `Order` o
JOIN PaymentTransaction pt ON o.id = pt.order_id
WHERE o.order_date BETWEEN '2022-01-01' AND '2025-01-01';



-- F. 4.
SELECT 
    dp.country AS GeographicalLocation,
    SUM(pt.total) AS TotalSales
FROM DeliveryPerson dp
JOIN Delivery dr ON dp.id = dr.delivery_person_id
JOIN `Order` o ON dr.order_id = o.id
JOIN PaymentTransaction pt ON o.id = pt.order_id
GROUP BY dp.country;

-- F.5.
SELECT DISTINCT 
    r.address AS Location
FROM `Order` o
JOIN OrderItem oi ON o.id = oi.order_id
JOIN MenuItem mi ON oi.item_id = mi.id
JOIN Restaurant r ON mi.restaurant_id = r.id
WHERE EXISTS (
    SELECT 1
    FROM Review rev
    WHERE rev.order_id = o.id
);