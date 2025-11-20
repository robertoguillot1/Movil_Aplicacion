# CervezApp 🍻

**Gestión Inteligente de Inventario**

CervezApp es una aplicación móvil desarrollada como proyecto académico para la gestión y control de inventario, ventas y clientes en una tienda de cervezas artesanales.

Su objetivo es ofrecer una solución simple, eficiente y moderna para pequeños negocios dedicados a la venta de bebidas.

## 📋 Información del Proyecto

- **Desarrollador**: Roberto Antonio Guillot Ipuana
- **Institución**: Universidad de La Guajira
- **Programa**: Ingeniería de Sistemas
- **Docente**: Bryan J. Otero Arrieta
- **Asignatura**: Desarrollo de Aplicaciones Móviles
- **Año**: 2025
- **Versión**: 1.7.0

## 🚀 Tecnologías Utilizadas

- **Framework**: Flutter
- **Lenguaje**: Dart
- **Backend**: Firebase (Authentication + Firestore)
- **Estado**: Provider
- **Plataformas**: Android, iOS, Web, Windows

## 🔧 Funcionalidades Principales

### 🔐 **Sistema de Autenticación**
- **Login/Registro**: Autenticación con email y contraseña
- **Gestión de Perfil**: Actualización de datos del usuario
- **Roles de Usuario**: Administrador y usuarios regulares
- **Sesión Persistente**: Mantiene la sesión activa entre reinicios

### 📦 **Gestión de Productos**
- **Catálogo de Productos**: Lista completa de cervezas disponibles
- **CRUD Completo**: Crear, leer, actualizar y eliminar productos
- **Categorías**: Organización por tipos de cerveza
- **Control de Stock**: Seguimiento de inventario en tiempo real
- **Precios**: Gestión de precios de venta y costos

### 👥 **Gestión de Clientes**
- **Base de Datos**: Registro completo de clientes
- **Información Detallada**: Datos de contacto y preferencias
- **Historial de Compras**: Seguimiento de ventas por cliente
- **Gestión de Créditos**: Control de cuentas por cobrar

### 💰 **Sistema de Ventas**
- **Proceso de Venta**: Registro completo de transacciones
- **Múltiples Productos**: Ventas con varios items
- **Cálculo Automático**: Totales, impuestos y descuentos
- **Comprobantes**: Generación de recibos de venta
- **Historial**: Registro histórico de todas las ventas

### 📊 **Estadísticas y Reportes**
- **Dashboard**: Vista general del negocio
- **Ventas por Período**: Análisis temporal de ingresos
- **Productos Más Vendidos**: Ranking de productos
- **Clientes Frecuentes**: Análisis de comportamiento
- **Exportación**: Generación de reportes en PDF/Excel

### 📱 **Características Adicionales**
- **Interfaz Moderna**: Diseño intuitivo y responsivo
- **Navegación Fluida**: Menú lateral con acceso rápido
- **Notificaciones**: Alertas y mensajes informativos
- **Tema Personalizado**: Colores corporativos de cerveza
- **Multiplataforma**: Funciona en móviles, tablets y escritorio

## 🏗️ Arquitectura de la Aplicación

### **Pantallas Principales**
- `HomeScreen`: Dashboard principal con estadísticas
- `ProductListScreen`: Lista de productos disponibles
- `ProductFormScreen`: Formulario para crear/editar productos
- `CustomersScreen`: Gestión de clientes
- `CustomerForm`: Formulario de clientes
- `SalesScreen`: Historial de ventas
- `SaleFormScreen`: Proceso de nueva venta
- `StatsScreen`: Estadísticas y reportes
- `LoginScreen`: Autenticación de usuarios
- `ProfileScreen`: Gestión de perfil
- `AboutScreen`: Información de la aplicación

### **Servicios Backend**
- `AuthService`: Manejo de autenticación y usuarios
- `ProductService`: Gestión de productos y categorías
- `CustomerService`: Administración de clientes
- `SalesService`: Procesamiento de ventas
- `StatsService`: Cálculo de estadísticas
- `ReceiptService`: Generación de comprobantes

### **Modelos de Datos**
- `User`: Información del usuario
- `Product`: Datos del producto
- `Customer`: Información del cliente
- `Sale`: Detalles de la venta

## 🛠️ Instalación y Configuración

### Prerrequisitos
- Flutter SDK (>=3.0.0)
- Dart SDK
- Firebase CLI
- Android Studio / VS Code

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone [url-del-repositorio]
   cd cervezapp
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   - Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
   - Habilitar Authentication (Email/Password)
   - Configurar Firestore Database
   - Descargar `google-services.json` para Android

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 🔑 Credenciales de Prueba

- **Email**: admin@cervezapp.com
- **Contraseña**: admin123

## 📱 Capturas de Pantalla

La aplicación incluye:
- Dashboard con estadísticas en tiempo real
- Gestión completa de productos con imágenes
- Sistema de ventas intuitivo
- Reportes detallados y exportables
- Interfaz moderna y fácil de usar

## 🤝 Contribuciones

Este es un proyecto académico desarrollado como parte del programa de Ingeniería de Sistemas de la Universidad de La Guajira.

## 📄 Licencia

© Universidad de La Guajira — Proyecto Académico 2025

---

**Desarrollado con ❤️ para la comunidad universitaria**