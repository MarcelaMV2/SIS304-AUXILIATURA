# 🗄️ Funciones — Funciones Definidas por el Usuario en MySQL
> 📅 Base de Datos · _User Defined Functions (UDF) · MySQL Workbench_

---

## 📖 ¿Qué es una Función en MySQL?

Una **función definida por el usuario** (`CREATE FUNCTION`) es un bloque de código SQL que siempre **devuelve un único valor** usando la instrucción `RETURN`. A diferencia de un procedimiento almacenado, una función puede usarse directamente dentro de una consulta `SELECT`, una condición `WHERE` o una asignación `SET`, como si fuera una función nativa de MySQL.

### 🔧 Estructura básica

```sql
DELIMITER $$
CREATE FUNCTION nombre_funcion(param1 TIPO, param2 TIPO) RETURNS TIPO_RETORNO
READS SQL DATA DETERMINISTIC
BEGIN
    DECLARE variable LOCAL_TIPO;

    SELECT columna INTO variable FROM tabla WHERE condicion;

    RETURN variable;
END $$
DELIMITER ;

-- Llamada: se puede usar como cualquier expresión
SET @resultado = nombre_funcion(valor1, valor2);
SELECT @resultado AS 'Etiqueta';
```

### 📌 Diferencias clave: Función vs Procedimiento

| Característica | `FUNCTION` | `PROCEDURE` |
|---|---|---|
| Devuelve valor | Siempre, con `RETURN` | Opcional, con `OUT` |
| Cómo se llama | `SET @v = funcion()` o dentro de `SELECT` | `CALL procedimiento()` |
| Parámetros de salida | No tiene `OUT`, solo `RETURN` | Puede tener `OUT` e `INOUT` |
| Uso en consultas | Sí, directamente en `SELECT`/`WHERE` | No |

### 📌 Conceptos clave de este tema

| Elemento | Para qué sirve |
|---|---|
| `RETURNS TIPO` | Declara el tipo de dato que la función devolverá |
| `READS SQL DATA` | Indica que la función solo **lee** datos, no los modifica |
| `DETERMINISTIC` | Garantiza que para los mismos parámetros siempre devuelve el mismo resultado |
| `RETURN variable` | Termina la función y entrega el valor al exterior |
| `MAX(col)` | Devuelve el valor máximo de una columna |
| `MIN(col)` | Devuelve el valor mínimo de una columna |
| `COUNT(*)` | Cuenta el número de filas que cumplen una condición |
| `SUM(col)` | Suma todos los valores de una columna |
| `AVG(col)` | Calcula el promedio de una columna numérica |
| `GROUP BY` | Agrupa filas para aplicar funciones de agregado por grupo |
| `ORDER BY ... DESC` | Ordena resultados de mayor a menor |
| `LIMIT 1` | Toma solo el primer resultado (obligatorio con `SELECT INTO` cuando hay varios) |
| `MONTH(fecha)` | Extrae el mes de un campo de fecha |
| `YEAR(fecha)` | Extrae el año de un campo de fecha |
| `DATE(campo)` | Extrae solo la parte de fecha de un `DATETIME` |
| `BETWEEN v1 AND v2` | Filtra valores dentro de un rango inclusivo |

---

## 🧩 Función 01 — Costo más alto entre repuestos con cantidad superior a un mínimo

### 📝 Enunciado

Crear una función que reciba un valor mínimo de cantidad como parámetro y devuelva el **costo más alto** registrado en la tabla `COMPRA` entre los registros cuya cantidad supere ese valor.

---

### 🧠 Resolución

Se declara una variable local `COSTOMAX` de tipo `FLOAT`.  
Se aplica `MAX(COSTO)` filtrando únicamente los registros donde `CANTIDAD > CMIN`.  
El resultado se carga en la variable con `SELECT INTO` y se devuelve con `RETURN`.

```sql
DELIMITER $$
CREATE FUNCTION FUN1(CMIN INT) RETURNS FLOAT
READS SQL DATA DETERMINISTIC
BEGIN
    DECLARE COSTOMAX FLOAT;

    SELECT MAX(COSTO) INTO COSTOMAX
    FROM COMPRA
    WHERE CANTIDAD > CMIN;

    RETURN COSTOMAX;
END $$
DELIMITER ;

SET @CMAX = FUN1(16);
SELECT @CMAX AS 'COSTO MAXIMO';
```

---

## 🧩 Función 02 — Total de entregas de un encargado en un mes y año específicos

### 📝 Enunciado

Crear una función que reciba el **ITEM de un encargado**, el **mes** y el **año** como parámetros, y devuelva el **número total de entregas** realizadas por ese encargado durante ese período.

---

### 🧠 Resolución

Se usa `COUNT(*)` para contar cuántas filas de la tabla `ENTREGA` corresponden al encargado indicado en el mes y año dados.  
Los filtros `MONTH(FECHAE) = MES` y `YEAR(FECHAE) = ANIO` permiten acotar exactamente el período solicitado.  
El conteo se guarda en `CEN` y se devuelve con `RETURN`.

```sql
DELIMITER $$
CREATE FUNCTION FUN2(ITEN INT, MES INT, ANIO INT) RETURNS INT
READS SQL DATA DETERMINISTIC
BEGIN
    DECLARE CEN INT;

    SELECT COUNT(*) INTO CEN
    FROM ENTREGA
    WHERE ITEM = ITEN
      AND MONTH(FECHAE) = MES
      AND YEAR(FECHAE)  = ANIO;

    RETURN CEN;
END $$
DELIMITER ;

SET @CANE = FUN2(10010, 9, 2024);
SELECT @CANE AS 'CANTIDAD DE ENTREGAS';
```

> 💡 **Nota:** `COUNT(*)` cuenta filas, no suma cantidades. Si se quisiera la suma de unidades entregadas, se usaría `SUM(CANTIDADE)` en su lugar.

---

## 🧩 Función 03 — Total de repuestos entregados entre dos fechas

### 📝 Enunciado

Crear una función que reciba **dos fechas** (inicial y final) y devuelva el **número total de unidades de repuestos entregadas** entre esas fechas, consultando la tabla `ENTREGA`.

---

### 🧠 Resolución

Se aplica la lógica de **intercambio de fechas** con una variable auxiliar `AUX` para que el rango siempre sea correcto sin importar el orden de los parámetros.  
Se usa `SUM(CANTIDADE)` con `BETWEEN` para acumular todas las unidades entregadas en ese período.

```sql
DELIMITER $$
CREATE FUNCTION FUN3(F1 DATE, F2 DATE) RETURNS INT
READS SQL DATA DETERMINISTIC
BEGIN
    DECLARE TOTAL INT;
    DECLARE AUX   DATE;

    IF (F1 > F2) THEN
        SET AUX = F1;
        SET F1  = F2;
        SET F2  = AUX;
    END IF;

    SELECT SUM(CANTIDADE) INTO TOTAL
    FROM ENTREGA
    WHERE DATE(FECHAE) BETWEEN F1 AND F2;

    RETURN TOTAL;
END $$
DELIMITER ;

SET @TOT = FUN3('2020-10-10', '2025-10-10');
SELECT @TOT AS 'CANTIDAD DE ENTREGA TOTAL';
```

---

## 🧩 Función 04 — Repuesto con mayor cantidad comprada en un año

### 📝 Enunciado

Crear una función que reciba un **año** como parámetro y devuelva la **descripción del repuesto** con la mayor cantidad comprada durante ese año, consultando las tablas `COMPRA` y `REPUESTO`.

---

### 🧠 Resolución

La solución requiere dos pasos: primero obtener el código del repuesto más comprado, luego buscar su descripción.  
Se declaran tres variables: `REP` (descripción final), `CMAX` (cantidad máxima, auxiliar) y `COR` (código del repuesto).  
Se agrupa por `CODIGO`, se ordena por cantidad descendente y se toma el primero con `LIMIT 1`.  
Con el código obtenido, se hace una segunda consulta a `REPUESTO` para obtener la descripción.

```sql
DELIMITER $$
CREATE FUNCTION FUN4(ANIO INT) RETURNS VARCHAR(50)
READS SQL DATA DETERMINISTIC
BEGIN
    DECLARE REP  VARCHAR(50);
    DECLARE CMAX INT;
    DECLARE COR  CHAR(6);

    SELECT CODIGO, MAX(CANTIDAD) INTO COR, CMAX
    FROM COMPRA
    WHERE YEAR(FECHA) = ANIO
    GROUP BY CODIGO
    ORDER BY MAX(CANTIDAD) DESC
    LIMIT 1;

    SELECT DESCRIPCION INTO REP
    FROM REPUESTO
    WHERE CODIGO = COR;

    RETURN REP;
END $$
DELIMITER ;

SET @REPU = FUN4(2025);
SELECT @REPU AS 'REPUESTO MAS COMPRADO';
```

> 💡 **Nota:** En esta función se encadenan dos consultas dentro del mismo `BEGIN...END`. La variable local `COR` actúa como puente entre ambas: guarda el resultado de la primera y lo usa como filtro en la segunda.

---

## 🧩 Función 05 — Total de repuestos vendidos por un proveedor en un rango de costos

### 📝 Enunciado

Crear una función que reciba el **NIT del proveedor** y un **rango de costos** (mínimo y máximo), y devuelva el **total de unidades** compradas a ese proveedor cuyos costos estén dentro de ese rango.

---

### 🧠 Resolución

Se filtra la tabla `COMPRA` por `NIT` del proveedor y por el rango de costos usando `BETWEEN CMIN AND CMAX`.  
La suma de `CANTIDAD` de esos registros se guarda en `TVENDIDOS` y se devuelve directamente.

```sql
DELIMITER $$
CREATE FUNCTION FUN5(NIP CHAR(10), CMIN INT, CMAX INT) RETURNS INT
READS SQL DATA DETERMINISTIC
BEGIN
    DECLARE TVENDIDOS INT;

    SELECT SUM(CANTIDAD) INTO TVENDIDOS
    FROM COMPRA
    WHERE NIT   = NIP
      AND COSTO BETWEEN CMIN AND CMAX;

    RETURN TVENDIDOS;
END $$
DELIMITER ;

SET @TOTVEN = FUN5('1011112450', 100, 300);
SELECT @TOTVEN AS 'TOTAL DE REPUESTOS VENDIDOS';
```

---

## 🧩 Función 06 — Proveedor con más repuestos vendidos en un mes y año

### 📝 Enunciado

Crear una función que reciba el **mes** y el **año** como parámetros y devuelva el **nombre del proveedor** que haya vendido la mayor cantidad de repuestos durante ese período, a partir de la tabla `COMPRA`.

---

### 🧠 Resolución

Al igual que en la Función 04, se necesitan dos pasos: primero identificar el NIT del proveedor con más ventas, luego obtener su nombre.  
Se agrupa por `NIT`, se ordena por cantidad máxima descendente y se toma el primero.  
Con el `NIT` obtenido en `NIP`, se consulta la tabla `PROVEEDOR` para recuperar el nombre y devolverlo.

```sql
DELIMITER $$
CREATE FUNCTION FUN6(MES INT, ANIO INT) RETURNS VARCHAR(50)
READS SQL DATA DETERMINISTIC
BEGIN
    DECLARE PROV VARCHAR(50);
    DECLARE NIP  CHAR(10);
    DECLARE CMAX INT;

    SELECT NIT, MAX(CANTIDAD) INTO NIP, CMAX
    FROM COMPRA
    WHERE MONTH(FECHA) = MES
      AND YEAR(FECHA)  = ANIO
    GROUP BY NIT
    ORDER BY CMAX DESC
    LIMIT 1;

    SELECT NOMBREP INTO PROV
    FROM PROVEEDOR
    WHERE NIT = NIP;

    RETURN PROV;
END $$
DELIMITER ;

SET @PROV = FUN6(9, 2025);
SELECT @PROV AS 'PROVEEDOR CON MAS VENTAS';
```

---

## 🧩 Función 07 — Costo promedio de compra de un repuesto

### 📝 Enunciado

Crear una función que reciba el **código de un repuesto** y devuelva el **costo promedio** de todas las compras registradas para ese repuesto en la tabla `COMPRA`.

---

### 🧠 Resolución

Es la función más directa del conjunto: se aplica `AVG(COSTO)` filtrando por el código del repuesto recibido.  
El resultado se guarda en `PROM` y se devuelve. No se necesitan validaciones adicionales porque `AVG` sobre un conjunto vacío devuelve `NULL`.

```sql
DELIMITER $$
CREATE FUNCTION FUN7(CODR CHAR(6)) RETURNS FLOAT
READS SQL DATA DETERMINISTIC
BEGIN
    DECLARE PROM FLOAT(6,2);

    SELECT AVG(COSTO) INTO PROM
    FROM COMPRA
    WHERE CODIGO = CODR;

    RETURN PROM;
END $$
DELIMITER ;

SET @PROMC = FUN7('R-0001');
SELECT @PROMC AS 'PROMEDIO REPUESTO';
```

> 💡 **Nota:** `AVG()` ignora automáticamente los valores `NULL`. Si no existe ningún registro para ese código, la función devolverá `NULL` en lugar de `0`.

---

[⬅️ Volver al inicio](https://marcelamv2.github.io/SIS304-AUXILIATURA/) &nbsp;|&nbsp; [🗃️ Ver código SQL](./repuestos_funciones.sql)