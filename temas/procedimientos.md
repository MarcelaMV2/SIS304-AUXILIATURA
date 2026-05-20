# 🗄️ Procedimientos Almacenados
> 📅 Base de Datos · _Stored Procedures de Consulta · MySQL Workbench_

---

## 📖 ¿Qué es un Procedimiento Almacenado sin Parámetros?

Un **procedimiento almacenado sin parámetros** es el tipo más simple: se crea una vez con su lógica de consulta fija, y cada vez que se llama con `CALL` ejecuta exactamente eso. No recibe valores externos ni devuelve nada fuera del resultado de cuadrícula.

Son ideales para consultas frecuentes, reportes fijos o vistas dinámicas que se reutilizan en el sistema.

### 🔧 Estructura básica

```sql
DELIMITER $$
CREATE PROCEDURE NOMBRE_PROCEDIMIENTO()
BEGIN
    -- Consultas, JOINs, filtros, agrupaciones...
    SELECT columnas FROM tabla WHERE condicion;
END $$
DELIMITER ;

-- Llamada (sin paréntesis con argumentos)
CALL NOMBRE_PROCEDIMIENTO;
```

### 📌 Conceptos utilizados en estos ejercicios

| Elemento | Para qué sirve |
|---|---|
| `INNER JOIN` | Combina filas de dos tablas donde la condición de unión se cumple en ambas |
| `WHERE` | Filtra filas antes de agrupar o mostrar resultados |
| `GROUP BY` | Agrupa filas para aplicar funciones de agregado por categoría |
| `HAVING` | Filtra grupos después de aplicar `GROUP BY` (no necesita `SELECT` dentro) |
| `ORDER BY ASC / DESC` | Ordena resultados de forma ascendente (A→Z, 0→9) o descendente |
| `LIKE 'X%'` | Filtra texto que empieza con X |
| `LIKE '%X'` | Filtra texto que termina con X |
| `LIKE '__X%'` | Filtra texto con X en la tercera posición (`_` representa un carácter) |
| `SUM(col)` | Suma todos los valores de una columna |
| `AVG(col)` | Calcula el promedio de una columna |
| `MAX(col)` | Devuelve el valor máximo |
| `MIN(col)` | Devuelve el valor mínimo |
| `COUNT(*)` | Cuenta el número de filas que cumplen la condición |
| `YEAR(fecha)` | Extrae el año de un campo de fecha |
| `MONTH(fecha)` | Extrae el mes de un campo de fecha |
| `DAY(fecha)` | Extrae el día de un campo de fecha |
| `CURDATE()` | Devuelve la fecha actual del sistema |
| `(SELECT ...)` en `WHERE` | Subconsulta: permite usar el resultado de otra consulta como valor de comparación |
| `DECLARE var TIPO` | Crea una variable local que solo vive dentro del `BEGIN...END` |
| `SELECT ... INTO var` | Carga el resultado de una consulta en una variable local |

---

## 🧩 Ejercicio 01 — Lista de repuestos con costo real entre dos valores

### 📝 Enunciado

Crear un procedimiento almacenado que muestre la lista de repuestos cuyo **costo real** (descontando el descuento y sumando el impuesto) se encuentre **entre 150 y 250 Bs.**, incluyendo la descripción del repuesto y el nombre del proveedor.

---

### 🧠 Resolución

Se hace un `INNER JOIN` entre `REPUESTO`, `COMPRA` y `PROVEEDOR` para obtener la descripción del repuesto y el nombre del proveedor en una sola consulta.  
El costo real se calcula directamente en el `WHERE` como `(COSTO - DESCUENTO + IMPUESTO)` y se filtra con `BETWEEN`.  
No se necesitan variables ni parámetros porque los límites del rango son fijos.

```sql
DELIMITER $$
CREATE PROCEDURE EJ_SP1()
BEGIN
    SELECT R.DESCRIPCION   AS 'REPUESTO',
           P.NOMBREP       AS 'PROVEEDOR',
           (C.COSTO - C.DESCUENTO + C.IMPUESTO) AS 'COSTO REAL Bs.'
    FROM REPUESTO R
        INNER JOIN COMPRA    C ON R.CODIGO  = C.CODIGO
        INNER JOIN PROVEEDOR P ON C.NIT     = P.NIT
    WHERE (C.COSTO - C.DESCUENTO + C.IMPUESTO) BETWEEN 150 AND 250;
END $$
DELIMITER ;

CALL EJ_SP1;
```

> 💡 **Nota:** `BETWEEN 150 AND 250` es **inclusivo** en ambos extremos, es decir, incluye los valores exactamente iguales a 150 y a 250.

---

## 🧩 Ejercicio 02 — Cantidad total entregada por cada encargado

### 📝 Enunciado

Crear un procedimiento almacenado que muestre el **nombre de cada encargado** junto con la **cantidad total de repuestos entregados**, ordenado de mayor a menor cantidad entregada.

---

### 🧠 Resolución

Se hace un `INNER JOIN` entre `ENCARGADO` y `ENTREGA` usando el campo `ITEM`.  
Se agrupa por nombre del encargado con `GROUP BY` y se aplica `SUM(CANTIDADE)` para acumular el total entregado por cada uno.  
El resultado se ordena de mayor a menor con `ORDER BY ... DESC`.

```sql
DELIMITER $$
CREATE PROCEDURE EJ_SP2()
BEGIN
    SELECT E.NOMBRE            AS 'ENCARGADO',
           SUM(EN.CANTIDADE)   AS 'TOTAL ENTREGADO'
    FROM ENCARGADO E
        INNER JOIN ENTREGA EN ON E.ITEM = EN.ITEM
    GROUP BY E.NOMBRE
    ORDER BY SUM(EN.CANTIDADE) DESC;
END $$
DELIMITER ;

CALL EJ_SP2;
```

> 💡 **Nota:** `ORDER BY ... DESC` ordena de mayor a menor (Z→A, 9→0). Si se omite `DESC`, el orden por defecto es `ASC` (de menor a mayor).

---

## 🧩 Ejercicio 03 — Repuestos eléctricos con su costo promedio de compra

### 📝 Enunciado

Crear un procedimiento almacenado que muestre únicamente los **repuestos eléctricos**, indicando su descripción, potencia y el **costo promedio** al que fueron comprados. Incluir solamente los que tengan **al menos 1 compra registrada**.

---

### 🧠 Resolución

Se encadenan tres tablas: `REPUESTO`, `ELECTRICO` y `COMPRA` mediante `INNER JOIN`.  
El `JOIN` con `ELECTRICO` ya actúa como filtro natural, devolviendo solo los repuestos que tienen registro en esa tabla.  
Se agrupa por descripción y potencia, y se filtra con `HAVING COUNT(*) >= 1` para garantizar que exista al menos una compra.

```sql
DELIMITER $$
CREATE PROCEDURE EJ_SP3()
BEGIN
    SELECT R.DESCRIPCION   AS 'REPUESTO ELECTRICO',
           EL.POTENCIA     AS 'POTENCIA (W)',
           AVG(C.COSTO)    AS 'COSTO PROMEDIO Bs.'
    FROM REPUESTO  R
        INNER JOIN ELECTRICO EL ON R.CODIGO  = EL.CODIGO
        INNER JOIN COMPRA     C ON R.CODIGO  = C.CODIGO
    GROUP BY R.DESCRIPCION, EL.POTENCIA
    HAVING COUNT(*) >= 1;
END $$
DELIMITER ;

CALL EJ_SP3;
```

> 💡 **Nota:** `HAVING` filtra **grupos** (resultados del `GROUP BY`), mientras que `WHERE` filtra **filas individuales** antes de agrupar. Por eso `COUNT(*)` va en `HAVING` y no en `WHERE`.

---

## 🧩 Ejercicio 04 — Proveedores cuya descripción de repuesto termina en vocal

### 📝 Enunciado

Crear un procedimiento almacenado que muestre el **nombre del proveedor**, la **descripción del repuesto** y la **cantidad total comprada**, para todos los repuestos cuya descripción **termina en una vocal** (A, E, I, O, U). Ordenar alfabéticamente por nombre del proveedor.

---

### 🧠 Resolución

Se usa `INNER JOIN` entre `PROVEEDOR`, `COMPRA` y `REPUESTO`.  
Para detectar que la descripción termina en vocal se usan cinco condiciones `LIKE '%A'`, `'%E'`, etc., unidas con `OR`.  
Se agrupa por proveedor y descripción, se suma la cantidad y se ordena alfabéticamente.

```sql
DELIMITER $$
CREATE PROCEDURE EJ_SP4()
BEGIN
    SELECT P.NOMBREP        AS 'PROVEEDOR',
           R.DESCRIPCION    AS 'REPUESTO',
           SUM(C.CANTIDAD)  AS 'CANTIDAD TOTAL'
    FROM PROVEEDOR P
        INNER JOIN COMPRA   C ON P.NIT     = C.NIT
        INNER JOIN REPUESTO R ON C.CODIGO  = R.CODIGO
    WHERE R.DESCRIPCION LIKE '%A'
       OR R.DESCRIPCION LIKE '%E'
       OR R.DESCRIPCION LIKE '%I'
       OR R.DESCRIPCION LIKE '%O'
       OR R.DESCRIPCION LIKE '%U'
    GROUP BY P.NOMBREP, R.DESCRIPCION
    ORDER BY P.NOMBREP ASC;
END $$
DELIMITER ;

CALL EJ_SP4;
```

> 💡 **Nota:** `LIKE '%A'` busca cualquier texto que **termine** en A. El `%` representa cualquier secuencia de caracteres (incluso vacía). `LIKE 'A%'` buscaría los que **empiezan** con A.

---

## 🧩 Ejercicio 05 — Repuestos con cantidad comprada superior al promedio general  _(con variable local)_

### 📝 Enunciado

Crear un procedimiento almacenado que muestre los **repuestos** cuya cantidad total comprada sea **superior al promedio general** de todas las compras registradas, mostrando también la cantidad total y el nombre del proveedor.

---

### 🧠 Resolución

Se usa una **variable local** `CPRO` para almacenar el promedio general de cantidades de toda la tabla `COMPRA`.  
Esto evita repetir la subconsulta en el `HAVING` y acelera la ejecución.  
Luego se consultan los repuestos agrupando por descripción y proveedor, filtrando con `HAVING SUM(C.CANTIDAD) > CPRO`.

```sql
DELIMITER $$
CREATE PROCEDURE EJ_SP5()
BEGIN
    DECLARE CPRO FLOAT;

    -- Se calcula el promedio general y se guarda en la variable local
    SELECT AVG(CANTIDAD) INTO CPRO FROM COMPRA;

    -- Consulta principal usando la variable como referencia
    SELECT R.DESCRIPCION    AS 'REPUESTO',
           P.NOMBREP        AS 'PROVEEDOR',
           SUM(C.CANTIDAD)  AS 'CANTIDAD TOTAL'
    FROM REPUESTO  R
        INNER JOIN COMPRA    C ON R.CODIGO = C.CODIGO
        INNER JOIN PROVEEDOR P ON C.NIT    = P.NIT
    GROUP BY R.DESCRIPCION, P.NOMBREP
    HAVING SUM(C.CANTIDAD) > CPRO;
END $$
DELIMITER ;

CALL EJ_SP5;
```

> 💡 **Nota:** El uso de una variable local (`DECLARE` + `SELECT INTO`) hace que el promedio se calcule **una sola vez** al inicio del procedimiento y se reutilice en el filtro. Sin la variable, MySQL ejecutaría la subconsulta por cada fila evaluada, lo que es más lento.

---

[⬅️ Volver al inicio](https://marcelamv2.github.io/SIS304-AUXILIATURA/) &nbsp;|&nbsp; [🗃️ Ver código SQL](./PROCEDIMIENTOS.sql)