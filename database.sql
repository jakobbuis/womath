CREATE DATABASE  IF NOT EXISTS `womath_development`
USE `womath_development`;

CREATE TABLE `people` (
  `id` int(11) NOT NULL,
  `repository` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
);

ALTER TABLE `womath_development`.`people` 
ADD COLUMN `company_identifier` VARCHAR(45) NULL AFTER `name`,
ADD COLUMN `company_name` VARCHAR(45) NULL AFTER `company_identifier`;

ALTER TABLE `womath_development`.`people` 
DROP COLUMN `company_identifier`;
