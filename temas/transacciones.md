# 🗄️ Transacciones — Procedimientos Almacenados con Transacciones en MySQL
> 📅 Base de Datos · _Stored Procedures & Transactions · MySQL Workbench_

---

## 📖 ¿Qué es una Transacción en MySQL?

Una **transacción** es un conjunto de operaciones SQL que se ejecutan como una unidad atómica: o todas se completan con éxito (`COMMIT`), o ninguna tiene efecto (`ROLLBACK`). Se implementan dentro de procedimientos almacenados (`CREATE PROCEDURE`) usando `START TRANSACTION`.

### 🔧 Estructura básica

```sql
DELIMITER $$
CREATE PROCEDURE NOMBRE_PROC(IN param1 TIPO, IN param2 TIPO)
BEGIN
    DECLARE variable TIPO;
    SET AUTOCOMMIT = 0;
    START TRANSACTION;

    -- validaciones con IF EXISTS / IF NOT EXISTS
    -- operaciones INSERT / UPDATE / DELETE
    -- si algo falla:
    --   ROLLBACK;
    --   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR';

    COMMIT;
END $$
DELIMITER ;

-- Llamada:
CALL NOMBRE_PROC(valor1, valor2);
```

### 📌 Conceptos clave de este tema

| Elemento | Para qué sirve |
|---|---|
| `SET AUTOCOMMIT = 0` | Desactiva la confirmación automática para controlar manualmente la transacción |
| `START TRANSACTION` | Marca el inicio del bloque transaccional |
| `COMMIT` | Confirma y persiste todos los cambios realizados en la transacción |
| `ROLLBACK` | Deshace todos los cambios si ocurre un error |
| `SIGNAL SQLSTATE '45000'` | Lanza un error personalizado con mensaje descriptivo |
| `IF EXISTS(SELECT ...)` | Verifica que un registro ya existe antes de operar |
| `IF NOT EXISTS(SELECT ...)` | Verifica que un registro NO existe (para evitar duplicados) |
| `SELECT col INTO var` | Recupera un valor de la base de datos y lo guarda en una variable local |
| `INSERT INTO` | Inserta una nueva fila en una tabla |
| `UPDATE ... SET` | Modifica campos de filas existentes |
| `DELETE FROM` | Elimina físicamente una fila de una tabla |
| `MYSQL_ERRNO` | Código de error de MySQL; si es distinto de 0, ocurrió un fallo |

### 📌 Diagrama del modelo de DEPÓSITO aplicado a este sistema

```
            INGRESO                         EGRESO
               ↓                               ↓
           [ COMPRA ]  →→→  DEPOSITO  →→→  [ ENTREGA ]
                        CINGRESO (+)      CANTIDADE (+)
                        CSALDO   (+)      CSALDO    (-)
```

> En esta base de datos no hay una tabla de depósito explícita, pero el saldo disponible se controla comparando `SUM(CANTIDAD)` en COMPRA contra `SUM(CANTIDADE)` en ENTREGA por repuesto.

---

## 🧩 Transacción 01 — Registrar una compra y simultáneamente registrar la primera entrega

### 📝 Enunciado

Transacción que registre la compra de un repuesto a un proveedor y, al mismo tiempo, consigne la primera entrega correspondiente a esa compra. Los datos son: el código del repuesto, el NIT del proveedor, la cantidad comprada, el costo, y el ITEM del encargado de la entrega.

---

### 🧠 Análisis

```
                                    ┌──────────────────────────────┐
CODI, NIT, CC, COSTO, ITEM ──────▶ │       TRANSACCION1           │
                                    └──────────────────────────────┘

  ANALSIS:
  REGISTRE COMPRA
    INSERT CC (CANT. COMPRA)
  REGISTRE ENTREGA
    INSERT CC (CANT. ENTREGA = CANT. COMPRA)
```

### 🧠 Resolución

Se verifica que el repuesto exista en `REPUESTO`, que el proveedor exista en `PROVEEDOR`, y que la combinación `(CODIGO, NIT)` no tenga ya un registro en `COMPRA` (clave primaria compuesta). Si todo es válido, se inserta en `COMPRA` y luego se genera automáticamente el primer registro en `ENTREGA` usando el número de entrega máximo + 1.

```sql
DELIMITER $$
CREATE PROCEDURE TRANSACCION1(IN CODI CHAR(6), IN NIP CHAR(10), IN CC INT, IN COSTO FLOAT, IN ITEN INT)
BEGIN
    DECLARE NE_NEW INT;
    SET AUTOCOMMIT = 0;
    START TRANSACTION;

    IF EXISTS(SELECT * FROM REPUESTO WHERE CODIGO = CODI) THEN
        IF EXISTS(SELECT * FROM PROVEEDOR WHERE NIT = NIP) THEN
            IF NOT EXISTS(SELECT * FROM COMPRA WHERE CODIGO = CODI AND NIT = NIP) THEN
                IF EXISTS(SELECT * FROM ENCARGADO WHERE ITEM = ITEN) THEN
                    BEGIN
                        INSERT INTO COMPRA VALUES (CODI, NIP, NOW(), CC, COSTO, 0.0, 0.0);
                        SET NE_NEW = (SELECT MAX(NE) + 1 FROM ENTREGA);
                        INSERT INTO ENTREGA VALUES (NE_NEW, NOW(), CC, CODI, NIP, ITEN);
                        IF (MYSQL_ERRNO <> 0) THEN
                            BEGIN
                                ROLLBACK;
                                SIGNAL SQLSTATE '45000'
                                SET MESSAGE_TEXT = 'TRANSACCIÓN NO COMPLETADA', MYSQL_ERRNO = '1006';
                            END;
                        END IF;
                    END;
                ELSE SELECT 'EL ENCARGADO NO ESTA REGISTRADO'; END IF;
            ELSE SELECT 'LA COMPRA YA FUE REGISTRADA PARA ESE PROVEEDOR'; END IF;
        ELSE SELECT 'EL PROVEEDOR NO ESTA REGISTRADO'; END IF;
    ELSE SELECT 'EL REPUESTO NO ESTA REGISTRADO'; END IF;

    COMMIT;
END $$
DELIMITER ;

CALL TRANSACCION1('R-0001', '1011112450', 10, 250.0, 10010);
```

---

## 🧩 Transacción 02 — Registrar una entrega para una compra existente

### 📝 Enunciado

Transacción que registre una entrega correspondiente a una compra ya existente en la base de datos. Los datos son: el número de entrega, el código del repuesto, el NIT del proveedor, la cantidad a entregar y el ITEM del encargado.

---

### 🧠 Análisis

```
                                         ┌──────────────────────────────┐
NE, CODI, NIP, CANTIDADE, ITEN ────────▶ │       TRANSACCION2           │
                                         └──────────────────────────────┘

  ANALSIS:
  VERIFICAR QUE COMPRA EXISTE
  VERIFICAR QUE ENTREGA NO EXISTE
  REGISTRE ENTREGA
    INSERT CANTIDADE
```

### 🧠 Resolución

Se verifica que la compra `(CODIGO, NIT)` exista en `COMPRA`, que el encargado esté registrado, y que el número de entrega no esté ya registrado. Si las validaciones pasan, se inserta la entrega.

```sql
DELIMITER $$
CREATE PROCEDURE TRANSACCION2(IN NE_NEW INT, IN CODI CHAR(6), IN NIP CHAR(10), IN CANTIDADE INT, IN ITEN INT)
BEGIN
    SET AUTOCOMMIT = 0;
    START TRANSACTION;

    IF EXISTS(SELECT * FROM COMPRA WHERE CODIGO = CODI AND NIT = NIP) THEN
        IF EXISTS(SELECT * FROM ENCARGADO WHERE ITEM = ITEN) THEN
            IF NOT EXISTS(SELECT * FROM ENTREGA WHERE NE = NE_NEW) THEN
                BEGIN
                    INSERT INTO ENTREGA VALUES (NE_NEW, NOW(), CANTIDADE, CODI, NIP, ITEN);
                    IF (MYSQL_ERRNO <> 0) THEN
                        BEGIN
                            ROLLBACK;
                            SIGNAL SQLSTATE '45000'
                            SET MESSAGE_TEXT = 'TRANSACCIÓN NO COMPLETADA', MYSQL_ERRNO = '1006';
                        END;
                    END IF;
                END;
            ELSE SELECT 'EL NUMERO DE ENTREGA YA EXISTE'; END IF;
        ELSE SELECT 'EL ENCARGADO NO ESTA REGISTRADO'; END IF;
    ELSE SELECT 'LA COMPRA NO EXISTE PARA ESE REPUESTO Y PROVEEDOR'; END IF;

    COMMIT;
END $$
DELIMITER ;

CALL TRANSACCION2(105, 'R-0001', '1011112450', 5, 10010);
```

---

## 🧩 Transacción 03 — Eliminar físicamente una entrega y actualizar la compra correspondiente

### 📝 Enunciado

Transacción que elimine físicamente el registro de una entrega. Se tiene como dato el número de entrega (`NE`).

---

### 🧠 Análisis

```
                          ┌──────────────────────────────┐
         NE_DEL ─────────▶ │       TRANSACCION3           │
                          └──────────────────────────────┘

  ANALSIS:
  VERIFICAR QUE ENTREGA EXISTE
  ELIMINACION FISICA ENTREGA
    DELETE
```

### 🧠 Resolución

Se verifica que el número de entrega exista antes de intentar eliminar. Si existe, se procede con el `DELETE`.

```sql
DELIMITER $$
CREATE PROCEDURE TRANSACCION3(IN NE_DEL INT)
BEGIN
    SET AUTOCOMMIT = 0;
    START TRANSACTION;

    IF EXISTS(SELECT * FROM ENTREGA WHERE NE = NE_DEL) THEN
        BEGIN
            DELETE FROM ENTREGA WHERE NE = NE_DEL;
            IF (MYSQL_ERRNO <> 0) THEN
                BEGIN
                    ROLLBACK;
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'TRANSACCIÓN NO COMPLETADA', MYSQL_ERRNO = '1006';
                END;
            END IF;
        END;
    ELSE SELECT 'LA ENTREGA NO EXISTE'; END IF;

    COMMIT;
END $$
DELIMITER ;

CALL TRANSACCION3(101);
```

---

## 🧩 Transacción 04 — Registrar compra o actualizar cantidad si ya existe

### 📝 Enunciado

Transacción que registre la compra de un repuesto a un proveedor. Si ya existe una compra de ese repuesto al mismo proveedor, se actualice la cantidad acumulada. Caso contrario, se registre como nueva compra. Los datos son: el código del repuesto, el NIT del proveedor, la cantidad y el costo unitario.

---

### 🧠 Análisis

```
                                    ┌──────────────────────────────┐
   CODI, NIP, CC, COSTO ───────────▶ │       TRANSACCION4           │
                                    └──────────────────────────────┘

  ANALSIS:
  REGISTRE COMPRA
    SI EXISTE  → UPDATE CANTIDAD = CANTIDAD + CC
    NO EXISTE  → INSERT CC
```

### 🧠 Resolución

Se verifican las existencias del repuesto y del proveedor. Luego se evalúa si ya existe el registro en `COMPRA`. De existir, se incrementa la cantidad; si no, se inserta uno nuevo.

```sql
DELIMITER $$
CREATE PROCEDURE TRANSACCION4(IN CODI CHAR(6), IN NIP CHAR(10), IN CC INT, IN COSTO FLOAT)
BEGIN
    SET AUTOCOMMIT = 0;
    START TRANSACTION;

    IF EXISTS(SELECT * FROM REPUESTO WHERE CODIGO = CODI) THEN
        IF EXISTS(SELECT * FROM PROVEEDOR WHERE NIT = NIP) THEN
            BEGIN
                IF EXISTS(SELECT * FROM COMPRA WHERE CODIGO = CODI AND NIT = NIP) THEN
                    UPDATE COMPRA SET CANTIDAD = CANTIDAD + CC WHERE CODIGO = CODI AND NIT = NIP;
                ELSE
                    INSERT INTO COMPRA VALUES (CODI, NIP, NOW(), CC, COSTO, 0.0, 0.0);
                END IF;
                IF (MYSQL_ERRNO <> 0) THEN
                    BEGIN
                        ROLLBACK;
                        SIGNAL SQLSTATE '45000'
                        SET MESSAGE_TEXT = 'TRANSACCIÓN NO COMPLETADA', MYSQL_ERRNO = '1006';
                    END;
                END IF;
            END;
        ELSE SELECT 'EL PROVEEDOR NO ESTA REGISTRADO'; END IF;
    ELSE SELECT 'EL REPUESTO NO ESTA REGISTRADO'; END IF;

    COMMIT;
END $$
DELIMITER ;

CALL TRANSACCION4('R-0001', '1011112450', 5, 200.0);
```

---

## 🧩 Transacción 05 — Registrar entrega solo si hay stock suficiente en compras

### 📝 Enunciado

Transacción que registre una nueva entrega de un repuesto, verificando que la cantidad total entregada hasta el momento no supere la cantidad total comprada. Si el saldo es suficiente, se registra la entrega; caso contrario, se registra solo con la cantidad disponible. Los datos son: el código del repuesto, el NIT del proveedor, la cantidad a entregar y el ITEM del encargado.

---

### 🧠 Análisis

```
                                         ┌──────────────────────────────┐
CODI, NIP, CANTIDADE, ITEN ────────────▶ │       TRANSACCION5           │
                                         └──────────────────────────────┘

  ANALSIS:
  CALCULE SALDO = TOTAL COMPRADO - TOTAL ENTREGADO
  SI SALDO >= CANTIDADE
    REGISTRE ENTREGA CON CANTIDADE
  SI SALDO < CANTIDADE Y SALDO > 0
    REGISTRE ENTREGA CON SALDO DISPONIBLE
  SI SALDO = 0
    MENSAJE: SIN STOCK DISPONIBLE
```

### 🧠 Resolución

Se calcula el saldo disponible restando el total ya entregado del total comprado. Según el resultado, se inserta la entrega con la cantidad solicitada o con el saldo real disponible.

```sql
DELIMITER $$
CREATE PROCEDURE TRANSACCION5(IN CODI CHAR(6), IN NIP CHAR(10), IN CANTIDADE INT, IN ITEN INT)
BEGIN
    DECLARE TOTAL_COMP INT;
    DECLARE TOTAL_ENT  INT;
    DECLARE SALDO      INT;
    DECLARE NE_NEW     INT;

    SET AUTOCOMMIT = 0;
    START TRANSACTION;

    IF EXISTS(SELECT * FROM COMPRA WHERE CODIGO = CODI AND NIT = NIP) THEN
        IF EXISTS(SELECT * FROM ENCARGADO WHERE ITEM = ITEN) THEN
            BEGIN
                SELECT CANTIDAD INTO TOTAL_COMP FROM COMPRA WHERE CODIGO = CODI AND NIT = NIP;
                SELECT IFNULL(SUM(CANTIDADE), 0) INTO TOTAL_ENT FROM ENTREGA WHERE CODIGO = CODI AND NIT = NIP;
                SET SALDO = TOTAL_COMP - TOTAL_ENT;
                SET NE_NEW = (SELECT MAX(NE) + 1 FROM ENTREGA);

                IF (SALDO > 0) THEN
                    IF (SALDO >= CANTIDADE) THEN
                        INSERT INTO ENTREGA VALUES (NE_NEW, NOW(), CANTIDADE, CODI, NIP, ITEN);
                    ELSE
                        INSERT INTO ENTREGA VALUES (NE_NEW, NOW(), SALDO, CODI, NIP, ITEN);
                    END IF;
                ELSE
                    SELECT 'SIN STOCK DISPONIBLE PARA ESTE REPUESTO';
                END IF;

                IF (MYSQL_ERRNO <> 0) THEN
                    BEGIN
                        ROLLBACK;
                        SIGNAL SQLSTATE '45000'
                        SET MESSAGE_TEXT = 'TRANSACCIÓN NO COMPLETADA', MYSQL_ERRNO = '1006';
                    END;
                END IF;
            END;
        ELSE SELECT 'EL ENCARGADO NO ESTA REGISTRADO'; END IF;
    ELSE SELECT 'NO EXISTE COMPRA PARA ESE REPUESTO Y PROVEEDOR'; END IF;

    COMMIT;
END $$
DELIMITER ;

CALL TRANSACCION5('R-0001', '1011112450', 3, 10010);
```

> 💡 **Nota:** `IFNULL(SUM(...), 0)` evita que el cálculo devuelva `NULL` cuando no hay entregas registradas aún para ese repuesto.

---

## 🧩 Transacción 06 — Eliminar compra y todas sus entregas asociadas

### 📝 Enunciado

Transacción que elimine físicamente el registro de una compra de un repuesto a un proveedor, eliminando también todas las entregas asociadas a esa compra. Los datos son: el código del repuesto y el NIT del proveedor.

---

### 🧠 Análisis

```
                               ┌──────────────────────────────┐
      CODI, NIP ──────────────▶ │       TRANSACCION6           │
                               └──────────────────────────────┘

  ANALSIS:
  VERIFICAR QUE COMPRA EXISTE
  ELIMINACION FISICA ENTREGAS ASOCIADAS
    DELETE FROM ENTREGA
  ELIMINACION FISICA COMPRA
    DELETE FROM COMPRA
```

### 🧠 Resolución

Primero se eliminan las entregas porque tienen clave foránea hacia `COMPRA`. Luego se elimina el registro de `COMPRA`. El orden es obligatorio para respetar la integridad referencial.

```sql
DELIMITER $$
CREATE PROCEDURE TRANSACCION6(IN CODI CHAR(6), IN NIP CHAR(10))
BEGIN
    SET AUTOCOMMIT = 0;
    START TRANSACTION;

    IF EXISTS(SELECT * FROM COMPRA WHERE CODIGO = CODI AND NIT = NIP) THEN
        BEGIN
            DELETE FROM ENTREGA WHERE CODIGO = CODI AND NIT = NIP;
            DELETE FROM COMPRA  WHERE CODIGO = CODI AND NIT = NIP;
            IF (MYSQL_ERRNO <> 0) THEN
                BEGIN
                    ROLLBACK;
                    SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'TRANSACCIÓN NO COMPLETADA', MYSQL_ERRNO = '1006';
                END;
            END IF;
        END;
    ELSE SELECT 'LA COMPRA NO EXISTE'; END IF;

    COMMIT;
END $$
DELIMITER ;

CALL TRANSACCION6('R-0001', '1011112450');
```

> 💡 **Nota:** Siempre se deben eliminar primero los registros hijos (ENTREGA) antes que los registros padre (COMPRA), ya que existe una `FOREIGN KEY` que lo impone.

---

## 🧩 Transacción 07 — Actualizar la disminución de cantidad en una entrega y reflejarla en compra

### 📝 Enunciado

Transacción que actualice la reducción de cantidad de una entrega existente. La cantidad de la compra correspondiente también deberá ajustarse para reflejar la devolución. Los datos son: el número de entrega y la cantidad a disminuir.

---

### 🧠 Análisis

```
                               ┌──────────────────────────────┐
       NE_UPD, CDISM ─────────▶ │       TRANSACCION7           │
                               └──────────────────────────────┘

  ANALSIS:
  VERIFICAR QUE ENTREGA EXISTE
  ACTUALICE ENTREGA
    UPDATE CANTIDADE = CANTIDADE - CDISM
  ACTUALICE COMPRA
    UPDATE CANTIDAD  = CANTIDAD  - CDISM
  VERIFICACION: CANTIDADE - CDISM >= 0
```

### 🧠 Resolución

Se obtienen el código del repuesto y el NIT del proveedor desde el registro de entrega. Se verifica que la disminución no deje la cantidad en negativo. Si es válido, se actualizan tanto `ENTREGA` como `COMPRA`.

```sql
DELIMITER $$
CREATE PROCEDURE TRANSACCION7(IN NE_UPD INT, IN CDISM INT)
BEGIN
    DECLARE CODI    CHAR(6);
    DECLARE NIP     CHAR(10);
    DECLARE CANTE   INT;

    SET AUTOCOMMIT = 0;
    START TRANSACTION;

    IF EXISTS(SELECT * FROM ENTREGA WHERE NE = NE_UPD) THEN
        BEGIN
            SELECT CODIGO, NIT, CANTIDADE INTO CODI, NIP, CANTE FROM ENTREGA WHERE NE = NE_UPD;

            IF (CANTE >= CDISM) THEN
                BEGIN
                    UPDATE ENTREGA SET CANTIDADE = CANTIDADE - CDISM WHERE NE = NE_UPD;
                    UPDATE COMPRA  SET CANTIDAD  = CANTIDAD  - CDISM WHERE CODIGO = CODI AND NIT = NIP;
                    IF (MYSQL_ERRNO <> 0) THEN
                        BEGIN
                            ROLLBACK;
                            SIGNAL SQLSTATE '45000'
                            SET MESSAGE_TEXT = 'TRANSACCIÓN NO COMPLETADA', MYSQL_ERRNO = '1006';
                        END;
                    END IF;
                END;
            ELSE SELECT 'LA CANTIDAD A DISMINUIR SUPERA LA CANTIDAD REGISTRADA EN LA ENTREGA'; END IF;
        END;
    ELSE SELECT 'LA ENTREGA NO EXISTE'; END IF;

    COMMIT;
END $$
DELIMITER ;

CALL TRANSACCION7(102, 1);
```

---

## 🗒️ TAREA — Transacciones Propuestas

Los siguientes problemas se proponen como práctica a realizar por parte de los estudiantes de la asignatura.

---

**T8.** Transacción que registre simultáneamente una compra y su primera entrega, y que además verifique si el repuesto es de tipo ELECTRICO o MECANICO para registrar el dato correspondiente en la tabla respectiva si aún no existe. Los datos son: código del repuesto, NIT del proveedor, cantidad, costo, ITEM del encargado, tipo de repuesto (`'E'` o `'M'`) y el dato específico (potencia o especificación).

---

**T9.** Transacción que registre una entrega de un repuesto por parte de un encargado de una ciudad determinada. Si el encargado ya tiene una entrega registrada para el mismo repuesto y proveedor, se actualice la cantidad. Caso contrario se registre una nueva entrega. Los datos son: el nombre del encargado, la ciudad, el código del repuesto y el NIT del proveedor.

---

**T10.** Transacción que elimine el registro de una compra de materiales de un proveedor determinado, actualizando también las entregas de modo que se eliminen todas las entregas cuya cantidad supere el saldo disponible luego de la eliminación. Los datos son: el código del repuesto y el NIT del proveedor.

---

**T11.** Transacción que transfiera todas las entregas asignadas a un encargado hacia otro encargado registrado en la base de datos. Se debe verificar que ambos encargados existan. Los datos son: el ITEM del encargado origen y el ITEM del encargado destino.

---

[⬅️ Volver al inicio](#) &nbsp;|&nbsp; [🗃️ Ver código SQL](./repuestos_transacciones.sql)