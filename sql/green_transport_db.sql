/* ============================================================
   SCRIPT: GreenTransportDB - Gestión de flota eléctrica
   Pensado para SQL Server / SQL Server Express
   ============================================================ */

---------------------------------------------------------------
-- 1. Eliminar BD si existe y crearla de nuevo
---------------------------------------------------------------
IF DB_ID('GreenTransportDB') IS NOT NULL
BEGIN
    ALTER DATABASE GreenTransportDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GreenTransportDB;
END;
GO

CREATE DATABASE GreenTransportDB;
GO

USE GreenTransportDB;
GO

---------------------------------------------------------------
-- 2. Creación de tablas
---------------------------------------------------------------

-- Tabla: Vehiculos
IF OBJECT_ID('dbo.Vehiculos', 'U') IS NOT NULL
    DROP TABLE dbo.Vehiculos;
GO

CREATE TABLE dbo.Vehiculos (
    IdVehiculo      INT IDENTITY(1,1) PRIMARY KEY,
    Placa           VARCHAR(10) NOT NULL UNIQUE,
    Modelo          VARCHAR(50) NOT NULL,
    Anio            INT NOT NULL CHECK (Anio BETWEEN 2015 AND YEAR(GETDATE()) + 1),
    Estado          VARCHAR(20) NOT NULL 
        CHECK (Estado IN ('ACTIVO', 'MANTENIMIENTO', 'RETIRADO')) 
        DEFAULT 'ACTIVO',
    Disponible      BIT NOT NULL DEFAULT 1
);
GO

-- Tabla: Conductores
IF OBJECT_ID('dbo.Conductores', 'U') IS NOT NULL
    DROP TABLE dbo.Conductores;
GO

CREATE TABLE dbo.Conductores (
    IdConductor         INT IDENTITY(1,1) PRIMARY KEY,
    NombreCompleto      NVARCHAR(100) NOT NULL,
    NumeroLicencia      VARCHAR(20) NOT NULL UNIQUE,
    FechaContratacion   DATE NOT NULL,
    Activo              BIT NOT NULL DEFAULT 1
);
GO

-- Tabla: Mantenimientos
IF OBJECT_ID('dbo.Mantenimientos', 'U') IS NOT NULL
    DROP TABLE dbo.Mantenimientos;
GO

CREATE TABLE dbo.Mantenimientos (
    IdMantenimiento INT IDENTITY(1,1) PRIMARY KEY,
    IdVehiculo      INT NOT NULL,
    IdConductor     INT NULL, -- puede ser NULL si lo lleva a taller externo
    FechaInicio     DATE NOT NULL,
    FechaFin        DATE NULL,
    Descripcion     NVARCHAR(200) NULL,
    Costo           DECIMAL(10,2) NULL CHECK (Costo IS NULL OR Costo >= 0),

    CONSTRAINT FK_Mantenimientos_Vehiculos
        FOREIGN KEY (IdVehiculo) REFERENCES dbo.Vehiculos(IdVehiculo),
    CONSTRAINT FK_Mantenimientos_Conductores
        FOREIGN KEY (IdConductor) REFERENCES dbo.Conductores(IdConductor),
    CONSTRAINT CK_Mantenimientos_Fechas
        CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio)
);
GO

---------------------------------------------------------------
-- 3. Insertar datos de ejemplo
---------------------------------------------------------------

-- Vehículos
INSERT INTO dbo.Vehiculos (Placa, Modelo, Anio, Estado, Disponible)
VALUES
('EV-1001', 'Nissan Leaf',          2021, 'ACTIVO',        1),
('EV-1002', 'Tesla Model 3',        2022, 'ACTIVO',        1),
('EV-1003', 'Hyundai Kona Electric',2020, 'MANTENIMIENTO', 0),
('EV-1004', 'Chevy Bolt',           2019, 'ACTIVO',        1),
('EV-1005', 'Kia Niro EV',          2023, 'RETIRADO',      0);
GO

-- Conductores
INSERT INTO dbo.Conductores (NombreCompleto, NumeroLicencia, FechaContratacion, Activo)
VALUES
(N'Laura Gómez',    'LIC-CR-001', '2020-03-15', 1),
(N'Carlos Ruiz',    'LIC-CR-002', '2019-07-01', 1),
(N'Ana Fernández',  'LIC-CR-003', '2021-11-20', 1),
(N'Pedro Morales',  'LIC-CR-004', '2018-01-10', 0); -- inactivo
GO

-- Mantenimientos
-- Suponemos que hoy es GETDATE(); usamos fechas variadas (algunos del último mes y otros antiguos)
DECLARE @Hoy DATE = CAST(GETDATE() AS DATE);

INSERT INTO dbo.Mantenimientos (IdVehiculo, IdConductor, FechaInicio, FechaFin, Descripcion, Costo)
VALUES
-- Mantenimiento antiguo (hace más de 1 mes)
(1, 1, DATEADD(MONTH, -3, @Hoy), DATEADD(MONTH, -3, @Hoy), N'Mantenimiento preventivo general', 150.00),

-- Mantenimiento reciente (último mes)
(2, 2, DATEADD(DAY, -10, @Hoy), DATEADD(DAY, -9, @Hoy), N'Revisión de baterías', 200.00),

-- Mantenimiento en curso (sin FechaFin, vehículo no disponible)
(3, 3, DATEADD(DAY, -5, @Hoy), NULL, N'Cambio de módulo de carga', 500.00),

-- Vehículo 4 con mantenimiento muy antiguo
(4, 1, DATEADD(YEAR, -1, @Hoy), DATEADD(YEAR, -1, @Hoy), N'Revisión de frenos eléctricos', 100.00);
GO

---------------------------------------------------------------
-- 4. Consultas avanzadas con JOIN
---------------------------------------------------------------

/* 4.a Listar mantenimientos por conductor
   Incluimos conductores aunque no tengan mantenimientos (LEFT JOIN)
*/
PRINT '==== 4.a Mantenimientos por conductor ====';
SELECT 
    c.IdConductor,
    c.NombreCompleto,
    c.NumeroLicencia,
    m.IdMantenimiento,
    v.Placa,
    v.Modelo,
    m.FechaInicio,
    m.FechaFin,
    m.Descripcion,
    m.Costo
FROM dbo.Conductores c
LEFT JOIN dbo.Mantenimientos m ON c.IdConductor = m.IdConductor
LEFT JOIN dbo.Vehiculos v       ON m.IdVehiculo   = v.IdVehiculo
ORDER BY c.NombreCompleto, m.FechaInicio DESC;
GO

/* 4.b Mostrar vehículos sin mantenimiento en el último mes
   Consideramos "último mes" como últimos 30 días aprox.
*/
PRINT '==== 4.b Vehículos sin mantenimiento en el último mes ====';
DECLARE @HaceUnMes DATE = DATEADD(MONTH, -1, CAST(GETDATE() AS DATE));

SELECT 
    v.IdVehiculo,
    v.Placa,
    v.Modelo,
    v.Anio,
    v.Estado,
    v.Disponible
FROM dbo.Vehiculos v
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Mantenimientos m
    WHERE m.IdVehiculo = v.IdVehiculo
      AND m.FechaInicio >= @HaceUnMes
);
GO

---------------------------------------------------------------
-- 5. Operaciones de conjuntos (UNION, INTERSECT, EXCEPT)
--    Comparar vehículos ACTIVO vs MANTENIMIENTO
---------------------------------------------------------------

/* Aclaración:
   - Activos: Estado = 'ACTIVO'
   - En mantenimiento: Estado = 'MANTENIMIENTO'
*/

PRINT '==== 5.a UNION - Vehículos activos y en mantenimiento (todos, sin duplicar) ====';
SELECT IdVehiculo, Placa, Estado
FROM dbo.Vehiculos
WHERE Estado = 'ACTIVO'
UNION
SELECT IdVehiculo, Placa, Estado
FROM dbo.Vehiculos
WHERE Estado = 'MANTENIMIENTO';
GO

PRINT '==== 5.b INTERSECT - Vehículos que están marcados como ACTIVO y MANTENIMIENTO a la vez ====';
/* En un modelo correcto normalmente no habrá resultados, 
   pero sirve para mostrar el uso de INTERSECT.
*/
SELECT IdVehiculo, Placa
FROM dbo.Vehiculos
WHERE Estado = 'ACTIVO'
INTERSECT
SELECT IdVehiculo, Placa
FROM dbo.Vehiculos
WHERE Estado = 'MANTENIMIENTO';
GO

PRINT '==== 5.c EXCEPT - Vehículos activos que no están marcados como en mantenimiento ====';
SELECT IdVehiculo, Placa
FROM dbo.Vehiculos
WHERE Estado = 'ACTIVO'
EXCEPT
SELECT IdVehiculo, Placa
FROM dbo.Vehiculos
WHERE Estado = 'MANTENIMIENTO';
GO

---------------------------------------------------------------
-- 6. Transacción: registrar mantenimiento y actualizar disponibilidad
---------------------------------------------------------------

/*
   Escenario:
   - Registrar un nuevo mantenimiento para un vehículo específico.
   - Poner el vehículo como no disponible y en estado 'MANTENIMIENTO'.
   - Si algo falla, deshacer todo con ROLLBACK.

   Puedes cambiar los valores de @IdVehiculo y @IdConductor
   para probar diferentes casos.
*/

PRINT '==== 6. Transacción de registro de mantenimiento ====';
DECLARE 
    @IdVehiculoTrans   INT = 2,   -- Cambiar según pruebas
    @IdConductorTrans  INT = 2,   -- Cambiar según pruebas
    @FechaInicioTrans  DATE = CAST(GETDATE() AS DATE),
    @DescripcionTrans  NVARCHAR(200) = N'Mantenimiento correctivo - revisión general',
    @CostoTrans        DECIMAL(10,2) = 300.00;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Validar que el vehículo existe y está disponible
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.Vehiculos 
        WHERE IdVehiculo = @IdVehiculoTrans 
          AND Disponible = 1
    )
    BEGIN
        RAISERROR('El vehículo no existe o no está disponible para mantenimiento.', 16, 1);
    END

    -- (Opcional) Validar que el conductor existe y está activo
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.Conductores
        WHERE IdConductor = @IdConductorTrans
          AND Activo = 1
    )
    BEGIN
        RAISERROR('El conductor no existe o no está activo.', 16, 1);
    END

    -- Insertar el registro de mantenimiento
    INSERT INTO dbo.Mantenimientos (IdVehiculo, IdConductor, FechaInicio, FechaFin, Descripcion, Costo)
    VALUES (@IdVehiculoTrans, @IdConductorTrans, @FechaInicioTrans, NULL, @DescripcionTrans, @CostoTrans);

    -- Actualizar el estado del vehículo
    UPDATE dbo.Vehiculos
    SET Disponible = 0,
        Estado     = 'MANTENIMIENTO'
    WHERE IdVehiculo = @IdVehiculoTrans;

    COMMIT TRANSACTION;
    PRINT 'Transacción completada: mantenimiento registrado y vehículo actualizado.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'Error en la transacción: ' + ERROR_MESSAGE();
END CATCH;
GO

---------------------------------------------------------------
-- FIN DEL SCRIPT
---------------------------------------------------------------
