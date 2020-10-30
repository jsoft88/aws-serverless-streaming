USE test_db;
GRANT RELOAD, PROCESS, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'python'@'%';

CREATE TABLE IF NOT EXISTS test_table(
	order_id INT NOT NULL AUTO_INCREMENT,
	customer_id VARCHAR(30),
	article_id VARCHAR(30),
	quantity INT,
	unit_price DECIMAL(8, 2),
	PRIMARY KEY (order_id)
);