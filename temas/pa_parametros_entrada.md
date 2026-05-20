# 🗄️ Procedimientos Almacenados — Con Parámetros de Entrada
> 📅 Base de Datos · _Stored Procedures con IN Parameters · MySQL Workbench_

---

## 📖 ¿Qué es un Procedimiento Almacenado con Parámetros de Entrada?

Un **procedimiento almacenado** es un bloque de código SQL guardado en el servidor de base de datos que puede ejecutarse cuando se le llama por su nombre. A diferencia de una consulta común, vive dentro de la base de datos y puede reutilizarse sin reescribirse.

Cuando un procedimiento tiene **parámetros de entrada (`IN`)**, significa que recibe valores desde el exterior al momento de ser llamado. Esos valores se usan dentro del cuerpo del procedimiento como si fueran variables.

### 🔧 Estructura básica

```sql
DELIMITER $$
CREATE PROCEDURE nombre_procedimiento(IN param1 TIPO, IN param2 TIPO)
BEGIN
    -- Cuerpo del procedimiento
    -- Se pueden usar variables locales: DECLARE variable TIPO;
    -- Consultas, actualizaciones, condicionales, etc.
END $$
DELIMITER ;

-- Llamada al procedimiento
CALL nombre_procedimiento(valor1, valor2);
```

### 📌 Puntos clave

- `DELIMITER $$` cambia el delimitador temporalmente para que el `;` interno no cierre el procedimiento antes de tiempo.
- `IN` indica que el parámetro **solo entra**, no devuelve valor al exterior.
- `DECLARE` permite crear **variables locales** dentro del `BEGIN...END`.
- `INTO` captura el resultado de un `SELECT` dentro de una variable.
- `IF EXISTS(...)` valida la existencia de un registro antes de operar.

---

## 🧩 Ejercicio 01 — Conteo de repuestos por tipo y fecha

### 📝 Enunciado

Crear un procedimiento almacenado que reciba como parámetro una **fecha específica** y cuente la cantidad total de repuestos **eléctricos** y **mecánicos** que se compraron ese día.

---

### 🧠 Resolución

Se declaran dos variables locales `CTM` y `CTE` para almacenar los totales.  
Mediante `SELECT ... INTO`, se suma la cantidad de compras cruzando la tabla `MECANICO` o `ELECTRICO` con `COMPRA`, filtrando por la fecha recibida.  
Al final se devuelve un `SELECT` con ambos valores etiquetados.

```sql
DELIMITER $$
CREATE PROCEDURE EJ1(IN FECHA1 DATE)
BEGIN
    DECLARE CTM FLOAT(6,2);
    DECLARE CTE FLOAT(6,2);

    SELECT SUM(C.CANTIDAD) INTO CTM
    FROM MECANICO M INNER JOIN COMPRA C ON M.CODIGO = C.CODIGO
    WHERE DATE(C.FECHA) = FECHA1;

    SELECT SUM(C.CANTIDAD) INTO CTE
    FROM ELECTRICO E INNER JOIN COMPRA C ON E.CODIGO = C.CODIGO
    WHERE DATE(C.FECHA) = FECHA1;

    SELECT CTM AS 'CANTIDAD DE REPUESTOS MECANICOS',
           CTE AS 'CANTIDAD DE REPUESTOS ELECTRICOS';
END $$
DELIMITER ;

CALL EJ1('2019-05-05');
```

---

## 🧩 Ejercicio 02 — Entregas realizadas por un encargado

### 📝 Enunciado

Crear un procedimiento que reciba como parámetro el **nombre de un encargado** y muestre todas las entregas que realizó, incluyendo el repuesto, la cantidad y la fecha.

---

### 🧠 Resolución

Primero se verifica que el encargado exista en la tabla `ENCARGADO`.  
Si existe, se obtiene su `ITEM` (identificador) mediante `SELECT INTO`, y luego se consultan todas sus entregas cruzando `REPUESTO` con `ENTREGA`.  
Si no existe, se devuelve un mensaje de error.

```sql
DELIMITER $$
CREATE PROCEDURE EJ2(IN NOMEN VARCHAR(50))
BEGIN
    DECLARE IEN INT(6);

    IF EXISTS(SELECT * FROM ENCARGADO WHERE NOMBRE = NOMEN) THEN
        SET IEN = (SELECT ITEM FROM ENCARGADO WHERE NOMBRE = NOMEN);

        SELECT R.DESCRIPCION AS 'REPUESTO',
               E.CANTIDADE   AS 'CANTIDAD',
               E.FECHAE      AS 'FECHA'
        FROM REPUESTO R INNER JOIN ENTREGA E ON R.CODIGO = E.CODIGO
        WHERE E.ITEM = IEN;
    ELSE
        SELECT 'EL ENCARGADO NO ESTA REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL EJ2('VICTOR CASTEDO');
```

---

## 🧩 Ejercicio 03 — Actualizar costo de una compra

### 📝 Enunciado

Crear un procedimiento que reciba el **código de un repuesto**, el **NIT del proveedor** y un **nuevo costo**, y actualice el costo de esa compra específica en la tabla `COMPRA`.

---

### 🧠 Resolución

Se valida primero que el proveedor exista, y luego que el repuesto también exista.  
Solo si ambas condiciones se cumplen, se ejecuta el `UPDATE` sobre `COMPRA` y se muestra el registro actualizado.  
Las validaciones están anidadas con `IF...ELSE` para dar mensajes precisos según qué dato falta.

```sql
DELIMITER $$
CREATE PROCEDURE EJ3(IN CR CHAR(6), IN NP CHAR(10), IN NC FLOAT(6,2))
BEGIN
    IF EXISTS(SELECT * FROM PROVEEDOR WHERE NIT = NP) THEN
        IF EXISTS(SELECT * FROM REPUESTO WHERE CODIGO = CR) THEN
            UPDATE COMPRA SET COSTO = NC WHERE CODIGO = CR AND NIT = NP;
            SELECT * FROM COMPRA WHERE CODIGO = CR AND NIT = NP;
        ELSE
            SELECT 'REPUESTO NO REGISTRADO' AS MENSAJE;
        END IF;
    ELSE
        SELECT 'PROVEEDOR NO REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL EJ3('R-0001', '1011112450', 250);
```

---

## 🧩 Ejercicio 04 — Compras en un rango de fechas con costo real

### 📝 Enunciado

Crear un procedimiento que reciba **dos fechas** como parámetros y muestre todas las compras realizadas dentro de ese rango, calculando el **costo total real** considerando: costo unitario, cantidad, descuento e impuesto.

---

### 🧠 Resolución

Se incluye una lógica para **intercambiar las fechas** si `F1 > F2`, garantizando que el rango siempre sea válido independientemente del orden en que se pasen.  
El costo real se calcula directamente en el `SELECT` como `COSTO - DESCUENTO + IMPUESTO`.

```sql
DELIMITER $$
CREATE PROCEDURE EJ4(IN F1 DATE, IN F2 DATE)
BEGIN
    DECLARE AUX DATE;

    IF (F1 > F2) THEN
        SET AUX = F1;
        SET F1  = F2;
        SET F2  = AUX;
    END IF;

    SELECT CODIGO, NIT, FECHA, CANTIDAD,
           (COSTO - DESCUENTO + IMPUESTO) AS 'COSTO REAL',
           DESCUENTO, IMPUESTO
    FROM COMPRA
    WHERE DATE(FECHA) BETWEEN F1 AND F2;
END $$
DELIMITER ;

CALL EJ4('2025-09-30', '2019-05-04');
```

---

## 🧩 Ejercicio 05 — Proveedores con más compras registradas

### 📝 Enunciado

Crear un procedimiento que reciba un **número mínimo** y muestre únicamente los proveedores cuya cantidad de compras registradas supere ese valor, identificando a los de mayor participación.

---

### 🧠 Resolución

Se agrupa por nombre de proveedor con `GROUP BY` y se filtra con `HAVING` para que solo aparezcan los que tienen un conteo igual o mayor al mínimo recibido como parámetro.

```sql
DELIMITER $$
CREATE PROCEDURE EJ5(IN CM INT)
BEGIN
    SELECT P.NOMBREP       AS 'PROVEEDOR',
           COUNT(*)        AS 'COMPRAS REGISTRADAS'
    FROM PROVEEDOR P INNER JOIN COMPRA C ON P.NIT = C.NIT
    GROUP BY P.NOMBREP
    HAVING COUNT(*) >= CM;
END $$
DELIMITER ;

CALL EJ5(4);
```

---

## 🧩 Ejercicio 06 — Insertar compra usando nombres en lugar de códigos

### 📝 Enunciado

Crear un procedimiento que inserte una compra cuando solo se conoce el **nombre del repuesto**, el **nombre del proveedor**, la **cantidad** y el **precio unitario**. Debe usar variables locales para obtener los códigos internos.

---

### 🧠 Resolución

Se valida la existencia tanto del proveedor como del repuesto.  
Luego se recuperan su `CODIGO` y `NIT` respectivamente con `SELECT INTO`.  
El costo total se calcula multiplicando cantidad por precio unitario directamente en el `INSERT`.

```sql
DELIMITER $$
CREATE PROCEDURE EJ6(IN DR VARCHAR(50), IN NP VARCHAR(50), IN CN INT, IN PR FLOAT(6,2))
BEGIN
    DECLARE CR  CHAR(6);
    DECLARE NIP CHAR(10);

    IF EXISTS(SELECT * FROM PROVEEDOR WHERE NOMBREP = NP) THEN
        IF EXISTS(SELECT * FROM REPUESTO WHERE DESCRIPCION = DR) THEN
            SELECT CODIGO INTO CR  FROM REPUESTO  WHERE DESCRIPCION = DR;
            SELECT NIT    INTO NIP FROM PROVEEDOR WHERE NOMBREP     = NP;

            INSERT INTO COMPRA(CODIGO, NIT, FECHA, CANTIDAD, COSTO)
            VALUES (CR, NIP, NOW(), CN, CN * PR);

            SELECT * FROM COMPRA WHERE CODIGO = CR AND NIT = NIP;
        ELSE
            SELECT 'REPUESTO NO REGISTRADO' AS MENSAJE;
        END IF;
    ELSE
        SELECT 'PROVEEDOR NO REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL EJ6('AMORTIGUADOR2', 'JUAN PABLO RUIZ', 5, 35.50);
```

---

## 🧩 Ejercicio 07 — Total gastado por proveedor en un rango de fechas

### 📝 Enunciado

Crear un procedimiento que reciba el **nombre de un proveedor** y **dos fechas**, y calcule el **total gastado** en compras dentro de ese rango. Usar variables locales para almacenar el NIT.

---

### 🧠 Resolución

Se aplica nuevamente la lógica de **intercambio de fechas** si vienen invertidas.  
Se valida que el proveedor exista, se obtiene su `NIT` con `SELECT INTO` y se suma el costo de todas sus compras en el rango indicado.

```sql
DELIMITER $$
CREATE PROCEDURE EJ7(IN NP VARCHAR(50), IN F1 DATE, IN F2 DATE)
BEGIN
    DECLARE AUX DATE;
    DECLARE NIP CHAR(10);

    IF (F1 > F2) THEN
        SET AUX = F1;
        SET F1  = F2;
        SET F2  = AUX;
    END IF;

    IF EXISTS(SELECT * FROM PROVEEDOR WHERE NOMBREP = NP) THEN
        SELECT NIT INTO NIP FROM PROVEEDOR WHERE NOMBREP = NP;

        SELECT SUM(COSTO) AS 'COSTO TOTAL'
        FROM COMPRA
        WHERE NIT = NIP AND DATE(FECHA) BETWEEN F1 AND F2;
    ELSE
        SELECT 'PROVEEDOR NO REGISTRADO' AS MENSAJE;
    END IF;
END $$
DELIMITER ;

CALL EJ7('JUAN PABLO RUIZ', '2019-05-05', '2025-09-30');
```

---

## 🧩 Ejercicio 08 — Repuestos más comprados en un rango de fechas

### 📝 Enunciado

Crear un procedimiento que muestre los **repuestos más comprados** dentro de un rango de fechas, mostrando únicamente aquellos que superen una **cantidad mínima** total acumulada.

---

### 🧠 Resolución

Se intercambian las fechas si están invertidas, luego se cruza `REPUESTO` con `COMPRA`, se agrupa por descripción del repuesto y se filtra con `HAVING` para mostrar solo los que superan la cantidad mínima recibida.

```sql
DELIMITER $$
CREATE PROCEDURE EJ8(IN F1 DATE, IN F2 DATE, IN CMIN INT)
BEGIN
    DECLARE AUX DATE;

    IF (F1 > F2) THEN
        SET AUX = F1;
        SET F1  = F2;
        SET F2  = AUX;
    END IF;

    SELECT R.DESCRIPCION    AS 'REPUESTO',
           SUM(C.CANTIDAD)  AS 'CANTIDAD TOTAL'
    FROM REPUESTO R INNER JOIN COMPRA C ON R.CODIGO = C.CODIGO
    WHERE DATE(C.FECHA) BETWEEN F1 AND F2
    GROUP BY R.DESCRIPCION
    HAVING SUM(C.CANTIDAD) >= CMIN;
END $$
DELIMITER ;

CALL EJ8('2019-05-05', '2025-09-30', 16);
```

---

[⬅️ Volver al inicio](https://marcelamv2.github.io/SIS304-AUXILIATURA/) &nbsp;|&nbsp; [🗃️ Ver código SQL](./PARAMETROSENTRADA.sql)