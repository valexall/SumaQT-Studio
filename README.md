# SumaQT Studio 🎨✨

**SumaQT Studio** es una suite moderna para edición y procesamiento inteligente de imágenes (incluyendo eliminación de fondo / *Remove BG*), construida con una arquitectura modular y desacoplada que combina la potencia de **FastAPI** en el backend con una experiencia visual fluida y responsiva en **Flutter**.

---

## 🏗️ Arquitectura del Proyecto

El repositorio está estructurado como un monorepo que alberga tanto el frontend como el backend:

```text
SumaQT Studio/
├── backend/                  # API REST con FastAPI (Monolito Modular)
│   ├── aplicacion/           # Punto de entrada y configuración de la app
│   ├── modulos/              # Módulos de dominio (usuarios, procesamiento_imagen, etc.)
│   ├── nucleo/               # Configuraciones centrales, seguridad (PBKDF2/JWT) y base de datos (MySQL)
│   ├── sql/                  # Scripts DDL de inicialización de la base de datos
│   ├── requirements.txt      # Dependencias de Python
│   └── .env.example          # Plantilla de variables de entorno
│
├── frontend/                 # Aplicación Flutter Multiplataforma (Desktop / Web / Móvil)
│   ├── lib/
│   │   ├── core/             # Configuración global, temas y constantes
│   │   ├── data/             # Servicios HTTP, repositorios y file pickers
│   │   ├── domain/           # Modelos de datos y entidades de negocio
│   │   └── ui/               # Vistas (Auth, Remove BG), ViewModels y widgets reutilizables
│   └── pubspec.yaml          # Dependencias y assets de Flutter
│
└── .agents/                  # Habilidades y agentes personalizados de desarrollo
```

---

## 👥 Procesos End-to-End (E2E) y Diagramas de Arquitectura

A continuación se detalla la relación de procesos E2E implementados en la plataforma, sus límites de ejecución, módulos y actores involucrados, junto a los enlaces directos a sus respectivos diagramas interactivos (*Archify*):

| Integrante | Proceso E2E | Inicio y Fin | Actores o Módulos Involucrados | Enlace al Diagrama |
| :--- | :--- | :--- | :--- | :--- |
| **Valentin Arenaza Ccaccya** (`@astr4vale`) | **Eliminación Inteligente de Fondo (*Remove BG*)** | **Inicio:** Usuario carga una imagen (JPEG/PNG/WEBP) en la interfaz.<br>**Fin:** Usuario visualiza y descarga la imagen en formato PNG transparente sin fondo. | • **Actor:** Usuario<br>• **Frontend:** Flutter UI (`HeroSection`, `UploadCard`, `RemoveBgViewModel`)<br>• **Backend:** FastAPI (`modulos/procesamiento_imagen`), Motor IA (`rembg` con U2-Net en ONNX Runtime)<br>• **Base de Datos:** MySQL Server (`sumaqt_studio` vía SQLAlchemy / `aiomysql`) | [📊 Ver Diagrama de Secuencia E2E](.archify/sequence-quitar-fondo-e2e-20261018-220000/quitar-fondo-e2e.html) |
| **Roger Paniura Ramos** (`@astr4vale`) | **Registro, Login y Autorización JWT** | **Inicio:** Usuario ingresa credenciales en `AuthView` (Login / Registro).<br>**Fin:** Usuario autenticado con JWT Bearer token, sesión establecida en Flutter y acceso concedido al editor. | • **Actor:** Usuario<br>• **Frontend:** Flutter UI (`AuthView`, `AuthViewModel`, `AuthRepository`, `AuthService`)<br>• **Backend:** FastAPI (`modulos/usuarios`), Núcleo Criptográfico (`nucleo/seguridad.py` con PBKDF2-HMAC-SHA256 y PyJWT)<br>• **Base de Datos:** MySQL Server (tabla `usuarios`) | [🔐 Ver Diagrama de Secuencia Auth](.archify/sequence-auth-e2e-20261018-223000/auth-e2e.html) |
| **Yerymay Rayme Pimentel** (`@astr4vale`) | **Arquitectura Global del Sistema (Monolito Modular)** | **Inicio:** Petición HTTP / Streaming desde el cliente Flutter.<br>**Fin:** Procesamiento desacoplado, persistencia en MySQL y retorno visual. | • **Frontend:** Capa UI, ViewModels, Repositorios, Servicios HTTP<br>• **Backend:** FastAPI Core, Módulos (`usuarios`, `procesamiento_imagen`), Núcleo BD (`nucleo/base_datos.py`)<br>• **Infraestructura:** Motor IA ONNX Runtime + MySQL Server `:3306` | [🏛️ Ver Diagrama de Arquitectura](.archify/architecture-quitar-fondo-20261018-221000/sumaqt-studio-arquitectura.html) |

---

## 🚀 Inicio Rápido

### 1. Requisitos Previos

- **Python** 3.10+
- **Flutter SDK** 3.x+
- **Git**

---

### 2. Configuración del Backend

1. Entra en el directorio del backend:
   ```bash
   cd backend
   ```

2. Crea y activa tu entorno virtual:
   ```bash
   # Windows (PowerShell)
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   ```

3. Instala las dependencias:
   ```bash
   pip install -r requirements.txt
   ```

4. Configura las variables de entorno:
   ```bash
   cp .env.example .env
   ```
   *(Edita `.env` con tus credenciales de MySQL y clave secreta de JWT)*.

5. Ejecuta el script SQL de inicialización en MySQL:
   ```bash
   # Puedes importar el archivo sql/init.sql en tu cliente MySQL o phpMyAdmin
   # O directamente por consola:
   mysql -u root -p < sql/init.sql
   ```

6. Inicia el servidor de desarrollo:
   ```bash
   uvicorn aplicacion.main:app --reload --port 8000
   ```
   La documentación interactiva Swagger estará disponible en: `http://localhost:8000/docs`.

---

### 3. Configuración del Frontend

1. Entra en el directorio del frontend:
   ```bash
   cd frontend
   ```

2. Obtén las dependencias de Flutter:
   ```bash
   flutter pub get
   ```

3. Ejecuta la aplicación (por ejemplo en Windows Desktop o Chrome):
   ```bash
   flutter run -d windows
   # o para web:
   flutter run -d chrome
   ```

---

## 🛠️ Tecnologías Utilizadas

- **Backend**: [FastAPI](https://fastapi.tiangolo.com/), [SQLAlchemy](https://www.sqlalchemy.org/) (AsyncIO), [aiomysql](https://github.com/aio-libs/aiomysql), [MySQL](https://www.mysql.com/), [rembg](https://github.com/danielgatis/rembg) (U2-Net / ONNX), [PyJWT](https://pyjwt.readthedocs.io/), [Uvicorn](https://www.uvicorn.org/)
- **Frontend**: [Flutter](https://flutter.dev/), [Dart](https://dart.dev/), arquitectura MVVM / Clean Architecture por capas, [Provider](https://pub.dev/packages/provider), [Google Fonts](https://pub.dev/packages/google_fonts)
- **Diagramas de Arquitectura**: [Archify](https://github.com/archify) (SVG interactivo con animación trace)

---

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulta `LICENSE` para más información.
