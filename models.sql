-- Create Customers table
CREATE TABLE Customers (
                           CustomerID INT AUTO_INCREMENT PRIMARY KEY,
                           Name VARCHAR(100) NOT NULL,
                           Email VARCHAR(100) UNIQUE NOT NULL
);

-- Create Orders table
CREATE TABLE Orders (
                        OrderID INT AUTO_INCREMENT PRIMARY KEY,
                        CustomerID INT NOT NULL,
                        OrderDate DATE NOT NULL,
                        TotalAmount DECIMAL(10, 2) NOT NULL,
                        FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Create OrderDetails table
CREATE TABLE OrderDetails (
                              OrderDetailID INT AUTO_INCREMENT PRIMARY KEY,
                              OrderID INT NOT NULL,
                              ProductID INT NOT NULL,
                              Quantity INT NOT NULL,
                              Price DECIMAL(10, 2) NOT NULL,
                              FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);
