FLUSH PRIVILEGES;
CREATE DATABASE wordpress;
CREATE USER 'user'@'%' IDENTIFIED BY 'password';
GRANT ALL ON wordpress.* TO 'user'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;
DROP DATABASE test; /*The test database that was automatically created has to be removed*/
FLUSH PRIVILEGES;
