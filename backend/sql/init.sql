-- ==============================================================================
-- SumaQt Studio — Script de Inicialización de Base de Datos MySQL
-- ==============================================================================

-- 1. Crear base de datos (si no existe)
CREATE DATABASE IF NOT EXISTS `sumaqt_studio`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- 2. Seleccionar la base de datos
USE `sumaqt_studio`;

-- 3. Tabla: usuarios
-- Almacena los usuarios registrados en el sistema.
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(120) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `creado_en` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_usuarios_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
