# Práctica 2 

## Introducción 

Se desarrollaron dos cubos multidimensionales en SQL Server Analysis Services (SSAS) basados en el modelo estrella del Data Warehouse creado en la Práctica 1:

## Descripción del Cubo OLAP

- **SGFOODVentas.cube**: Analiza las ventas por producto, cliente, vendedor, sucursal y tiempo.
- **SGFOODCompras.cube**: Analiza las compras por proveedor, producto, sucursal y tiempo.

Cada cubo contiene:
- **Medidas clave**: TotalVenta, TotalCosto, UnidadesVendidas, etc.
- **Dimensiones**: Tiempo, Producto, Sucursal, Cliente, Vendedor, Proveedor
- **Jerarquías naturales**:
  - Año → Mes → Día
  - Región → Sucursal
  - Categoría → Producto

Estos cubos permiten una navegación interactiva para responder preguntas estratégicas sobre desempeño, tendencias y cumplimiento de metas.


## KPIs Definidos en SSAS

Se configuraron directamente en SSAS mediante expresiones MDX y la opción KPIs, cumpliendo con el requisito de implementación en el motor de análisis.

### KPIs implementados

#### 1. Cumplimiento de Meta de Ventas

#### Medida de apoyo

```
[Measures].[Meta Ventas] = 1000000
```

#### Valor KPI

```
[Measures].[Total Venta] / [Measures].[Meta Ventas]
```

#### Meta 

100% (cumplimiento total)

#### Status

```
CASE 
  WHEN [Measures].[Total Venta] >= [Measures].[Meta Ventas] THEN 1
  WHEN [Measures].[Total Venta] >= [Measures].[Meta Ventas] * 0.8 THEN 0
  ELSE -1
END
```

## Tablero en Power BI

Se desarrolló un dashboard interactivo conectado directamente al cubo OLAP mediante Live Connection.

El tablero incluye:

* **Compras**

![compras](/Practica_2/imgs/compras.png)

* **ventas**

![ventas](/Practica_2/imgs/ventas.png)


Esto facilita la exploración de datos en tiempo real y la toma de decisiones ejecutivas.

## Guía de Conexión Power BI - SSAS

1. Abrir Power BI Desktop.
2. Seleccionar un informe en blanco.
3. Seleccionar Obtener datos de otro origen > Base de datos SQL Server Analysis Services.
4. Ingresar el servidor SSAS y elegir el modo Multidimensional.
5. Conectar en modo Live Connection para mantener los cálculos en SSAS.
6. Por ultimo seleccionar la base de datos.

## Conclusiones
- El cubo OLAP facilita el análisis estratégico mediante jerarquías y medidas clave.  
- Los KPIs definidos permiten evaluar el rendimiento global de SG-FOOD.  
- Power BI potencia la visualización y usabilidad de la información, promoviendo una toma de decisiones más ágil y fundamentada.  