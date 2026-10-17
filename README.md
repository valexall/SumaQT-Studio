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
│   ├── nucleo/               # Configuraciones centrales y clientes externos (Supabase, etc.)
│   ├── requirements.txt      # Dependencias de Python
│   └── .env.example          # Plantilla de variables de entorno
│
├── frontend/                 # Aplicación Flutter Multiplataforma (Desktop / Web / Móvil)
│   ├── lib/
│   │   ├── core/             # Configuración global, temas y constantes
│   │   ├── data/             # Servicios HTTP, repositorios y file pickers
│   │   ├── domain/           # Modelos de datos y entidades de negocio
│   │   └── ui/               # Vistas, ViewModels y widgets reutilizables
│   └── pubspec.yaml          # Dependencias y assets de Flutter
│
└── .agents/                  # Habilidades y agentes personalizados de desarrollo
```

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
   *(Edita `.env` con tus credenciales de Supabase si corresponde)*.

5. Inicia el servidor de desarrollo:
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

- **Backend**: [FastAPI](https://fastapi.tiangolo.com/), [Pydantic Settings](https://docs.pydantic.dev/), [Supabase Python](https://supabase.com/docs/reference/python), [Uvicorn](https://www.uvicorn.org/)
- **Frontend**: [Flutter](https://flutter.dev/), [Dart](https://dart.dev/), arquitectura MVVM / Clean Architecture por capas
- **Control de Versiones**: Git & GitHub

---

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulta `LICENSE` para más información.
