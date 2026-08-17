-- Cuando usar cada cosa?
-- Stored Procedures: Quiero realizar un proceso que involuca varias cosas: Ej: Grabar muchos renglones, actualizar cosas, etc. Su ejecucion no depende de un evento especifico
-- Trigger: Se ejecuta automaticamente por algun evento (alguna modificacion de algun dato) y es un stored procedure
-- Funciones: Cuando se va a realizar la misma logica muchas veces y NO PUEDE modificar datos


-- Ejercicio 1

CREATE function ej1 (@producto char(8), @deposito char(2))
RETURNS varchar(40)
AS
	BEGIN
		
		return (SELECT CASE WHEN stoc_cantidad >= ISNULL(stoc_stock_maximo,0) THEN 'DEPOSITO COMPLETO'
				ELSE 'OCUPACION DEL DEPOSITO ' + STR(stoc_cantidad/stoc_stock_maximo * 100) + '%' 
				END FROM STOCK
				WHERE stoc_producto = @producto and stoc_deposito = @deposito)
	END

SELECT stoc_producto,stoc_deposito, dbo.ej1 (stoc_producto, stoc_deposito) FROM STOCK

-- Ejercicio 2

ALTER FUNCTION ej2 (@producto char(8), @fecha date)
RETURNS decimal(12,2)
AS
	BEGIN

	return(SELECT ISNULL(SUM(stoc_cantidad),0) FROM STOCK
	WHERE stoc_producto = @producto) + (SELECT ISNULL(SUM(item_cantidad),0) FROM Item_Factura
										JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
										WHERE item_producto = @producto AND fact_fecha > @fecha)

	END


SELECT prod_codigo, dbo.ej2(prod_codigo, '01/01/2012') FROM Producto

-- Ejercicio 3

CREATE PROCEDURE ej3 @cantidadEmpleadosSinJefe INT OUTPUT
AS
	BEGIN

		SELECT @cantidadEmpleadosSinJefe = COUNT (*) FROM Empleado WHERE empl_jefe IS NULL

		UPDATE Empleado SET empl_jefe = (SELECT TOP 1 empl_codigo
											FROM Empleado
											WHERE empl_jefe IS NULL
											ORDER BY empl_salario DESC, empl_ingreso)
		WHERE empl_jefe IS NULL AND empl_codigo <>	(SELECT TOP 1 empl_codigo
													FROM Empleado
													WHERE empl_jefe IS NULL
													ORDER BY empl_salario DESC, empl_ingreso)

		RETURN

	END