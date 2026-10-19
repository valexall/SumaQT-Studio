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

-- 4. Tabla: ordenes
-- Órdenes de trabajo del estudio (flujo: pendiente → procesando → entregada).
CREATE TABLE IF NOT EXISTS `ordenes` (
  `id` CHAR(36) NOT NULL,
  `nombre_proyecto` VARCHAR(120) NOT NULL,
  `cliente_nombre` VARCHAR(120) NOT NULL,
  `cliente_email` VARCHAR(255) NOT NULL,
  `total_imagenes` INT NOT NULL,
  `imagenes_procesadas` INT NOT NULL DEFAULT 0,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'pendiente',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cerrada_en` DATETIME NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Tabla: archivos_orden
-- Imágenes subidas a cada orden (original y resultado sin fondo en disco local).
CREATE TABLE IF NOT EXISTS `archivos_orden` (
  `id` CHAR(36) NOT NULL,
  `orden_id` CHAR(36) NOT NULL,
  `nombre_original` VARCHAR(255) NOT NULL,
  `storage_path_original` VARCHAR(500) NULL,
  `storage_path_resultado` VARCHAR(500) NULL,
  `estado` VARCHAR(20) NOT NULL DEFAULT 'procesado',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `ix_archivos_orden_orden_id` (`orden_id`),
  CONSTRAINT `fk_archivos_orden_orden`
    FOREIGN KEY (`orden_id`) REFERENCES `ordenes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
