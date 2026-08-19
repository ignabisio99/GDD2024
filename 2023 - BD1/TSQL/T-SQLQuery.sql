-- Ejercicio 1

CREATE function ej1 (@producto char(8),@deposito char(2))
RETURNS varchar(40)
AS
	BEGIN
		
		return (SELECT CASE WHEN stoc_cantidad >= ISNULL(stoc_stock_maximo,0) THEN 
		'DEPOSITO COMPLETO'
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


SELECT stoc_producto, dbo.ej2(stoc_producto, '01/01/2012') FROM STOCK

-- Ejercicio 3

CREATE PROCEDURE ej3 @cantidad INT OUTPUT
AS
	BEGIN

	SELECT @cantidad = COUNT(*) FROM Empleado WHERE empl_jefe IS NULL

	DECLARE @GerenteGeneral NUMERIC(6,0) = (SELECT TOP 1 empl_codigo FROM Empleado
									WHERE empl_jefe IS NULL
									ORDER BY empl_salario DESC, empl_ingreso ASC)
	
	UPDATE Empleado SET empl_jefe = @GerenteGeneral
	WHERE empl_jefe IS NULL AND empl_codigo <> @GerenteGeneral
	RETURN

	END

-- Ejercicio 4

CREATE PROCEDURE ej4 @codigo numeric(6,0) OUTPUT
AS
	BEGIN

	UPDATE Empleado SET empl_comision = (SELECT SUM(fact_total) FROM Factura
											WHERE fact_vendedor = empl_codigo
											AND YEAR(fact_fecha) = 2012)

	SELECT @codigo = (SELECT TOP 1 empl_codigo FROM Empleado
						ORDER BY empl_comision DESC)

	RETURN
	
	END

-- Ejercicio 5

IF OBJECT_ID('Fact_table','U') IS NOT NULL 
DROP TABLE Fact_table
GO

Create table Fact_table
( anio char(4) not null,
mes char(2) not null,
familia char(3) not null,
rubro char(4) not null,
zona char(3) not null,
cliente char(6) not null,
producto char(8) not null,
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint pk_Fact_table_ID primary key(anio,mes,familia,rubro,zona,cliente,producto) 


CREATE PROCEDURE ej5v1
AS
	BEGIN
		
		INSERT INTO Fact_table
			SELECT YEAR(fact_fecha),
					MONTH(fact_fecha),
					prod_familia,
					prod_rubro,
					depa_zona,
					fact_cliente,
					prod_codigo,
					SUM(item_cantidad),
					SUM(item_precio)
				FROM Factura
				JOIN Item_Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
				JOIN Producto ON prod_codigo = item_producto
				JOIN Empleado ON empl_codigo = fact_vendedor
				JOIN Departamento ON depa_codigo = empl_codigo
				GROUP BY YEAR(fact_fecha),
					MONTH(fact_fecha),
					prod_familia,
					prod_rubro,
					depa_zona,
					fact_cliente,
					prod_codigo
	END
GO

-- Ejercicio 6

CREATE PROCEDURE ej6
AS
	BEGIN
	
	DECLARE @combo char(8)
	DECLARE @comboCantidad INTEGER

	DECLARE @fact_tipo char(1)
	DECLARE @fact_sucursal char(4)
	DECLARE @fact_numero char(8)


	DECLARE cFacturas CURSOR FOR
			SELECT fact_tipo, fact_sucursal, fact_numero FROM Factura

			OPEN cFacturas

			FETCH NEXT FROM cFacturas
			INTO @fact_tipo, @fact_sucursal, @fact_numero

			WHILE @@FETCH_STATUS = 0 
				BEGIN

				DECLARE cProducto CURSOR FOR
				SELECT comp_producto FROM Composicion
				JOIN Item_Factura ON item_producto = comp_componente
				WHERE item_cantidad >= comp_cantidad
				AND item_tipo = @fact_tipo AND item_sucursal = @fact_sucursal AND item_numero = @fact_numero
				GROUP BY comp_componente
				HAVING COUNT(*) = (SELECT COUNT(*) FROM Composicion C2 WHERE c2.comp_producto = comp_producto)


				OPEN cProducto
				FETCH NEXT FROM cProducto
				INTO @combo
				WHILE @@FETCH_STATUS = 0
					BEGIN

					select @combocantidad= MIN(FLOOR((item_cantidad/c1.comp_cantidad)))
				from Item_Factura join Composicion C1 on (item_producto = C1.comp_componente)
				where item_cantidad >= C1.comp_cantidad and
					  item_sucursal = @fact_sucursal and
					  item_numero = @fact_numero and
					  item_tipo = @fact_tipo and
					  c1.comp_producto = @combo	--SACAMOS CUANTOS COMBOS PUEDO ARMAR COMO M�XIMO (POR ESO EL MIN)
				
				--INSERTAMOS LA FILA DEL COMBO CON EL PRECIO QUE CORRESPONDE
				insert into Item_Factura (item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
				select @fact_tipo, @fact_sucursal, @fact_numero, @combo, @combocantidad, 
				(@combocantidad * (select prod_precio from Producto where prod_codigo = @combo));				

				update Item_Factura  
				set 
				item_cantidad = i1.item_cantidad - (@combocantidad * (select comp_cantidad from Composicion
																		where i1.item_producto = comp_componente 
																			  and comp_producto=@combo)),
				ITEM_PRECIO = (i1.item_cantidad - (@combocantidad * (select comp_cantidad from Composicion
															where i1.item_producto = comp_componente 
																  and comp_producto=@combo))) * 	
													(select prod_precio from Producto where prod_codigo = I1.item_producto)											  															  
				from Item_Factura I1, Composicion C1 
				where I1.item_sucursal = @fact_sucursal and
					  I1.item_numero = @fact_numero and
					  I1.item_tipo = @fact_tipo AND
					  I1.item_producto = C1.comp_componente AND
					  C1.comp_producto = @combo
					  
				delete from Item_Factura
				where item_sucursal = @fact_sucursal and
					  item_numero = @fact_numero and
					  item_tipo = @fact_tipo and
					  item_cantidad = 0
				
				fetch next from cproducto into @combo
			end
			close cProducto;
			deallocate cProducto;
			
			fetch next from cFacturas into @fact_tipo, @fact_sucursal, @fact_numero
			end
			close cFacturas;
			deallocate cFacturas;

	END


-- Ejercicio 7

IF OBJECT_ID('Ventas','U')IS NOT NULL
DROP TABLE Ventas
GO
CREATE TABLE Ventas
(
vent_renglon INT IDENTITY(1,1) PRIMARY KEY,
vent_codigo char(8) NULL,
vent_detalle char(50) NULL,
vent_cant_mov INT NULL,
vent_precio decimal(12,2) NULL,
vent_ganancia decimal(12,2) NOT NULL
)

CREATE PROCEDURE ej7(@fecha1 SMALLDATETIME, @fecha2 SMALLDATETIME)
AS
	BEGIN

	INSERT INTO Ventas
		SELECT prod_codigo,
			   prod_detalle,
			   COUNT(item_cantidad),
			   AVG(item_precio),
			   SUM(fact_total-fact_total_impuestos) - SUM(item_cantidad*item_precio)
		FROM Producto
		JOIN Item_Factura ON item_producto = prod_codigo
		JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
		WHERE (fact_fecha > @fecha1) AND (fact_fecha < @fecha2)
		GROUP BY prod_codigo,prod_detalle

	END

-- Ejercicio 8

IF OBJECT_ID('Diferencias','U') IS NOT NULL
DROP TABLE Diferencias
GO
CREATE TABLE Diferencias
(
dif_codigo char(8) NULL,
dif_detalle char(50) NULL,
dif_cantidad decimal(12,2) NULL,
dif_precio_gen decimal(12,2) NULL,
dif_precio_fac decimal(12,2) NULL
)

CREATE FUNCTION calcular_precio_generado(@producto char(8))
RETURNS decimal(12,2)
AS
	BEGIN
		
		DECLARE @costoTotal decimal(12,2)
		DECLARE @componente char(8)
		DECLARE @cantidad decimal(12,2)

		if NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto = @producto)
		BEGIN
			SELECT @costoTotal = (SELECT prod_precio FROM Producto WHERE prod_codigo = @producto)
			RETURN @costoTotal
		END 

		SET @costoTotal = 0

		DECLARE cComp CURSOR FOR
		SELECT comp_componente, comp_cantidad
		FROM Composicion
		WHERE comp_producto = @producto

		OPEN cComp 
		FETCH NEXT FROM cComp INTO @componente, @cantidad
		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @costoTotal = @costoTotal + (dbo.calcular_precio_generado(@componente)) * @cantidad
				FETCH NEXT FROM cComp INTO @componente, @cantidad
			END

		CLOSE cComp
		DEALLOCATE cComp
		RETURN @costoTotal

	END


CREATE PROCEDURE ej8
AS
	BEGIN

	INSERT INTO Diferencias
		SELECT prod_codigo,
			   prod_detalle,
			   COUNT(comp_componente),
			   dbo.calcular_precio_generado(prod_codigo),
			   item_precio
		FROM Producto 
		JOIN Composicion ON comp_producto = prod_codigo
		JOIN Item_Factura ON item_producto = prod_codigo
		WHERE item_precio <> dbo.calcular_precio_generado(prod_codigo)
		GROUP BY prod_codigo, prod_detalle, item_precio


	END


-- Ejercicio 9

CREATE TRIGGER ej9 ON Item_Factura FOR UPDATE
AS
	BEGIN
			
		DECLARE @producto char(8)
		DECLARE @cantidad_i decimal(12,2)
		DECLARE @cantidad_d decimal(12,2)


		DECLARE cUpdate CURSOR FOR
		SELECT i.item_producto, i.item_cantidad, d.item_cantidad FROM Item_Factura i
		JOIN deleted d ON d.item_tipo+d.item_sucursal+d.item_numero = i.item_tipo+i.item_sucursal+i.item_numero
		AND i.item_producto = d.item_producto
		WHERE i.item_cantidad <> d.item_cantidad

		OPEN cUpdate 
		FETCH NEXT FROM cUpdate INTO @producto, @cantidad_i, @cantidad_d
		WHILE @@FETCH_STATUS = 0
			BEGIN

				IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @producto)
					BEGIN
						UPDATE STOCK
						SET stoc_cantidad = stoc_cantidad + (@cantidad_i - @cantidad_d) * comp_cantidad
						FROM STOCK
						JOIN Composicion on comp_producto = @producto AND comp_componente = stoc_producto
						WHERE stoc_deposito IN (SELECT TOP 1 stoc_deposito FROM STOCK
												WHERE stoc_producto = comp_componente AND stoc_cantidad > 0
												ORDER BY stoc_cantidad DESC)
					END	
				FETCH NEXT FROM cUpdate INTO @producto, @cantidad_i, @cantidad_d
			END
		CLOSE cUpdate
		DEALLOCATE cUpdate
	
	END


-- Ejercicio 10

CREATE TRIGGER ej10 on Producto FOR DELETE
AS
	BEGIN

		IF (SELECT SUM(s.stoc_cantidad) FROM deleted d
		JOIN STOCK s on s.stoc_producto = d.prod_codigo) > 0
			BEGIN
				ROLLBACK TRANSACTION
				PRINT 'No se puede eliminar, existe stock'
			END
		ELSE
			BEGIN
				DELETE FROM STOCK
				WHERE stoc_producto in (SELECT prod_codigo FROM deleted)

				DELETE FROM Producto
				WHERE prod_codigo IN (SELECT prod_codigo FROM deleted)
			END

	END

-- Ejercicio 11

CREATE FUNCTION ej11 (@codigo numeric(6,0))
RETURNS INT
AS
	BEGIN
		
		DECLARE @cantEmpleados INT = 0
		DECLARE @subEmplCodigo numeric(6,0)

		IF NOT EXISTS (SELECT COUNT(*) FROM Empleado
						WHERE empl_jefe = @codigo)
			BEGIN
				RETURN @cantEmpleados
			END

		SET @cantEmpleados = (SELECT COUNT(*) FROM Empleado
								WHERE empl_jefe = @codigo AND empl_codigo > @codigo)	

		DECLARE cEmpl CURSOR FOR
		(SELECT empl_codigo FROM Empleado
		WHERE empl_jefe = @codigo)

		OPEN cEmpl
		FETCH NEXT FROM cEmpl INTO @subEmplCodigo
		WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @cantEmpleados = @cantEmpleados + dbo.ej11(@subEmplCodigo)
				FETCH NEXT FROM cEmpl INTO @subEmplCodigo
			END
		CLOSE cEmpl
		DEALLOCATE cEmpl

	RETURN @cantEmpleados
	END

SELECT dbo.ej11(1)

-- Ejercicio 12

CREATE FUNCTION chequear(@producto char(8), @componente char(8))
RETURNS INT
AS
	BEGIN
		DECLARE @comp_componente_aux char(8)

		IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @componente AND comp_componente = @producto)
		BEGIN
			RETURN 1
		END

		DECLARE cComp CURSOR FOR
			SELECT comp_componente FROM Composicion
			 WHERE comp_producto = @componente

		OPEN cComp 
		FETCH NEXT INTO @comp_componente_aux
		WHILE @@FETCH_STATUS = 0
			BEGIN
				IF(dbo.chequear(@producto,@comp_componente_aux)  = 1)
				BEGIN
					RETURN 1
				END
				FETCH NEXT INTO @comp_componente_aux	
			END

			CLOSE cCopm
			DEALLOCATE cComp

		RETURN 0
	END

CREATE TRIGGER ej12 ON Composicion FOR INSERT
AS
	BEGIN

		IF EXISTS (SELECT comp_producto FROM inserted WHERE comp_producto = comp_componente)
			BEGIN
				ROLLBACK TRANSACTION
			END
		
		IF EXISTS (SELECT comp_producto FROM inserted WHERE dbo.chequear(comp_producto,comp_producto) = 1)
			BEGIN
				ROLLBACK TRANSACTION
			END

	END

-- Ejercicio 13

CREATE FUNCTION salarioEmpleados(@codigoEmpleado numeric(6,0))
RETURNS decimal(12,2)
AS
	BEGIN
		
		DECLARE @salarioAcum decimal(12,2) = 0
		DECLARE @subEmpleado numeric(6,0)

		IF NOT EXISTS (SELECT * FROM Empleado WHERE empl_jefe = @codigoEmpleado)
			BEGIN
				SELECT @salarioAcum = (SELECT empl_salario FROM Empleado WHERE empl_codigo = @codigoEmpleado)
				RETURN @salarioAcum
			END

		DECLARE cEmpleados CURSOR FOR
			SELECT empl_codigo FROM Empleado
				WHERE empl_jefe = @codigoEmpleado

		OPEN cEmpleados
		FETCH NEXT INTO @subEmpleado
		WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @salarioAcum = @salarioAcum + dbo.salarioEmpleados(@subEmpleado)
				FETCH NEXT INTO @subEmpleado
			END

		CLOSE cEmpleados
		DEALLOCATE cEmpleados
		RETURN @salarioAcum
	END


CREATE TRIGGER ej13 ON Empleado FOR INSERT
AS 
	BEGIN

	IF EXISTS (SELECT * FROM inserted 
	WHERE empl_salario > dbo.salarioEmpleados(empl_codigo) * 0.2)
		BEGIN
			ROLLBACK TRANSACTION
		END 

	END


-- Ejercicio 14

CREATE FUNCTION calcularPrecio(@producto char(8))
RETURNS decimal(12,2)
AS
	BEGIN

	DECLARE @precio decimal(12,2) 

	SELECT @precio = (SELECT SUM(prod_precio) FROM Producto
						JOIN Composicion ON comp_componente = prod_codigo
						WHERE comp_producto = @producto)
		
		RETURN @precio
	END

CREATE TRIGGER ej14 ON Item_Factura INSTEAD OF INSERT
AS
	BEGIN

		DECLARE @producto char(8)
		DECLARE @precio decimal(12,2)
		DECLARE @numero char(8)
		DECLARE @sucursal char(4)
		DECLARE @tipo char(1)
		DECLARE @fecha smalldatetime
		DECLARE @cliente char(6)
		
		DECLARE cCompra CURSOR FOR 
		(SELECT item_precio, item_producto, item_numero, item_sucursal, item_tipo FROM inserted)

		OPEN cCompra
		FETCH NEXT FROM cCompra INTO @producto, @precio, @numero, @sucursal, @tipo
		WHILE @@FETCH_STATUS = 0
			BEGIN
				
				IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @producto)
				BEGIN
					IF @precio < dbo.calcularPrecio(@producto) AND @precio >= (dbo.calcularPrecio(@producto)/2)
					BEGIN
						set @cliente= (select fact_cliente from Factura f where f.fact_numero+f.fact_sucursal+f.fact_tipo = 
										@numero+@sucursal+@tipo)
						set @fecha= (select fact_fecha from Factura f where f.fact_numero+f.fact_sucursal+f.fact_tipo = 
										@numero+@sucursal+@tipo)

						insert into Item_Factura
						select * from inserted where @producto = item_producto

						print @cliente + @fecha + @producto + @precio
					END
					else
			begin
				if(@precio >= dbo.calcularPrecio(@producto))
				begin
					insert into Item_Factura
					select * from inserted where @producto = item_producto
				end
					else
					begin
						print @producto + 'no se pudo insertar porque el precio es menor a la mitad de la suma de sus comp'
					end
			end
				END
				else 
			begin
				insert into Item_Factura
				select * from inserted where @producto = item_producto
			end
		fetch next from cursorCompra into @producto,@precio,@numero,@sucursal,@tipo

			END
		
	END


CREATE FUNCTION f_14(@producto char(8))
RETURNS decimal(12,2)
AS
	BEGIN

		DECLARE @precio decimal(12,2)

		SET @precio = (SELECT SUM(prod_precio) FROM Producto
						JOIN Composicion ON comp_componente = prod_codigo
						WHERE prod_codigo = @producto)

		RETURN @precio

	END



CREATE TRIGGER ejj14 ON Item_Factura INSTEAD OF INSERT
AS
	BEGIN

		DECLARE @i_precio decimal(12,2)
		DECLARE @i_producto char(8)
		DECLARE @i_tipo char(1)
		DECLARE @i_sucursal char(4)
		DECLARE @i_numero char(8)
		DECLARE @cliente char(6)
		DECLARE @fecha smalldatetime


		DECLARE cCompra CURSOR FOR
		SELECT item_precio, item_producto, item_tipo, item_sucursal, item_numero FROM inserted

		OPEN cCompra
		FETCH NEXT cCompra INTO @i_producto, @i_precio, @i_tipo, @i_sucursal, @i_numero
		WHILE @@FETCH_STATUS = 0
			BEGIN
				
				IF EXISTS (SELECT * FROM Composicion WHERE comp_producto = @i_producto)
				BEGIN
					
					IF @i_precio < dbo.f_14(@i_producto) AND @i_precio >= dbo.f_14(@i_producto) / 2
					BEGIN
						
						SET @cliente = (SELECT fact_cliente FROM Factura
							WHERE fact_tipo+fact_sucursal+fact_numero = @i_tipo+@i_sucursal+@i_numero)
						SET @fecha = (SELECT fact_fecha FROM Factura
										WHERE fact_tipo+fact_sucursal+fact_numero = @i_tipo+@i_sucursal+@i_numero)

						INSERT INTO Item_Factura
						SELECT * FROM inserted WHERE @i_producto = item_producto

						PRINT @fecha + @cliente + @i_producto + @i_precio
							
					END
					
				END
				

			END

	END

-- Ejercicio 15

CREATE FUNCTION precio15(@producto char(8))
RETURNS decimal(12,2)
AS
	BEGIN

		DECLARE @acum_precio decimal(12,2)
		DECLARE @aux_comp char(8)
		DECLARE @aux_cant decimal(12,2)
		
		IF NOT EXISTS (SELECT * FROM Composicion WHERE comp_producto = @producto)
		BEGIN
			SET @acum_precio = (SELECT prod_precio FROM Producto WHERE prod_codigo = @producto)
			RETURN @acum_precio
		END

		DECLARE cComp CURSOR FOR
		SELECT comp_componente, comp_cantidad FROM Composicion
		WHERE comp_producto = @producto

		OPEN cComp
		FETCH NEXT FROM cComp INTO @aux_comp, @aux_cant
		WHILE @@FETCH_STATUS = 0
			BEGIN

				SET @acum_precio = @acum_precio + dbo.precio15(@aux_comp) * @aux_cant

				FETCH NEXT FROM cComp INTO @aux_comp, @aux_cant
				
			END	

		CLOSE cComp
		DEALLOCATE cComp

		RETURN @acum_precio

	END	


CREATE FUNCTION ej15(@producto char(8))
RETURNS decimal(12,2)
AS
	BEGIN
		
		RETURN dbo.precio15(@producto)
		
	END

-- Ejercicio 16


-- Ejercicio 17

CREATE TRIGGER ej17 ON Stock FOR INSERT,UPDATE
AS
	BEGIN

		IF EXISTS (SELECT * FROM inserted
					WHERE stoc_cantidad > stoc_stock_maximo OR stoc_punto_reposicion > stoc_cantidad)
			BEGIN
					ROLLBACK TRANSACTION
			END

	END

-- Ejercicio 18

CREATE TRIGGER ej18 ON Factura INSTEAD OF INSERT
AS
	BEGIN

		INSERT INTO Factura(fact_cliente,fact_fecha,fact_numero,fact_sucursal,fact_tipo,fact_total,fact_total_impuestos,fact_vendedor)
			(SELECT * FROM inserted i 
			WHERE i.fact_cliente IN (SELECT fact_cliente FROM Factura f
									JOIN Cliente on clie_codigo = f.fact_cliente
									GROUP BY fact_cliente,clie_limite_credito
									HAVING SUM(fact_total) + i.fact_total <= clie_limite_credito ))
		
	END

-- Ejercicio 19

CREATE FUNCTION empl_19(@empleado numeric(6,0))
RETURNS INT
AS
	BEGIN

		DECLARE @aux_empl numeric(6,0)
		DECLARE @cant_empl INT = 0

		IF NOT EXISTS (SELECT * FROM Empleado WHERE empl_jefe = @empleado)
		BEGIN
			RETURN @cant_empl
		END

		SET @cant_empl = (SELECT COUNT(*) FROM Empleado WHERE empl_jefe = @empleado)

		DECLARE cEmpl CURSOR FOR
		(SELECT empl_codigo FROM Empleado WHERE empl_jefe = @empleado)

		OPEN cEmpl
		FETCH NEXT FROM cEmpl INTO @aux_empl
		WHILE @@FETCH_STATUS = 0
			BEGIN

				SET @cant_empl = @cant_empl + dbo.empl_19(@aux_empl)
				FETCH NEXT FROM cEmpl INTO @aux_empl

			END
		
		CLOSE cEmpl
		DEALLOCATE cEmpl
		
		RETURN @cant_empl
	END


CREATE TRIGGER ej19 ON Empleado FOR INSERT
AS
	BEGIN

		IF EXISTS(SELECT * FROM inserted i
					WHERE i.empl_codigo IN (SELECT empl_jefe FROM Empleado)	 AND (YEAR(GETDATE()) - YEAR(i.empl_ingreso) < 5 )
					AND dbo.empl_19(i.empl_codigo) > (SELECT COUNT(*)/2 FROM Empleado))
		BEGIN
			ROLLBACK TRANSACTION
		END

	END

-- Ejercicio 20

CREATE PROCEDURE ej20
AS
	BEGIN

		DECLARE @empleado numeric(6,0)
		DECLARE @comision decimal(12,2)

		DECLARE cEmpl CURSOR FOR
		(SELECT empl_codigo FROM Empleado)

		OPEN cEmpl 
		FETCH NEXT FROM cEmpl INTO @empleado
		WHILE @@FETCH_STATUS = 0
			BEGIN
				
				SET @comision = (SELECT (SUM(fact_total)*0.5) FROM Factura
								WHERE fact_vendedor = @empleado AND MONTH(fact_fecha) = MONTH(GETDATE()))

				IF( (SELECT COUNT(DISTINCT item_producto) FROM Factura
					JOIN Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
					WHERE fact_vendedor = @empleado AND MONTH(fact_fecha) = MONTH(GETDATE())) >= 50 )
					BEGIN
						SET @comision = @comision + (SELECT (SUM(fact_total)*0.3) FROM Factura
								WHERE fact_vendedor = @empleado AND MONTH(fact_fecha) = MONTH(GETDATE()))
					END	

			END

		CLOSE cEmpl
		DEALLOCATE cEmpl

	END


-- Ejercicio 21

CREATE TRIGGER ej21 ON Item_Factura FOR INSERT
AS	
	BEGIN
		
			DECLARE @tipo char(1)
			DECLARE @sucursal char(4)
			DECLARE @numero char(8)

		IF EXISTS (SELECT * FROM inserted i
					JOIN Producto on prod_codigo = i.item_producto
					GROUP BY i.item_tipo+i.item_sucursal+i.item_numero
					HAVING COUNT(DISTINCT prod_familia ) > 1)
			BEGIN

				DECLARE cFact CURSOR FOR
				(SELECT i.item_tipo+i.item_sucursal+i.item_numero FROM inserted i)

				OPEN cFact
				FETCH NEXT FROM cFact INTO @tipo, @sucursal, @numero
				WHILE @@FETCH_STATUS = 0
					BEGIN
						
						IF(SELECT COUNT(DISTINCT prod_familia) FROM inserted i
							JOIN Producto ON prod_codigo = i.item_producto
							WHERE i.item_tipo = @tipo AND i.item_sucursal = @sucursal AND i.item_numero = @numero
							GROUP BY i.item_tipo+i.item_sucursal+i.item_numero) > 1
							
							BEGIN
								DELETE FROM Item_Factura WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
								DELETE FROM Factura WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
							END
						FETCH NEXT FROM cFact INTO @tipo,@sucursal,@numero
					END

					CLOSE cFact
					DEALLOCATE cFact
					ROLLBACK TRANSACTION
					PRINT 'No se puede insertar una factura con productos de distintas familias'


			END

	END


-- Ejercicio 22

CREATE PROCEDURE ej22
AS
	BEGIN

		DECLARE @cant_prod INT
		DECLARE @rubro char(4)

		
		DECLARE cRubro CURSOR FOR
			(SELECT rubr_id, COUNT(DISTINCT prod_codigo) FROM Rubro
			JOIN Producto on prod_rubro = rubr_id
			GROUP BY rubr_id
			HAVING COUNT(DISTINCT prod_codigo) > 20)

		OPEN cRubro
		FETCH NEXT FROM cRubro INTO @rubro, @cant_prod
		WHILE @@FETCH_STATUS = 0
			BEGIN
				
				DECLARE @producto char(8)
				DECLARE @familia char(3)
				DECLARE @rubro_nuevo char(4)

				DECLARE cProducto CURSOR FOR
				(SELECT prod_codigo,prod_familia FROM Producto WHERE prod_rubro = @rubro)

				OPEN cProducto
				FETCH NEXT FROM cProducto INTO @producto, @familia
				WHILE @@FETCH_STATUS = 0 AND @cant_prod > 20
					BEGIN

						IF EXISTS(SELECT TOP 1 prod_rubro FROM Producto
									GROUP BY prod_rubro
									HAVING COUNT(DISTINCT prod_codigo) < 20
									ORDER BY COUNT(DISTINCT prod_codigo) ASC)
							BEGIN

								SET @rubro_nuevo = (SELECT TOP 1 prod_rubro FROM Producto
									GROUP BY prod_rubro
									HAVING COUNT(DISTINCT prod_codigo) < 20
									ORDER BY COUNT(DISTINCT prod_codigo) ASC)
								UPDATE Producto SET prod_rubro = @rubro_nuevo WHERE prod_codigo = @producto
							END
						ELSE
							BEGIN
								IF NOT EXISTS(SELECT * FROM Rubro WHERE rubr_detalle = 'RUBRO REASIGNADO')
									BEGIN
										INSERT INTO Rubro(rubr_id,rubr_detalle) VALUES ('ej21','RUBRO REASIGNADO')
									END
								UPDATE Producto SET prod_rubro = 'ej21'
							END
						SET @cant_prod = @cant_prod - 1
						FETCH NEXT FROM cProducto INTO @producto, @familia

					END
				CLOSE cProducto
				DEALLOCATE cProducto

				FETCH NEXT FROM cRubro INTO @rubro, @cant_prod

			END

			CLOSE cRubro
			DEALLOCATE cRubro


	END


-- Ejercicio 23

CREATE TRIGGER ej23 ON Item_Factura FOR INSERT
AS
	BEGIN


		IF(SELECT COUNT(DISTINCT comp_producto) FROM inserted i
			JOIN Composicion ON comp_producto = i.item_producto
			GROUP BY i.item_tipo+i.item_sucursal+i.item_numero) > 2
			
			BEGIN
				
				DECLARE @tipo char(1)
				DECLARE @sucursal char(4)
				DECLARE @numero char(8)
				
				DECLARE cFact CURSOR FOR
				(SELECT item_tipo+item_sucursal+item_numero FROM inserted)
				
				OPEN cFact
				NEXT FETCH FROM cFact INTO @tipo, @sucursal, @numero
				WHILE @@FETCH_STATUS = 0
					BEGIN
					
						IF(SELECT COUNT(DISTINCT item_producto) FROM inserted
						WHERE item_producto IN (SELECT comp_producto FROM Composicion)
						AND item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero) > 2
							BEGIN
								
								DELETE FROM Item_Factura WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
								DELETE FROM Factura WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero

							END
						FETCH NEXT FROM cFact INTO @tipo, @sucursal, @numero
					END 

				CLOSE cFact
				DEALLOCATE cFact
				ROLLBACK TRANSACTION
			END


	END 


-- Ejercicio 24

CREATE PROCEDURE ej24
AS
	BEGIN

		DECLARE @deposito char(2)
		DECLARE @zona char(1)

		DECLARE cDepo CURSOR FOR
		(SELECT depo_codigo, depo_zona FROM DEPOSITO
		JOIN Empleado ON empl_codigo = depo_encargado
		JOIN Departamento ON depa_codigo = empl_departamento
		WHERE depa_zona != depo_zona)

		OPEN cDepo
		FETCH NEXT FROM cDepo INTO @deposito, @zona
		WHILE @@FETCH_STATUS = 0
			BEGIN

				DECLARE @nuevo_encargado numeric(6,0)
				
				SET @nuevo_encargado = (SELECT TOP 1 depo_encargado FROM DEPOSITO
										JOIN Empleado ON empl_codigo = depo_encargado
										JOIN Departamento ON depa_codigo = empl_departamento
										WHERE @zona = depa_zona
										GROUP BY depo_encargado
										ORDER BY COUNT(depo_encargado))
				UPDATE DEPOSITO SET depo_encargado = @nuevo_encargado WHERE depo_codigo = @deposito

				FETCH NEXT FROM cDepo INTO @deposito, @zona
			END

		CLOSE cDepo
		DEALLOCATE cDepo
		

	END

-- Ejercicio 25

CREATE TRIGGER ej25 ON Composicion FOR INSERT, UPDATE
AS
	BEGIN
		
		IF EXISTS(SELECT * FROM inserted c1
					JOIN Composicion c2 ON c2.comp_componente = c1.comp_producto AND c2.comp_producto = c1.comp_componente)
				BEGIN

						ROLLBACK TRANSACTION
				END
		
	END


-- Ejercicio 26

CREATE TRIGGER ej26 ON Item_Factura FOR INSERT
AS
	BEGIN

		DECLARE @tipo char(1)
		DECLARE @sucursal char(4)
		DECLARE @numero char(8)

		IF EXISTS(SELECT * FROM inserted i
				JOIN Composicion c on c.comp_componente = i.item_producto
				GROUP BY i.item_producto)

		DECLARE cFact CURSOR FOR
		(SELECT item_tipo,item_sucursal,item_numero FROM inserted
		WHERE item_producto IN (SELECT comp_componente FROM Composicion))

		OPEN cFact
		FETCH NEXT FROM cFact INTO @tipo, @sucursal, @numero
		WHILE @@FETCH_STATUS = 0
			BEGIN
				

					DELETE FROM Item_Factura WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
					DELETE FROM Factura WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
				FETCH NEXT FROM cFact INTO @tipo, @sucursal, @numero

			END

		CLOSE cFact
		DEALLOCATE cFact
		PRINT 'No se puede crear una factura con productos que sean componentes de composicion' 
		ROLLBACK TRANSACTION
	END


-- Ejercicio 27

CREATE PROCEDURE ej27
AS
	BEGIN

		DECLARE @deposito char(2)

		
		DECLARE cDepo CURSOR FOR
		(SELECT depo_codigo FROM DEPOSITO)

		OPEN cDepo
		FETCH NEXT FROM cDepo INTO @deposito
		WHILE @@FETCH_STATUS = 0
			BEGIN

				DECLARE @nuevo_encargado numeric(6,0)

				SET @nuevo_encargado = (SELECT TOP 1 depo_encargado FROM DEPOSITO
										WHERE depo_encargado NOT IN(SELECT empl_jefe FROM Empleado)
										AND depo_encargado NOT IN (SELECT clie_vendedor FROM Cliente)
										GROUP BY depo_encargado
										ORDER BY COUNT(*) ASC)

				UPDATE DEPOSITO SET depo_encargado = @nuevo_encargado WHERE depo_codigo = @deposito

				FETCH NEXT FROM cDepo Into @deposito
			END

		CLOSE cDepo
		DEALLOCATE cDepo
	END

-- Ejercicio 28

CREATE PROCEDURE ej28
AS
	BEGIN
		
		DECLARE @cliente char(6)

		DECLARE cClie CURSOR FOR
		(SELECT clie_codigo FROM Cliente)

		OPEN cClie
		FETCH NEXT FROM cClie INTO @cliente
		WHILE @@FETCH_STATUS = 0
			BEGIN
				
				DECLARE @vendedor numeric(6,0)
					
				IF EXISTS(SELECT clie_codigo FROM Cliente
							WHERE clie_codigo NOT IN (SELECT fact_cliente FROM Factura))
					BEGIN
						
						SET @vendedor = (SELECT TOP 1 fact_vendedor FROM Factura
										GROUP BY fact_vendedor
										ORDER BY SUM(fact_total) DESC )
						 UPDATE Cliente SET clie_vendedor = @vendedor WHERE clie_codigo = @cliente
					END
				ELSE
					BEGIN

						SET @vendedor = (SELECT TOP 1 fact_cliente FROM Factura
										WHERE fact_cliente = @cliente
										GROUP BY fact_cliente
										ORDER BY COUNT(*) DESC )
						
						UPDATE Cliente SET clie_vendedor = @vendedor WHERE clie_codigo = @cliente

					END

					FETCH NEXT FROM cClie INTO @cliente

			END

		CLOSE cClie
		DEALLOCATE cClie


	END

-- Ejercicio 29

CREATE TRIGGER ej29 ON Item_Factura FOR INSERT
AS
	BEGIN

	/*(SELECT c1.comp_producto, c2.comp_producto FROM Item_Factura i
					JOIN Item_Factura i2 ON i2.item_tipo+i2.item_sucursal+i2.item_numero = i.item_tipo+i.item_sucursal+i.item_numero
					JOIN Composicion c1 ON comp_componente = i.item_producto
					JOIN Composicion c2 ON c2.comp_componente = i2.item_producto
					WHERE c1.comp_producto != c2.comp_producto)
		OTRA FORMA DE HACERLO*/
		IF EXISTS(SELECT * FROM inserted i
				 JOIN inserted i2 ON i2.item_tipo+i2.item_sucursal+i2.item_numero = i.item_tipo+i.item_sucursal+i.item_numero
				 JOIN Composicion c ON c.comp_componente = i.item_producto
				 JOIN Composicion c2 ON c2.comp_componente = i2.item_producto
				 WHERE i.item_producto != i2.item_producto AND c.comp_producto != c2.comp_producto)
			BEGIN

				DECLARE @tipo char(1)
				DECLARE @sucursal char(4)
				DECLARE @numero char(8)

				DECLARE cFact CURSOR FOR
				(SELECT item_tipo,item_sucursal,item_numero FROM inserted)

				OPEN cFact
				FETCH NEXT FROM cFact INTO @tipo,@sucursal,@numero
				WHILE @@FETCH_STATUS = 0
					BEGIN


						IF(SELECT COUNT(comp_producto) FROM inserted
							JOIN Composicion ON comp_componente = item_producto
							WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
							GROUP BY comp_componente) > 1
							
							BEGIN

								DELETE FROM Item_Factura WHERE item_tipo+item_sucursal+item_numero = @tipo+@sucursal+@numero
								DELETE FROM Factura WHERE fact_tipo+fact_sucursal+fact_numero = @tipo+@sucursal+@numero
							END
						FETCH NEXT FROM cFact INTO @tipo,@sucursal,@numero

					END

					ROLLBACK TRANSACTION

					CLOSE cFact
					DEALLOCATE cFact

					PRINT 'NO SE PUEDE GENERAR UNA FACTURA CON COMPONENTES DE COMBOS DIFERENTES'


			END	
			
	END
