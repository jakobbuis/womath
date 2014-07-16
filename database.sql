CREATE DATABASE  IF NOT EXISTS `womath_development`
USE `womath_development`;

CREATE TABLE `people` (
  `id` int(11) NOT NULL,
  `repository` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
);
