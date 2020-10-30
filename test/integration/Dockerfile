FROM mysql:5.7
WORKDIR /docker-entrypoint-initdb.d
ENV MYSQL_ROOT_PASSWORD=123456
ENV MYSQL_USER=python
ENV MYSQL_PASSWORD=123456
ENV MYSQL_DATABASE=test_db
COPY ./sql/init_scripts.sql init_scripts.sql
COPY ./sql/inserts.sql inserts.sql
COPY mysqld.cnf /etc/mysql/mysql.conf.d/mysqld.cnf