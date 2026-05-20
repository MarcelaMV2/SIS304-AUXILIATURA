USE REPUESTOS;
-- 1.Funcion que devuelva el costo más alto de un repuesto con cantidad superior a un valor introducido: 
-- Crea una función que reciba un valor como parámetro y devuelva el costo más alto de los repuestos 
-- cuya cantidad en la tabla COMPRA sea mayor a ese valor introducido, utilizando la tabla de compras.
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

SET @CMAX=FUN1(16);
SELECT @CMAX AS 'COSTO MAXIMO';
SELECT * FROM COMPRA;
UPDATE COMPRA SET COSTO=345 WHERE CODIGO='R-0001' AND NIT='1011222450';

-- 2.Funcion que devuelva el total de entregas realizadas por un encargado en un mes: Crea una función 
-- que reciba el ITEM de un encargado, el MES y el AÑO como parámetros, y devuelva el número total de 
-- entregas realizadas por ese encargado durante el mes y año indicados.
SELECT * FROM ENTREGA;
DELIMITER $$
CREATE FUNCTION FUN2(ITEN INT,MES INT, ANIO INT) RETURNS INT 
READS SQL DATA DETERMINISTIC
BEGIN
DECLARE CEN INT;
SELECT COUNT(*) INTO CEN 
FROM ENTREGA
WHERE ITEM=ITEN AND MONTH(FECHAE)=MES AND YEAR(FECHAE)=ANIO;
RETURN CEN;
END $$
DELIMITER ;

SET @CANE = FUN2(10010,9,2024);
SELECT @CANE AS 'CANTIDAD DE ENTREGAS';

-- 3. Funcion que devuelva el número total de repuestos entregados entre dos fechas: Crea una función 
-- que reciba dos fechas (inicial y final) y devuelva el número total de repuestos entregados entre 
-- esas fechas, utilizando la tabla ENTREGA.
DELIMITER $$
CREATE FUNCTION FUN3(F1 DATE, F2 DATE) RETURNS INT 
READS SQL DATA DETERMINISTIC
BEGIN
DECLARE TOTAL INT;
DECLARE AUX DATE;
IF(F1>F2) THEN
SET AUX = F1;
SET F1 = F2;
SET F2 = AUX;
END IF;
SELECT SUM(CANTIDADE) INTO TOTAL
FROM ENTREGA 
WHERE DATE(FECHAE) BETWEEN F1 AND F2;
RETURN TOTAL;
END $$
DELIMITER ;

SET @TOT = FUN3('2020-10-10', '2025-10-10');
SELECT @TOT AS 'CANTIDAD DE ENTREGA TOTAL';

-- 4. Funcion que devuelva el repuesto con la mayor cantidad comprada en un año: Crea una función que 
-- reciba un AÑO como parámetro y devuelva el código del repuesto con la mayor cantidad comprada durante 
-- ese año, consultando la tabla COMPRA.
DELIMITER $$
CREATE FUNCTION FUN4(ANIO INT) RETURNS VARCHAR(50) 
READS SQL DATA DETERMINISTIC
BEGIN
DECLARE REP VARCHAR(50);
DECLARE CMAX INT;
DECLARE COR CHAR(6);
SELECT CODIGO,MAX(CANTIDAD) INTO COR,CMAX 
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
SELECT * FROM REPUESTO;

-- 5.Funcion que devuelva el total de repuestos vendidos por proveedor dentro de un rango de costos: 
-- Crea una función que reciba un NIT de proveedor, y un rango de COSTOS (mínimo y máximo) como 
-- parámetros, y devuelva el total de repuestos vendidos por ese proveedor dentro de ese rango de costos en la tabla COMPRA.
DELIMITER $$
CREATE FUNCTION FUN5(NIP CHAR(10), CMIN INT, CMAX INT) RETURNS INT
READS SQL DATA DETERMINISTIC
BEGIN
DECLARE TVENDIDOS INT;
SELECT SUM(CANTIDAD) INTO TVENDIDOS
FROM COMPRA
WHERE NIT=NIP AND COSTO BETWEEN CMIN AND CMAX;
RETURN TVENDIDOS;
END $$
DELIMITER ;
SET @TOTVEN = FUN5('1011112450',100,300);
SELECT @TOTVEN AS 'TOTAL DE REPUESTOS VENDIDOS';
SELECT * FROM COMPRA;


-- 6. Funcion que devuelva el proveedor con más repuestos vendidos en un mes: Crea una función que 
-- reciba el MES y AÑO como parámetros y devuelva el NIT del proveedor que haya vendido más 
-- repuestos durante ese mes y año, a partir de los datos en la tabla COMPRA.
DELIMITER $$
CREATE FUNCTION FUN6(MES INT, ANIO INT) RETURNS VARCHAR(50)
READS SQL DATA DETERMINISTIC
BEGIN
DECLARE PROV VARCHAR(50);
DECLARE NIP CHAR(10);
DECLARE CMAX INT;
SELECT NIT,MAX(CANTIDAD) INTO NIP,CMAX
FROM COMPRA 
WHERE MONTH(FECHA)=MES AND YEAR(FECHA)=ANIO
GROUP BY NIT
ORDER BY CMAX DESC
LIMIT 1;

SELECT NOMBREP INTO PROV
FROM PROVEEDOR 
WHERE NIT = NIP;
RETURN PROV;
END $$
DELIMITER ;
SET @PROV = FUN6(9,2025);
SELECT @PROV AS 'PROVEEDOR CON MAS VENTAS';

-- Funcion que devuelva el costo promedio de compra por repuesto: Crea una función que reciba un 
-- CODIGO de repuesto y devuelva el costo promedio de todas las compras realizadas para ese repuesto, 
-- consultando la tabla COMPRA.
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

-- Funcion que devuelva el encargado que más entregas ha realizado en un mes: Crea una función que 
-- reciba un MES y AÑO como parámetros y devuelva el nombre del encargado que más entregas ha 
-- realizado durante ese mes y año, consultando las tablas ENCARGADO y ENTREGA.

-- Funcion que devuelva la cantidad total de repuestos entregados por proveedor en un rango de fechas: 
-- Crea una función que reciba un NIT de proveedor y un rango de fechas como parámetros, y devuelva 
-- la cantidad total de repuestos entregados por ese proveedor durante ese rango de fechas, usando las tablas ENTREGA y COMPRA.

-- Funcion que devuevla el repuesto más reciente comprado por un proveedor: Crea una función que 
-- reciba el NIT de un proveedor y devuelva el código del repuesto más reciente comprado por ese 
-- proveedor, basándose en la fecha de compra registrada en la tabla COMPRA.