SET FOREIGN_KEY_CHECKS = 0;

-- Drop others just to be safe
DROP TABLE IF EXISTS REVIEWS;
DROP TABLE IF EXISTS ORDERS_PAYMENT;
DROP TABLE IF EXISTS BOOK_ORDERS;
DROP TABLE IF EXISTS WRITTEN_BY;
DROP TABLE IF EXISTS BELONG_CATEGORIES;
DROP TABLE IF EXISTS MANAGE_STOCK;
DROP TABLE IF EXISTS MANAGE_ORDER;
DROP TABLE IF EXISTS ORDERS;
DROP TABLE IF EXISTS AUTHORS;
DROP TABLE IF EXISTS CATEGORIES;
DROP TABLE IF EXISTS ADMINS;
DROP TABLE IF EXISTS CUSTOMERS;
DROP TABLE IF EXISTS BOOKS;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE AUTHORS (
  Author_id INT PRIMARY KEY,
  Name VARCHAR(64) NOT NULL,
  Nationality VARCHAR(64) NOT NULL,
  Biography VARCHAR(1024) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE BOOKS (
  book_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
  Isbn CHAR(10) NOT NULL,
  Title VARCHAR(64) NOT NULL, 
  Edition CHAR(3) NOT NULL,
  Price DECIMAL(8,2) NOT NULL,
  Pub_year INT NOT NULL,
  Stock_quant INT NOT NULL,
  UNIQUE KEY idx_isbn (Isbn)  /* <--- THIS LINE IS REQUIRED FOR FOREIGN KEYS TO WORK */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


CREATE TABLE WRITTEN_BY (
  Isbn CHAR(10) NOT NULL,
  Author_id INT NOT NULL,
  PRIMARY KEY (Isbn, Author_id),
  CONSTRAINT FK_ISBN FOREIGN KEY (Isbn) REFERENCES BOOKS(Isbn) ON DELETE CASCADE,
  CONSTRAINT FK_AUTHOR_ID FOREIGN KEY (Author_id) REFERENCES AUTHORS(Author_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE CATEGORIES (
  Category_id INT PRIMARY KEY,
  Category VARCHAR(32) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE BELONG_CATEGORIES (
  Isbn CHAR(10) NOT NULL,
  Category_id INT NOT NULL,
  PRIMARY KEY (Isbn, Category_id),
  CONSTRAINT FK_ISBN_BC FOREIGN KEY (Isbn) REFERENCES BOOKS(Isbn) ON DELETE CASCADE,
  CONSTRAINT FK_CATEGORY_ID_BC FOREIGN KEY (Category_id) REFERENCES CATEGORIES(Category_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE CUSTOMERS (
  Cust_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
  First_name VARCHAR(16),
  Last_name VARCHAR(16),
  User_name VARCHAR(32) UNIQUE, 
  Address VARCHAR(64),
  Phone_num VARCHAR(12),
  Reg_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  Password VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ORDERS (
  Order_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, 
  Cust_id INT UNSIGNED,
  Order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  Status VARCHAR(32) NOT NULL,
  Total_amt INT,
  CONSTRAINT FK_CUST_ID_ORDERS FOREIGN KEY(Cust_id) REFERENCES CUSTOMERS(Cust_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE BOOK_ORDERS (
  Order_id INT UNSIGNED,
  Isbn CHAR(10),
  PRIMARY KEY (Order_id, Isbn),
  CONSTRAINT FK_ORDER_ID_BO FOREIGN KEY(Order_id) REFERENCES ORDERS(Order_id) ON DELETE CASCADE,
  CONSTRAINT FK_ISBN_BO FOREIGN KEY(Isbn) REFERENCES BOOKS(Isbn) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ORDERS_PAYMENT (
  Payment_id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Order_id INT UNSIGNED,
  Payment_method VARCHAR(32),
  Time_stamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT FK_ORDER_ID_OP FOREIGN KEY(Order_id) REFERENCES ORDERS(Order_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE REVIEWS (
  Cust_id INT UNSIGNED ,
  Order_id INT UNSIGNED,
  Isbn CHAR(10),
  Time_stamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  Rating INT, 
  Comm VARCHAR(1024),
  PRIMARY KEY (Cust_id, Order_id, Isbn, Time_stamp),
  CONSTRAINT FK_CUST_ID_REV FOREIGN KEY (Cust_id) REFERENCES CUSTOMERS(Cust_id) ON DELETE CASCADE,
  CONSTRAINT FK_ORDER_ID_REV FOREIGN KEY (Order_id) REFERENCES ORDERS(Order_id) ON DELETE CASCADE,
  CONSTRAINT FK_ISBN_REV FOREIGN KEY (Isbn) REFERENCES BOOKS(Isbn) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ADMINS (
  Admin_id INT PRIMARY KEY,
  First_name VARCHAR(16),
  Last_name VARCHAR(16),
  Password VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE MANAGE_STOCK(
  Admin_id INT NOT NULL,
  Isbn CHAR(10) NOT NULL,
  Old_stock_quant INT NOT NULL,
  New_stock_quant INT NOT NULL,
  Delta_stock_quant INT DEFAULT NULL,
  Time_stamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
  PRIMARY KEY(Admin_id, Time_stamp),
  CONSTRAINT FK_ADMIN_ID_MS FOREIGN KEY (Admin_id) REFERENCES ADMINS(Admin_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE MANAGE_ORDER (
  Admin_id INT,
  Order_id INT UNSIGNED,
  Time_stamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL ,
  Action_type VARCHAR(64),
  PRIMARY KEY (Admin_id, Time_stamp),
  CONSTRAINT FK_ADMIN_ID FOREIGN KEY (Admin_id) REFERENCES ADMINS(Admin_id) ON DELETE CASCADE,
  CONSTRAINT FK_ORDER_ID_MO FOREIGN KEY (Order_id) REFERENCES ORDERS(Order_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO BOOKS (Isbn, Title, Edition, Price, Pub_year, Stock_quant)
VALUES (0123456789, 'Algebra', 1, 9.99, 2000, 5);
INSERT INTO BOOKS (Isbn, Title, Edition, Price, Pub_year, Stock_quant)
VALUES (1234567890, 'Number Theory', 2, 19.99, 2001, 10);
INSERT INTO BOOKS (Isbn, Title, Edition, Price, Pub_year, Stock_quant)
VALUES (2345678901, 'Calculus', 3, 29.99, 2002, 20);
INSERT INTO BOOKS (Isbn, Title, Edition, Price, Pub_year, Stock_quant)
VALUES (3456789012, 'Probability', 4, 39.99, 2003, 30);
INSERT INTO BOOKS (Isbn, Title, Edition, Price, Pub_year, Stock_quant)
VALUES (4567890123, 'Statistics', 5, 49.99, 2004, 40);
INSERT INTO BOOKS (Isbn, Title, Edition, Price, Pub_year, Stock_quant)
VALUES (5678901234, 'Relational Algebra', 6, 59.99, 2005, 50);

INSERT INTO AUTHORS (Author_id, Name, Nationality, Biography)
VALUES (123, 'Al-Gebriz', 'Persian', 'The OG of Mathematics');
INSERT INTO AUTHORS (Author_id, Name, Nationality, Biography)
VALUES (234, 'Ramunanujan', 'Indian', 'The Boy-Wonder of Modern Mathematicsc');
INSERT INTO AUTHORS (Author_id, Name, Nationality, Biography)
VALUES (345, 'Newton', 'English', 'The More, Well-Known Boy-Wonder of Modern Mathematicsc');
INSERT INTO AUTHORS (Author_id, Name, Nationality, Biography)
VALUES (456, 'Descartes', 'French', 'He Took No Prisoners');
INSERT INTO AUTHORS (Author_id, Name, Nationality, Biography)
VALUES (567, 'Pearson', 'English', 'Low-key you could NOT live without him.');
INSERT INTO AUTHORS (Author_id, Name, Nationality, Biography)
VALUES (678, 'Codd', 'English', 'Here we are making databases thanks to this guy...');

INSERT INTO WRITTEN_BY (Isbn, Author_id)
VALUES (0123456789, 123);
INSERT INTO WRITTEN_BY (Isbn, Author_id)
VALUES (1234567890, 234);
INSERT INTO WRITTEN_BY (Isbn, Author_id)
VALUES (2345678901, 345);
INSERT INTO WRITTEN_BY (Isbn, Author_id)
VALUES (3456789012, 456);
INSERT INTO WRITTEN_BY (Isbn, Author_id)
VALUES (4567890123, 567);
INSERT INTO WRITTEN_BY (Isbn, Author_id)
VALUES (5678901234, 678);

INSERT INTO CATEGORIES (Category_id, Category)
VALUES (0123, 'Classical Mathematics');
INSERT INTO CATEGORIES (Category_id, Category)
VALUES (1234, 'Modern Mathematics');

INSERT INTO BELONG_CATEGORIES (Isbn, Category_id)
VALUES (0123456789, 0123);
INSERT INTO BELONG_CATEGORIES (Isbn, Category_id)
VALUES(1234567890, 0123);
INSERT INTO BELONG_CATEGORIES (Isbn, Category_id)
VALUES(2345678901, 0123);
INSERT INTO BELONG_CATEGORIES (Isbn, Category_id)
VALUES(3456789012, 0123);
INSERT INTO BELONG_CATEGORIES (Isbn, Category_id)
VALUES (4567890123, 0123);
INSERT INTO BELONG_CATEGORIES (Isbn, Category_id)
VALUES (5678901234, 1234);

INSERT INTO CUSTOMERS(Cust_id, First_name, Last_name, User_name, Password, Address, Phone_num, Reg_date)
VALUES (01234567, 'John', 'Lennon', 'JohnnyBoy', 'Dog123', '57 Green St, London, England', '44-555-5555', '2002-01-25 01:14:15');
INSERT INTO CUSTOMERS(Cust_id, First_name, Last_name, User_name, Password, Address, Phone_num, Reg_date)
VALUES (12345678, 'Paul', 'McCartney', 'LadiesMan', 'Dog123', '57 Green St, London, England', '44-555-5556', '2002-02-25 01:14:15');
INSERT INTO CUSTOMERS(Cust_id, First_name, Last_name, User_name, Password, Address, Phone_num, Reg_date)
VALUES (23456789, 'George', 'Harrison', 'ShyGuy', 'Dog123', '57 Green St, London, England', '44-555-5557', '2002-03-25 01:14:15');
INSERT INTO CUSTOMERS(Cust_id, First_name, Last_name, User_name, Password, Address, Phone_num, Reg_date)
VALUES (34567890, 'Ringo', 'Starr', 'Ringo', 'Dog123', '57 Green St, London, England', '44-555-5558', '2002-04-25 01:14:15');
INSERT INTO CUSTOMERS(Cust_id, First_name, Last_name, User_name, Password, Address, Phone_num, Reg_date)
VALUES (45678901, 'George', 'Martin', '20199732', 'Dog123', '57 Green St, London, England', '44-555-5559', '2002-05-25 01:14:15');

INSERT INTO ORDERS (Order_id, Cust_id, Status, Total_amt)
VALUES (01234567, 01234567,'Incomplete', 56.70);
INSERT INTO ORDERS (Order_id, Cust_id, Status, Total_amt)
VALUES (12345678, 12345678,'In-transit', 430.94);
INSERT INTO ORDERS (Order_id, Cust_id, Status, Total_amt)
VALUES (23456789, 23456789,'In-transit', 20.77);
INSERT INTO ORDERS (Order_id, Cust_id, Status, Total_amt)
VALUES (34567890, 34567890,'In-transit', 29.41);
INSERT INTO ORDERS (Order_id, Cust_id, Status, Total_amt)
VALUES (45678901, 45678901,'Filled', 41.87);

INSERT INTO BOOK_ORDERS (Order_id, Isbn)
VALUES (01234567, 0123456789);
INSERT INTO BOOK_ORDERS (Order_id, Isbn)
VALUES (12345678, 1234567890);
INSERT INTO BOOK_ORDERS (Order_id, Isbn)
VALUES (23456789, 2345678901);
INSERT INTO BOOK_ORDERS (Order_id, Isbn)
VALUES (34567890, 3456789012);
INSERT INTO BOOK_ORDERS (Order_id, Isbn)
VALUES (34567890, 4567890123);

INSERT INTO ORDERS_PAYMENT (Order_id, Payment_id, Payment_method, Time_stamp)
VALUES (01234567, 465987, 'PayPal', '2002-03-25 01:14:15');
INSERT INTO ORDERS_PAYMENT (Order_id, Payment_id, Payment_method, Time_stamp)
VALUES (34567890, 465789, 'AMEX', '2002-03-27 01:14:15');
INSERT INTO ORDERS_PAYMENT (Order_id, Payment_id, Payment_method, Time_stamp)
VALUES (12345678, 463987, 'AMEX', '2002-04-27 01:14:15');
INSERT INTO ORDERS_PAYMENT (Order_id, Payment_id, Payment_method, Time_stamp)
VALUES (23456789, 156987, 'Credit Card', '2002-05-27 01:14:15');
INSERT INTO ORDERS_PAYMENT (Order_id, Payment_id, Payment_method, Time_stamp)
VALUES (45678901, 489687, 'PayPal', '2002-06-27 01:14:15');

INSERT INTO REVIEWS(Order_id, Cust_id, Isbn, Time_stamp, Rating, Comm)
VALUES (01234567, 23456789, 0123456789, '2002-01-25 01:14:15', 9, 'Great start, solid');
INSERT INTO REVIEWS(Order_id, Cust_id, Isbn, Time_stamp, Rating, Comm)
VALUES (12345678, 01234567, 0123456789, '25-02-03 2:15:16', 10, 'Gotta love algebra...');
INSERT INTO REVIEWS(Order_id, Cust_id, Isbn, Time_stamp, Rating, Comm)
VALUES (23456789, 01234567,0123456789, '25-03-04 3:16:17', 6, 'Seems incomplete, should have follow-up edition');
INSERT INTO REVIEWS(Order_id, Cust_id, Isbn, Time_stamp, Rating, Comm)
VALUES (34567890, 01234567,3456789012, '25-04-05 4:17:18', 9, 'My friend loved it.');
INSERT INTO REVIEWS(Order_id, Cust_id, Isbn, Time_stamp, Rating, Comm)
VALUES (45678901, 01234567, 3456789012, '25-05-06 6:18:19', 9, 'Very interesting title, would recommmend');

INSERT INTO ADMINS(Admin_id, First_name, Last_name, Password)
VALUES (01234567, 'Anthony', 'Baskin', 'Dog123');
INSERT INTO ADMINS(Admin_id, First_name, Last_name, Password)
VALUES (12345678, 'Michael', 'Baskin', 'Dog1234');
INSERT INTO ADMINS(Admin_id, First_name, Last_name, Password)
VALUES (23456789, 'Tony', 'Baskin', 'Dog12345');
INSERT INTO ADMINS(Admin_id, First_name, Last_name, Password)
VALUES (34567890, 'Mr.Anthony', 'Baskin', 'Dog123456');

INSERT INTO MANAGE_STOCK(Admin_id, Isbn, Old_stock_quant, New_stock_quant, Time_stamp)
VALUES (34567890, 0123456789, 0, 5, '25-04-05 06:17:18' );
INSERT INTO MANAGE_STOCK(Admin_id, Isbn, Old_stock_quant, New_stock_quant, Time_stamp)
VALUES (23456789, 0123456789, 5, 10, '25-07-08 08:19:20');

INSERT INTO MANAGE_STOCK(Admin_id, Isbn, Old_stock_quant, New_stock_quant, Time_stamp)
VALUES (01234567, 0123456789, 0, 5, '25-04-05 06:17:18' );
INSERT INTO MANAGE_STOCK(Admin_id, Isbn, Old_stock_quant, New_stock_quant, Time_stamp)
VALUES (01234567, 0123456789, 5, 10, '25-04-05 06:17:19');

INSERT INTO MANAGE_ORDER(Admin_id, Order_id, Time_stamp, Action_type)
VALUES (23456789, 01234567, '25-04-05 06:17:18', 'Change payment method');
INSERT INTO MANAGE_ORDER(Admin_id, Order_id, Time_stamp, Action_type)
VALUES (23456789, 01234567, '25-07-08 12:19:20', 'Change payment method');
