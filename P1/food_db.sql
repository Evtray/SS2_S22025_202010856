-- =============================================

-- Crear base de datos para el Data Warehouse
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DW_SGFOOD')
BEGIN
    CREATE DATABASE DW_SGFOOD;
END
GO

USE DW_SGFOOD;
GO

-- =============================================
-- ELIMINACIÓN DE TABLAS (para re-ejecución del script)
-- =============================================
IF OBJECT_ID('Fact_Ventas', 'U') IS NOT NULL DROP TABLE Fact_Ventas;
IF OBJECT_ID('Fact_Compras', 'U') IS NOT NULL DROP TABLE Fact_Compras;
IF OBJECT_ID('Dim_Productos', 'U') IS NOT NULL DROP TABLE Dim_Productos;
IF OBJECT_ID('Dim_Clientes', 'U') IS NOT NULL DROP TABLE Dim_Clientes;
IF OBJECT_ID('Dim_Proveedores', 'U') IS NOT NULL DROP TABLE Dim_Proveedores;
IF OBJECT_ID('Dim_Vendedores', 'U') IS NOT NULL DROP TABLE Dim_Vendedores;
IF OBJECT_ID('Dim_Sucursales', 'U') IS NOT NULL DROP TABLE Dim_Sucursales;
IF OBJECT_ID('Dim_Tiempo', 'U') IS NOT NULL DROP TABLE Dim_Tiempo;
GO

-- =============================================
-- DIMENSIÓN TIEMPO
-- =============================================
CREATE TABLE Dim_Tiempo (
    TiempoID INT PRIMARY KEY,           -- Formato YYYYMMDD
    Fecha DATE NOT NULL,
    Año INT NOT NULL,
    Mes INT NOT NULL,
    Nombre_Mes VARCHAR(20) NOT NULL,
    Trimestre VARCHAR(2) NOT NULL,      -- Q1, Q2, Q3, Q4
    Semana_Año INT NOT NULL,
    Dia_Semana INT NOT NULL,            -- 1=Lunes, 7=Domingo
    Nombre_Dia VARCHAR(20) NOT NULL,
    Es_Fin_Semana BIT DEFAULT 0,
    Es_Feriado BIT DEFAULT 0,
    Fecha_Creacion DATETIME DEFAULT GETDATE()
);

-- Índices para optimizar consultas
CREATE NONCLUSTERED INDEX IX_Dim_Tiempo_Año ON Dim_Tiempo(Año);
CREATE NONCLUSTERED INDEX IX_Dim_Tiempo_Mes ON Dim_Tiempo(Mes);
CREATE NONCLUSTERED INDEX IX_Dim_Tiempo_Trimestre ON Dim_Tiempo(Trimestre);
GO

-- =============================================
-- DIMENSIÓN PRODUCTOS (basada en ambos CSV)
-- =============================================
CREATE TABLE Dim_Productos (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    CodProducto VARCHAR(20) NOT NULL UNIQUE,
    NombreProducto VARCHAR(200) NOT NULL,
    MarcaProducto VARCHAR(100) NOT NULL,
    Categoria VARCHAR(50) NOT NULL,
    Activo BIT DEFAULT 1,
    Fecha_Creacion DATETIME DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME DEFAULT GETDATE()
);

-- Índices para optimizar consultas
CREATE NONCLUSTERED INDEX IX_Dim_Productos_Categoria ON Dim_Productos(Categoria);
CREATE NONCLUSTERED INDEX IX_Dim_Productos_Marca ON Dim_Productos(MarcaProducto);
CREATE NONCLUSTERED INDEX IX_Dim_Productos_Codigo ON Dim_Productos(CodProducto);
GO

-- =============================================
-- DIMENSIÓN CLIENTES (desde ventas.csv)
-- =============================================
CREATE TABLE Dim_Clientes (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    CodCliente VARCHAR(20) NOT NULL UNIQUE,
    NombreCliente VARCHAR(200) NOT NULL,
    TipoCliente VARCHAR(30) NOT NULL,       -- Del CSV: tipo de cliente
    Activo BIT DEFAULT 1,
    Fecha_Creacion DATETIME DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME DEFAULT GETDATE()
);

-- Índices para optimizar consultas
CREATE NONCLUSTERED INDEX IX_Dim_Clientes_Tipo ON Dim_Clientes(TipoCliente);
CREATE NONCLUSTERED INDEX IX_Dim_Clientes_Codigo ON Dim_Clientes(CodCliente);
CREATE NONCLUSTERED INDEX IX_Dim_Clientes_Nombre ON Dim_Clientes(NombreCliente);
GO

-- =============================================
-- DIMENSIÓN PROVEEDORES (desde compras.csv)
-- =============================================
CREATE TABLE Dim_Proveedores (
    ProveedorID INT IDENTITY(1,1) PRIMARY KEY,
    CodProveedor VARCHAR(20) NOT NULL UNIQUE,
    NombreProveedor VARCHAR(200) NOT NULL,
    Activo BIT DEFAULT 1,
    Fecha_Creacion DATETIME DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME DEFAULT GETDATE()
);

-- Índices para optimizar consultas
CREATE NONCLUSTERED INDEX IX_Dim_Proveedores_Codigo ON Dim_Proveedores(CodProveedor);
CREATE NONCLUSTERED INDEX IX_Dim_Proveedores_Nombre ON Dim_Proveedores(NombreProveedor);
GO

-- =============================================
-- DIMENSIÓN VENDEDORES (desde ventas.csv)
-- =============================================
CREATE TABLE Dim_Vendedores (
    VendedorID INT IDENTITY(1,1) PRIMARY KEY,
    CodVendedor VARCHAR(20) NOT NULL UNIQUE,
    NombreVendedor VARCHAR(100) NOT NULL,
    Activo BIT DEFAULT 1,
    Fecha_Creacion DATETIME DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME DEFAULT GETDATE()
);

-- Índices para optimizar consultas
CREATE NONCLUSTERED INDEX IX_Dim_Vendedores_Codigo ON Dim_Vendedores(CodVendedor);
CREATE NONCLUSTERED INDEX IX_Dim_Vendedores_Nombre ON Dim_Vendedores(NombreVendedor);
GO

-- =============================================
-- DIMENSIÓN SUCURSALES (presente en ambos CSV)
-- =============================================
CREATE TABLE Dim_Sucursales (
    SucursalID INT IDENTITY(1,1) PRIMARY KEY,
    CodSucursal VARCHAR(20) NOT NULL UNIQUE,
    NombreSucursal VARCHAR(100) NOT NULL,
    Region VARCHAR(30) NOT NULL,            -- Del CSV: Norte, Sur, Este, Oeste, Central
    Departamento VARCHAR(50) NOT NULL,      -- Del CSV: departamento de Guatemala
    Activo BIT DEFAULT 1,
    Fecha_Creacion DATETIME DEFAULT GETDATE(),
    Fecha_Modificacion DATETIME DEFAULT GETDATE()
);

-- Índices para optimizar consultas
CREATE NONCLUSTERED INDEX IX_Dim_Sucursales_Region ON Dim_Sucursales(Region);
CREATE NONCLUSTERED INDEX IX_Dim_Sucursales_Departamento ON Dim_Sucursales(Departamento);
CREATE NONCLUSTERED INDEX IX_Dim_Sucursales_Codigo ON Dim_Sucursales(CodSucursal);
GO

-- =============================================
-- TABLA DE HECHOS - VENTAS (basada en ventas.csv)
-- =============================================
CREATE TABLE Fact_Ventas (
    VentaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Claves foráneas (Dimensiones)
    ProductoID INT NOT NULL,
    ClienteID INT NOT NULL,
    VendedorID INT NOT NULL,
    SucursalID INT NOT NULL,
    TiempoID INT NOT NULL,
    
    -- Métricas del CSV
    Unidades INT NOT NULL,                  -- Del CSV: Unidades vendidas
    PrecioUnitario DECIMAL(15,4) NOT NULL,  -- Del CSV: PrecioUnitario
    
    -- Métricas calculadas
    Total_Venta AS (Unidades * PrecioUnitario) PERSISTED,
    
    -- Auditoría
    Fecha_Creacion DATETIME DEFAULT GETDATE(),
    Usuario_Creacion VARCHAR(50) DEFAULT SYSTEM_USER,
    
    -- Constraints de integridad referencial
    CONSTRAINT FK_Fact_Ventas_Producto FOREIGN KEY (ProductoID) REFERENCES Dim_Productos(ProductoID),
    CONSTRAINT FK_Fact_Ventas_Cliente FOREIGN KEY (ClienteID) REFERENCES Dim_Clientes(ClienteID),
    CONSTRAINT FK_Fact_Ventas_Vendedor FOREIGN KEY (VendedorID) REFERENCES Dim_Vendedores(VendedorID),
    CONSTRAINT FK_Fact_Ventas_Sucursal FOREIGN KEY (SucursalID) REFERENCES Dim_Sucursales(SucursalID),
    CONSTRAINT FK_Fact_Ventas_Tiempo FOREIGN KEY (TiempoID) REFERENCES Dim_Tiempo(TiempoID),
    
    -- Validaciones de negocio
    CONSTRAINT CK_Fact_Ventas_Unidades CHECK (Unidades > 0),
    CONSTRAINT CK_Fact_Ventas_Precio CHECK (PrecioUnitario > 0)
);

-- Índices para optimizar consultas de la tabla de hechos
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_TiempoID ON Fact_Ventas(TiempoID);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_ProductoID ON Fact_Ventas(ProductoID);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_SucursalID ON Fact_Ventas(SucursalID);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_ClienteID ON Fact_Ventas(ClienteID);
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_VendedorID ON Fact_Ventas(VendedorID);

-- Índice compuesto para consultas frecuentes
CREATE NONCLUSTERED INDEX IX_Fact_Ventas_Tiempo_Producto ON Fact_Ventas(TiempoID, ProductoID) 
INCLUDE (Total_Venta, Unidades);
GO

-- =============================================
-- TABLA DE HECHOS - COMPRAS (basada en compras.csv)
-- =============================================
CREATE TABLE Fact_Compras (
    CompraID BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Claves foráneas (Dimensiones)
    ProductoID INT NOT NULL,
    ProveedorID INT NOT NULL,
    SucursalID INT NOT NULL,
    TiempoID INT NOT NULL,
    
    -- Métricas del CSV
    Unidades INT NOT NULL,                  -- Del CSV: Unidades compradas
    CostoUnitario DECIMAL(15,4) NOT NULL,   -- Del CSV: CostoUnitario
    
    -- Métricas calculadas
    Total_Compra AS (Unidades * CostoUnitario) PERSISTED,
    
    -- Auditoría
    Fecha_Creacion DATETIME DEFAULT GETDATE(),
    Usuario_Creacion VARCHAR(50) DEFAULT SYSTEM_USER,
    
    -- Constraints de integridad referencial
    CONSTRAINT FK_Fact_Compras_Producto FOREIGN KEY (ProductoID) REFERENCES Dim_Productos(ProductoID),
    CONSTRAINT FK_Fact_Compras_Proveedor FOREIGN KEY (ProveedorID) REFERENCES Dim_Proveedores(ProveedorID),
    CONSTRAINT FK_Fact_Compras_Sucursal FOREIGN KEY (SucursalID) REFERENCES Dim_Sucursales(SucursalID),
    CONSTRAINT FK_Fact_Compras_Tiempo FOREIGN KEY (TiempoID) REFERENCES Dim_Tiempo(TiempoID),
    
    -- Validaciones de negocio
    CONSTRAINT CK_Fact_Compras_Unidades CHECK (Unidades > 0),
    CONSTRAINT CK_Fact_Compras_Costo CHECK (CostoUnitario > 0)
);

-- Índices para optimizar consultas de la tabla de hechos
CREATE NONCLUSTERED INDEX IX_Fact_Compras_TiempoID ON Fact_Compras(TiempoID);
CREATE NONCLUSTERED INDEX IX_Fact_Compras_ProductoID ON Fact_Compras(ProductoID);
CREATE NONCLUSTERED INDEX IX_Fact_Compras_ProveedorID ON Fact_Compras(ProveedorID);
CREATE NONCLUSTERED INDEX IX_Fact_Compras_SucursalID ON Fact_Compras(SucursalID);

-- Índice compuesto para consultas frecuentes
CREATE NONCLUSTERED INDEX IX_Fact_Compras_Tiempo_Proveedor ON Fact_Compras(TiempoID, ProveedorID) 
INCLUDE (Total_Compra, Unidades);
GO

-- =============================================
-- VISTAS PARA ANÁLISIS (Basadas en la estructura real)
-- =============================================

-- Vista consolidada de ventas con todas las dimensiones
CREATE VIEW VW_Ventas_Completas AS
SELECT 
    fv.VentaID,
    dt.Fecha,
    dt.Año,
    dt.Mes,
    dt.Nombre_Mes,
    dt.Trimestre,
    dc.CodCliente,
    dc.NombreCliente,
    dc.TipoCliente,
    dv.CodVendedor,
    dv.NombreVendedor,
    dp.CodProducto,
    dp.NombreProducto,
    dp.MarcaProducto,
    dp.Categoria,
    ds.CodSucursal,
    ds.NombreSucursal,
    ds.Region,
    ds.Departamento,
    fv.Unidades,
    fv.PrecioUnitario,
    fv.Total_Venta
FROM Fact_Ventas fv
INNER JOIN Dim_Tiempo dt ON fv.TiempoID = dt.TiempoID
INNER JOIN Dim_Clientes dc ON fv.ClienteID = dc.ClienteID
INNER JOIN Dim_Vendedores dv ON fv.VendedorID = dv.VendedorID
INNER JOIN Dim_Productos dp ON fv.ProductoID = dp.ProductoID
INNER JOIN Dim_Sucursales ds ON fv.SucursalID = ds.SucursalID;
GO

-- Vista consolidada de compras con todas las dimensiones
CREATE VIEW VW_Compras_Completas AS
SELECT 
    fc.CompraID,
    dt.Fecha,
    dt.Año,
    dt.Mes,
    dt.Nombre_Mes,
    dt.Trimestre,
    dpr.CodProveedor,
    dpr.NombreProveedor,
    dp.CodProducto,
    dp.NombreProducto,
    dp.MarcaProducto,
    dp.Categoria,
    ds.CodSucursal,
    ds.NombreSucursal,
    ds.Region,
    ds.Departamento,
    fc.Unidades,
    fc.CostoUnitario,
    fc.Total_Compra
FROM Fact_Compras fc
INNER JOIN Dim_Tiempo dt ON fc.TiempoID = dt.TiempoID
INNER JOIN Dim_Proveedores dpr ON fc.ProveedorID = dpr.ProveedorID
INNER JOIN Dim_Productos dp ON fc.ProductoID = dp.ProductoID
INNER JOIN Dim_Sucursales ds ON fc.SucursalID = ds.SucursalID;
GO

-- =============================================
-- PROCEDIMIENTOS PARA GENERAR DIMENSIÓN TIEMPO
-- =============================================
CREATE PROCEDURE SP_Generar_Dimension_Tiempo
    @FechaInicio DATE,
    @FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @FechaActual DATE = @FechaInicio;
    
    WHILE @FechaActual <= @FechaFin
    BEGIN
        -- Verificar si ya existe la fecha
        IF NOT EXISTS (SELECT 1 FROM Dim_Tiempo WHERE Fecha = @FechaActual)
        BEGIN
            INSERT INTO Dim_Tiempo (TiempoID, Fecha, Año, Mes, Nombre_Mes, Trimestre, Semana_Año, 
                                   Dia_Semana, Nombre_Dia, Es_Fin_Semana, Es_Feriado)
            VALUES (
                YEAR(@FechaActual) * 10000 + MONTH(@FechaActual) * 100 + DAY(@FechaActual),
                @FechaActual,
                YEAR(@FechaActual),
                MONTH(@FechaActual),
                CASE MONTH(@FechaActual)
                    WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
                    WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
                    WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
                    WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
                END,
                'Q' + CAST(CEILING(MONTH(@FechaActual) / 3.0) AS VARCHAR(1)),
                DATEPART(WEEK, @FechaActual),
                DATEPART(WEEKDAY, @FechaActual),
                CASE DATEPART(WEEKDAY, @FechaActual)
                    WHEN 1 THEN 'Domingo' WHEN 2 THEN 'Lunes' WHEN 3 THEN 'Martes'
                    WHEN 4 THEN 'Miércoles' WHEN 5 THEN 'Jueves' WHEN 6 THEN 'Viernes'
                    WHEN 7 THEN 'Sábado'
                END,
                CASE WHEN DATEPART(WEEKDAY, @FechaActual) IN (1, 7) THEN 1 ELSE 0 END,
                0  -- Se puede actualizar manualmente para feriados específicos
            );
        END
        
        SET @FechaActual = DATEADD(DAY, 1, @FechaActual);
    END;
    
    PRINT 'Dimensión Tiempo generada desde ' + CONVERT(VARCHAR, @FechaInicio) + ' hasta ' + CONVERT(VARCHAR, @FechaFin);
END;
GO

-- =============================================
-- CONSULTAS DE LA PRÁCTICA (Basadas en la estructura real)
-- =============================================

-- Consulta 1: Total de compras y ventas por año
GO
PRINT 'Consulta 1: Total de compras y ventas por año';
PRINT 'SELECT dt.Año, SUM(fv.Total_Venta) as Total_Ventas, SUM(fc.Total_Compra) as Total_Compras FROM...';
GO

-- Consulta 2: Productos con pérdida (precio de venta menor al costo de compra)
PRINT 'Consulta 2: Productos con pérdida';
PRINT 'Comparar PrecioUnitario de ventas vs CostoUnitario de compras por producto';
GO

-- Consulta 3: Top 5 productos más vendidos por unidades
PRINT 'Consulta 3: Top 5 productos más vendidos';
PRINT 'SELECT TOP 5 dp.NombreProducto, SUM(fv.Unidades) FROM Fact_Ventas fv...';
GO

-- Consulta 4: Ingresos por región y año
PRINT 'Consulta 4: Ingresos por región y año';
PRINT 'SELECT ds.Region, dt.Año, SUM(fv.Total_Venta) FROM VW_Ventas_Completas...';
GO

-- Consulta 5: Proveedores con mayor volumen de compras
PRINT 'Consulta 5: Proveedores con mayor volumen';
PRINT 'SELECT dpr.NombreProveedor, SUM(fc.Total_Compra) FROM VW_Compras_Completas...';
GO

-- =============================================
-- DATOS INICIALES
-- =============================================

-- Generar dimensión tiempo para 2023-2025 (rango amplio para los CSV)
EXEC SP_Generar_Dimension_Tiempo '2023-01-01', '2025-12-31';
GO

-- =============================================
-- VERIFICACIÓN FINAL Y ESTRUCTURA DEL MODELO
-- =============================================
PRINT '';
PRINT '===============================================';
PRINT 'MODELO ESTRELLA SG-FOOD CREADO EXITOSAMENTE';
PRINT '===============================================';
PRINT '';
PRINT 'ESTRUCTURA DEL MODELO:';
PRINT '';
PRINT 'DIMENSIONES:';
PRINT '- Dim_Tiempo: ' + CAST((SELECT COUNT(*) FROM Dim_Tiempo) AS VARCHAR(10)) + ' registros creados';
PRINT '- Dim_Productos: Listo para ETL (CodProducto, NombreProducto, MarcaProducto, Categoria)';
PRINT '- Dim_Clientes: Listo para ETL (CodCliente, NombreCliente, TipoCliente)';
PRINT '- Dim_Proveedores: Listo para ETL (CodProveedor, NombreProveedor)';
PRINT '- Dim_Vendedores: Listo para ETL (CodVendedor, NombreVendedor)';
PRINT '- Dim_Sucursales: Listo para ETL (CodSucursal, NombreSucursal, Region, Departamento)';
PRINT '';
PRINT 'TABLAS DE HECHOS:';
PRINT '- Fact_Ventas: ProductoID, ClienteID, VendedorID, SucursalID, TiempoID';
PRINT '  Métricas: Unidades, PrecioUnitario, Total_Venta (calculado)';
PRINT '- Fact_Compras: ProductoID, ProveedorID, SucursalID, TiempoID';
PRINT '  Métricas: Unidades, CostoUnitario, Total_Compra (calculado)';
PRINT '';
PRINT 'MAPEO CON CSV:';
PRINT 'ventas.csv -> Fact_Ventas + Dim_Clientes + Dim_Vendedores + Dim_Productos + Dim_Sucursales';
PRINT 'compras.csv -> Fact_Compras + Dim_Proveedores + Dim_Productos + Dim_Sucursales';
PRINT '';
PRINT 'VISTAS DISPONIBLES:';
PRINT '- VW_Ventas_Completas: Vista desnormalizada para análisis de ventas';
PRINT '- VW_Compras_Completas: Vista desnormalizada para análisis de compras';
PRINT '';
PRINT '¡Listo para configurar el proceso ETL en SSIS!';
GO