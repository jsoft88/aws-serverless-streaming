CREATE USER 'python'@'localhost' IDENTIFIED BY '123456';

CREATE DATABASE test_db;

USE test_db;

CREATE TABLE IF NOT EXISTS test_table(
	order_id INT NOT NULL AUTO_INCREMENT,
	customer_id VARCHAR(30),
	article_id VARCHAR(30),
	quantity INT,
	unit_price DECIMAL(8, 2),
	PRIMARY KEY (order_id)
);

GRANT ALL ON test_db.test_table TO 'python'@'localhost';