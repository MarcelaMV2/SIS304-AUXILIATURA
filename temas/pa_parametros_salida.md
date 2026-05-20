# 🗄️ Procedimientos Almacenados — Con Parámetros de Entrada y Salida
> 📅 Base de Datos · _Stored Procedures con IN y OUT Parameters · MySQL Workbench_

---

## 📖 ¿Qué es un Parámetro de Salida (`OUT`)?

En los procedimientos anteriores usamos parámetros `IN` para **enviar** datos al procedimiento. Ahora agregamos los parámetros `OUT`, que sirven para **devolver** un resultado hacia afuera del procedimiento, como si el procedimiento "llenara" una variable que luego podemos consultar.

### 🔧 Estructura básica

```sql
DELIMITER $$
CREATE PROCEDURE nombre(IN param_entrada TIPO, OUT param_salida TIPO)
BEGIN
    -- Se usa SELECT ... INTO param_salida para cargar el resultado
    SELECT columna INTO param_salida FROM tabla WHERE condicion;
END $$
DELIMITER ;

-- Llamada: las variables de salida se escriben con @
CALL nombre(valor_entrada, @mi_variable);

-- Consulta del resultado devuelto
SELECT @mi_variable AS 'Etiqueta';
```

### 📌 Conceptos clave de este tema

| Elemento | Para qué sirve |
|---|---|
| `OUT param TIPO` | Declara un parámetro que el procedimiento **devolverá** al exterior |
| `@variable` | Variable de sesión de MySQL; vive fuera del procedimiento y recibe el `OUT` |
| `SELECT ... INTO var` | Captura el resultado de una consulta dentro de una variable (local o `OUT`) |
| `DECLARE var TIPO` | Crea una variable **local** que solo existe dentro del `BEGIN...END` |
| `SET var = (SELECT ...)` | Otra forma de asignar valor a una variable local |
| `LIMIT 1` | Garantiza que el `SELECT INTO` devuelva un solo registro (obligatorio para no generar error) |
| `YEAR(fecha)` | Extrae el año de un campo de tipo `DATE` o `DATETIME` |
| `MONTH(fecha)` | Extrae el mes de un campo de tipo `DATE` o `DATETIME` |
| `CURDATE()` | Devuelve la fecha actual del servidor |
| `AVG(col)` | Calcula el promedio de una columna numérica |
| `MAX(col)` | Devuelve el valor máximo de una columna |

---

## 🧩 Ejercicio 01 — Costo total de una compra por nombre de repuesto y proveedor

### 📝 Enunciado

Crear un procedimiento que reciba el **nombre del repuesto** y el **nombre del proveedor**, y devuelva en un parámetro de salida el **costo total real** de la compra (considerando descuento e impuesto).

---

### 🧠 Resolución

Se usan dos variables locales `COD` y `NITP` para guardar el código del repuesto y el NIT del proveedor.  
Se valida la existencia de ambos con `IF EXISTS` anidados.  
El costo real se calcula como `COSTO - DESCUENTO + IMPUESTO` y se carga directo al parámetro `OUT` con `SELECT INTO`.  
Se usa `LIMIT 1` para asegurar que solo se tome un registro.

```sql
DELIMITER $$
CREATE PROCEDURE PS1(IN NR VARCHAR(50), IN NP VARCHAR(50), OUT CTC FLOAT(6,2))
BEGIN
    DECLARE COD  CHAR(6);
    DECLARE NITP CHAR(10);

    IF EXISTS(SELECT * FROM PROVEEDOR WHERE NOMBREP = NP) THEN
        IF EXISTS(SELECT * FROM REPUESTO WHERE DESCRIPCION = NR) THEN
            SELECT CODIGO INTO COD  FROM REPUESTO  WHERE DESCRIPCION = NR;
            SELECT NIT    INTO NITP FROM PROVEEDOR WHERE NOMBREP     = NP;

            SELECT (COSTO - DESCUENTO + IMPUESTO) INTO CTC
            FROM COMPRA
            WHERE NIT = NITP AND CODIGO = COD
            LIMIT 1;
        ELSE
            SELECT 'REPUESTO NO REGISTRADO' AS MENSAJE;
        END IF;
    ELSE
        SELECT 'PROVEEDOR NO REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL PS1('AMORTIGUADOR', 'JUAN PABLO RUIZ', @CTC);
SELECT @CTC AS 'COSTO TOTAL';
```

---

## 🧩 Ejercicio 02 — Cantidad total entregada de un repuesto

### 📝 Enunciado

Crear un procedimiento que reciba el **nombre de un repuesto** y devuelva en un parámetro de salida la **cantidad total entregada** de ese repuesto sumando todas sus entregas.

---

### 🧠 Resolución

Se verifica que el repuesto exista en la tabla `REPUESTO`.  
Se hace un `JOIN` entre `ENTREGA` y `REPUESTO` para filtrar por nombre, y se acumula la suma de `CANTIDADE` directamente en el parámetro `OUT CTE`.

```sql
DELIMITER $$
CREATE PROCEDURE PS2(IN DR VARCHAR(50), OUT CTE INT(6))
BEGIN
    IF EXISTS(SELECT * FROM REPUESTO WHERE DESCRIPCION = DR) THEN
        SELECT SUM(E.CANTIDADE) INTO CTE
        FROM ENTREGA E INNER JOIN REPUESTO R ON E.CODIGO = R.CODIGO
        WHERE R.DESCRIPCION = DR;
    ELSE
        SELECT 'REPUESTO NO REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL PS2('BUJIA', @CTE);
SELECT @CTE AS 'CANTIDAD TOTAL ENTREGADA';
```

---

## 🧩 Ejercicio 03 — Repuesto más caro comprado hasta la fecha

### 📝 Enunciado

Crear un procedimiento que devuelva en parámetros de salida la **descripción** y el **costo** del repuesto más caro comprado hasta la fecha (el primero que encuentre en caso de empate).

---

### 🧠 Resolución

Este procedimiento no necesita parámetros `IN` ni validaciones, ya que trabaja sobre toda la tabla.  
Se hace un `JOIN` entre `REPUESTO` y `COMPRA`, se ordena por costo de mayor a menor con `ORDER BY ... DESC` y se toma solo el primero con `LIMIT 1`.  
El `SELECT INTO` carga los dos valores simultáneamente en los dos parámetros `OUT`.

```sql
DELIMITER $$
CREATE PROCEDURE PS3(OUT DR VARCHAR(50), OUT CT FLOAT(6,2))
BEGIN
    SELECT R.DESCRIPCION, C.COSTO INTO DR, CT
    FROM REPUESTO R INNER JOIN COMPRA C ON R.CODIGO = C.CODIGO
    ORDER BY C.COSTO DESC
    LIMIT 1;
END $$
DELIMITER ;

CALL PS3(@DR, @CT);
SELECT @DR AS 'REPUESTO', @CT AS 'COSTO';
```

> 💡 **Nota:** `SELECT col1, col2 INTO var1, var2` permite capturar múltiples columnas en múltiples variables en una sola instrucción.

---

## 🧩 Ejercicio 04 — Cantidad total de repuestos comprados en un rango de fechas

### 📝 Enunciado

Crear un procedimiento que reciba **dos fechas** como parámetros de entrada y devuelva en un parámetro de salida la **cantidad total de repuestos** comprados dentro de ese rango.

---

### 🧠 Resolución

Se aplica la lógica de **intercambio de fechas** con una variable auxiliar `AUX` para garantizar que el rango siempre sea válido, sin importar el orden en que se pasen las fechas.  
Luego se suma `CANTIDAD` de la tabla `COMPRA` filtrando con `BETWEEN` y el resultado se deposita en el parámetro `OUT CTRC`.

```sql
DELIMITER $$
CREATE PROCEDURE PS4(IN F1 DATE, IN F2 DATE, OUT CTRC INT)
BEGIN
    DECLARE AUX DATE;

    IF (F1 > F2) THEN
        SET AUX = F1;
        SET F1  = F2;
        SET F2  = AUX;
    END IF;

    SELECT SUM(CANTIDAD) INTO CTRC
    FROM COMPRA
    WHERE DATE(FECHA) BETWEEN F1 AND F2;
END $$
DELIMITER ;

CALL PS4('2019-02-15', '2025-10-07', @CTRC);
SELECT @CTRC AS 'CANTIDAD TOTAL DE REPUESTOS COMPRADOS';
```

---

## 🧩 Ejercicio 05 — Total de repuestos comprados y gasto total de un proveedor en un año

### 📝 Enunciado

Crear un procedimiento que reciba un **año** y el **nombre del proveedor**, y devuelva en parámetros de salida el **total de repuestos comprados** y el **gasto total** (con descuento e impuesto) de ese proveedor en ese año.

---

### 🧠 Resolución

Se valida que el proveedor exista y se obtiene su `NIT` con `SET variable = (SELECT ...)`.  
Luego un solo `SELECT` con dos funciones de agregado (`SUM`) carga ambos resultados simultáneamente en los dos parámetros `OUT` usando `INTO TRC, GTC`.  
El filtro combina `NIT` con `YEAR(FECHA)` para acotar al año indicado.

```sql
DELIMITER $$
CREATE PROCEDURE PS5(IN ANIO INT(4), IN NP VARCHAR(50), OUT TRC INT, OUT GTC FLOAT(6,2))
BEGIN
    DECLARE NITP CHAR(10);

    IF EXISTS(SELECT * FROM PROVEEDOR WHERE NOMBREP = NP) THEN
        SET NITP = (SELECT NIT FROM PROVEEDOR WHERE NOMBREP = NP);

        SELECT SUM(CANTIDAD),
               SUM(COSTO - DESCUENTO + IMPUESTO) INTO TRC, GTC
        FROM COMPRA
        WHERE NIT = NITP AND YEAR(FECHA) = ANIO;
    ELSE
        SELECT 'PROVEEDOR NO REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL PS5(2019, 'JUAN PABLO RUIZ', @TRC, @GTC);
SELECT @TRC AS 'CANTIDAD TOTAL', @GTC AS 'GASTO TOTAL';
```

---

## 🧩 Ejercicio 06 — Promedio y cantidad máxima entregada por un encargado

### 📝 Enunciado

Crear un procedimiento que reciba el **nombre de un encargado** y devuelva en parámetros de salida el **promedio** y la **cantidad máxima** de repuestos entregados por ese encargado.

---

### 🧠 Resolución

Se valida que el encargado exista y se obtiene su `ITEM` con `SET`.  
Se usan las funciones `AVG()` para el promedio y `MAX()` para el máximo, cargando ambos resultados a sus respectivos parámetros `OUT` en una sola instrucción `SELECT INTO`.

```sql
DELIMITER $$
CREATE PROCEDURE PS6(IN NOE VARCHAR(50), OUT PCE FLOAT(6,2), OUT MRE INT)
BEGIN
    DECLARE IE INT(6);

    IF EXISTS(SELECT * FROM ENCARGADO WHERE NOMBRE = NOE) THEN
        SET IE = (SELECT ITEM FROM ENCARGADO WHERE NOMBRE = NOE);

        SELECT AVG(CANTIDADE), MAX(CANTIDADE) INTO PCE, MRE
        FROM ENTREGA
        WHERE ITEM = IE;
    ELSE
        SELECT 'ENCARGADO NO REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL PS6('VICTOR CASTEDO', @PCE, @MRE);
SELECT @PCE AS 'PROMEDIO', @MRE AS 'CANTIDAD MAXIMA';
```

> 💡 **Nota:** `AVG()` devuelve un valor decimal, por eso el parámetro de salida es `FLOAT`. `MAX()` sobre una columna entera devuelve un entero.

---

## 🧩 Ejercicio 07 — Repuesto más entregado entre dos meses del año en curso

### 📝 Enunciado

Crear un procedimiento que reciba **dos meses** (números del 1 al 12) y devuelva en parámetros de salida el **nombre del repuesto más entregado** y su **cantidad total**, considerando solo el año actual.

---

### 🧠 Resolución

Se intercambian los meses con una variable auxiliar si `M1 > M2`.  
Se filtran las entregas usando `MONTH(FECHAE) BETWEEN M1 AND M2` combinado con `YEAR(FECHAE) = YEAR(CURDATE())` para restringir al año en curso.  
Se agrupa por descripción, se ordena descendentemente y se toma el primero con `LIMIT 1`.

```sql
DELIMITER $$
CREATE PROCEDURE PS7(IN M1 INT, IN M2 INT, OUT DR VARCHAR(50), OUT RME INT)
BEGIN
    DECLARE AUX INT;

    IF (M1 > M2) THEN
        SET AUX = M1;
        SET M1  = M2;
        SET M2  = AUX;
    END IF;

    SELECT R.DESCRIPCION, SUM(E.CANTIDADE) INTO DR, RME
    FROM REPUESTO R INNER JOIN ENTREGA E ON R.CODIGO = E.CODIGO
    WHERE MONTH(E.FECHAE) BETWEEN M1 AND M2
      AND YEAR(E.FECHAE)  = YEAR(CURDATE())
    GROUP BY R.DESCRIPCION
    ORDER BY SUM(E.CANTIDADE) DESC
    LIMIT 1;
END $$
DELIMITER ;

CALL PS7(2, 10, @DR, @RME);
SELECT @DR AS 'REPUESTO MAS ENTREGADO', @RME AS 'CANTIDAD TOTAL ENTREGADA';
```

> 💡 **Nota:** `CURDATE()` retorna la fecha actual del servidor. `YEAR(CURDATE())` extrae solo el año, permitiendo filtrar dinámicamente sin hardcodear el año en el código.

---

## 🧩 Ejercicio 08 — Porcentaje de participación de un repuesto en las compras de un proveedor

### 📝 Enunciado

Crear un procedimiento que reciba el **nombre de un repuesto** y el **nombre de un proveedor**, y devuelva en un parámetro de salida el **porcentaje** que representa ese repuesto dentro del total de compras realizadas a ese proveedor.

---

### 🧠 Resolución

Se obtienen el código del repuesto y el NIT del proveedor en variables locales.  
Se calculan por separado: `CP` (cantidad total comprada a ese proveedor) y `CR` (cantidad comprada de ese repuesto específico a ese proveedor).  
El porcentaje se calcula con la fórmula `(CR * 100) / CP` y se asigna al parámetro `OUT` con `SET`.

```sql
DELIMITER $$
CREATE PROCEDURE PS8(IN DR VARCHAR(50), IN NP VARCHAR(50), OUT PPR FLOAT(6,2))
BEGIN
    DECLARE COD  CHAR(6);
    DECLARE NITP CHAR(10);
    DECLARE CP   INT;
    DECLARE CR   INT;

    IF EXISTS(SELECT * FROM REPUESTO WHERE DESCRIPCION = DR) THEN
        IF EXISTS(SELECT * FROM PROVEEDOR WHERE NOMBREP = NP) THEN
            SELECT CODIGO INTO COD  FROM REPUESTO  WHERE DESCRIPCION = DR;
            SELECT NIT    INTO NITP FROM PROVEEDOR WHERE NOMBREP     = NP;

            SELECT SUM(CANTIDAD) INTO CP FROM COMPRA WHERE NIT = NITP;
            SELECT SUM(CANTIDAD) INTO CR FROM COMPRA WHERE NIT = NITP AND CODIGO = COD;

            SET PPR = (CR * 100) / CP;
        ELSE
            SELECT 'PROVEEDOR NO REGISTRADO' AS MENSAJE;
        END IF;
    ELSE
        SELECT 'REPUESTO NO REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL PS8('AMORTIGUADOR', 'CARLA', @PPR);
SELECT @PPR AS 'PORCENTAJE REPUESTO DEL PROVEEDOR';
```

> 💡 **Nota:** A diferencia de los ejercicios anteriores, aquí `SET PPR = (expresión)` se usa al final porque el valor no viene directamente de un `SELECT`, sino de un cálculo entre dos variables locales ya cargadas.

---

[⬅️ Volver al inicio](./README.md) &nbsp;|&nbsp; [🗃️ Ver código SQL](./PARAMETROSSALIDA.sql)