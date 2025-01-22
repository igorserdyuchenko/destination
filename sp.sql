        DELIMITER $$

        CREATE PROCEDURE GetCustomerOrderDetails(
            IN input_customer_id INT,
            IN start_date DATE,
            IN end_date DATE
        )
        BEGIN
            -- Retrieve orders and their details for the specified customer and date range
            SELECT
                c.CustomerID,
                c.Name AS CustomerName,
                o.OrderID,
                o.OrderDate,
                o.TotalAmount,
                od.ProductID,
                od.Quantity,
                od.Price,
                (od.Quantity * od.Price) AS LineTotal
            FROM Customers c
                     INNER JOIN Orders o ON c.CustomerID = o.CustomerID
                     INNER JOIN OrderDetails od ON o.OrderID = od.OrderID
            WHERE c.CustomerID = input_customer_id
              AND o.OrderDate BETWEEN start_date AND end_date
            ORDER BY o.OrderDate DESC;
                    END$$

                    DELIMITER ;
