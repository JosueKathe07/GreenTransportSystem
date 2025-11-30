GreenTransportSystem

Sistema de gestión de flota eléctrica — Caso 3 (Git + SQL)

🚀 Descripción del Proyecto

Este proyecto implementa una solución para la empresa GreenTransport, dedicada a administrar una flota de vehículos eléctricos junto con sus conductores y mantenimientos.
El objetivo principal es construir:

Una base de datos transaccional para controlar la flota.

Un flujo profesional de control de versiones usando Git y GitHub.

El proyecto combina conocimientos de SQL Server Express, diseño de base de datos, consultas avanzadas, transacciones, y versionamiento con Git aplicados a un caso empresarial real.

🧩 1. Objetivo del Sistema

La empresa requiere una herramienta que permita:

Registrar vehículos eléctricos.

Administrar conductores activos e inactivos.

Registrar mantenimientos, costos y fechas.

Detectar vehículos sin mantenimiento reciente.

Comparar el estado de la flota mediante operaciones de conjuntos.

Mantener consistencia en los datos mediante transacciones SQL.

Este repositorio contiene toda la estructura del proyecto, incluyendo el script SQL y el flujo de desarrollo con ramas.

🗂️ 2. Estructura del Repositorio
GreenTransportSystem/
│
├── sql/
│   └── green_transport_db.sql    # Script SQL completo y funcional
│
├── README.md                     # Documentación principal
│
└── docs/ (opcional)              # Puedes agregar PDF, diagramas o evidencias

🛢️ 3. Descripción de la Base de Datos

El modelo incluye tres tablas principales:

🚗 Vehículos

Información de la flota eléctrica.

Campos: Placa, Modelo, Año, Estado, Disponible.

👤 Conductores

Información personal y laboral.

Campos: Nombre, Licencia, FechaContratación, Activo.

🔧 Mantenimientos

Registro de los servicios de mantenimiento realizados.

Contiene: IdVehiculo, IdConductor, fechas, descripción, costo.

✔ Relaciones

Un vehículo puede tener múltiples mantenimientos.

Un conductor puede participar en mantenimiento pero es opcional.

Incluye validaciones mediante CHECK, FOREIGN KEYS y restricciones lógicas.

🧪 4. Funcionalidades Implementadas en SQL

Dentro del archivo green_transport_db.sql se incluyen:

📌 Consultas avanzadas

Mantenimientos por conductor (JOIN)

Vehículos sin mantenimiento en el último mes

Comparación de flota con:

UNION

INTERSECT

EXCEPT

🔐 Transacción completa

Incluye:

Registro de mantenimiento

Cambio de estado del vehículo a “MANTENIMIENTO”

Validaciones de disponibilidad

Manejo de errores con TRY–CATCH

COMMIT y ROLLBACK

Esta transacción garantiza la integridad de la información.

🧷 5. Cómo Ejecutar el Script SQL
🔸 Requisitos:

SQL Server Express

SQL Server Management Studio (SSMS)

🔸 Pasos:

Abrir SSMS.

Conectarse a la instancia local.

Abrir el archivo:
sql/green_transport_db.sql

Presionar Execute o F5.

Verificar que se creó la BD:
GreenTransportDB

Probar las consultas incluidas en el script.

⚡ El script elimina y recrea la base de datos automáticamente para evitar errores de duplicado.

🌱 6. Flujo de Trabajo Git Utilizado (Git Flow)

Este proyecto usa un flujo profesional con ramas:

Ramas principales:

main → Versión estable, lista para producción.

develop → Línea principal de desarrollo.

Ramas feature:

feature/vehiculos

feature/conductores

feature/mantenimientos

Flujo aplicado:

Crear ramas feature desde develop.

Realizar commits frecuentes en cada feature.

Subir cambios:

git push origin feature/vehiculos


Crear pull requests hacia develop.

Resolver conflictos si aparecen.

Al finalizar el proyecto → Merge final:
develop → main.# GreenTransportSystem
