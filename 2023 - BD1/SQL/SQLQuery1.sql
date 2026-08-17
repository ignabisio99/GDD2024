-- Ejercicio 1

SELECT clie_codigo, clie_razon_social FROM Cliente
WHERE clie_limite_credito >= 1000
ORDER BY clie_codigo

-- Ejercicio 2

SELECT prod_codigo, prod_detalle FROM Producto
JOIN Item_Factura on item_producto = prod_codigo
JOIN Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
WHERE year(fact_fecha) = 2012
GROUP BY prod_codigo, prod_detalle
ORDER BY sum(item_cantidad)

-- Ejercicio 3

SELECT prod_codigo, prod_detalle, SUM(stoc_cantidad) FROM Producto
JOIN STOCK on stoc_producto = prod_codigo
GROUP BY prod_codigo, prod_detalle
ORDER BY prod_detalle

-- Ejercicio 4

SELECT p.prod_codigo, p.prod_detalle, COUNT(c.comp_componente)
FROM Producto p
LEFT JOIN Composicion c ON c.comp_producto = p.prod_codigo
WHERE p.prod_codigo IN (SELECT s.stoc_producto FROM STOCK s
						GROUP BY s.stoc_producto
						HAVING AVG(s.stoc_cantidad) > 100)
GROUP BY p.prod_codigo, p.prod_detalle

-- Ejercicio 5

SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) as CantEgresos
FROM Producto p
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_codigo, p.prod_detalle
HAVING SUM(i.item_cantidad) > (SELECT SUM(i2.item_cantidad)
								FROM Item_Factura i2 
								JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
								WHERE YEAR(f2.fact_fecha) = 2011 AND i2.item_producto = p.prod_codigo
								GROUP BY i2.item_producto)

-- Ejercicio 6

SELECT r.rubr_id, r.rubr_detalle, COUNT(p.prod_codigo) as CantProd, SUM(s.stoc_cantidad) as StockRubro
FROM Rubro r
JOIN Producto p ON p.prod_rubro = r.rubr_id
JOIN STOCK s ON s.stoc_producto = p.prod_codigo
WHERE p.prod_codigo IN (SELECT s2.stoc_producto 
						FROM STOCK s2
						WHERE s2.stoc_deposito = '00'
						GROUP BY s2.stoc_producto
						HAVING SUM(s2.stoc_cantidad) > (SELECT SUM(s3.stoc_cantidad)
														FROM STOCK s3
														WHERE s3.stoc_producto = '00000000' AND s3.stoc_deposito = '00'
														GROUP BY s3.stoc_producto))
GROUP BY r.rubr_id, r.rubr_detalle

-- Ejercicio 7

SELECT p.prod_codigo, p.prod_detalle, MAX(i.item_precio) as MayorPrecio, MIN(i.item_precio) MinPrecio, CAST((MAX(i.item_precio) - MIN(i.item_precio)) * 100 /MIN(i.item_precio) AS DECIMAL(10,2)) as DifPrecios
FROM Producto p
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
WHERE p.prod_codigo in (SELECT s.stoc_producto
						FROM STOCK s
						GROUP BY s.stoc_producto
						HAVING SUM(s.stoc_cantidad) > 0)
GROUP BY p.prod_codigo, p.prod_detalle

-- Ejercicio 8

SELECT p.prod_detalle, MAX(s.stoc_cantidad) as MayorStock
FROM Producto p
JOIN STOCK s ON s.stoc_producto = p.prod_codigo
GROUP BY p.prod_detalle
HAVING COUNT(*) = (SELECT COUNT(*) FROM DEPOSITO)

-- Ejercicio 9

SELECT e.empl_jefe, e.empl_codigo, e.empl_nombre, 
	(SELECT COUNT(d2.depo_codigo) FROM DEPOSITO d2 WHERE d2.depo_encargado = e.empl_jefe) as CantDeposJefe,
	(SELECT COUNT(d3.depo_codigo) FROM DEPOSITO d3 WHERE d3.depo_encargado = e.empl_codigo) as CantDeposEmp
FROM Empleado e
GROUP BY e.empl_jefe, e.empl_codigo, e.empl_nombre

-- Ejercicio 10

SELECT p.prod_detalle, (SELECT TOP 1 f.fact_cliente
						FROM Factura f
						JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero
						WHERE i.item_producto = p.prod_codigo
						GROUP BY f.fact_cliente
						ORDER BY SUM(i.item_cantidad) DESC) as ClienteConMasCompras
FROM Producto p
WHERE p.prod_codigo IN (SELECT TOP 10 i1.item_producto
						FROM Item_Factura i1
						GROUP BY i1.item_producto
						ORDER BY SUM(i1.item_cantidad) DESC)
OR
p.prod_codigo IN (SELECT TOP 10 i2.item_producto
					FROM Item_Factura i2
					GROUP BY i2.item_producto
					ORDER BY SUM(i2.item_cantidad) ASC)

-- Ejercicio 11

SELECT fa.fami_detalle, COUNT(DISTINCT i.item_producto) AS CantVentasProdDif, SUM(f.fact_total) - SUM(f.fact_total_impuestos) AS TotalSinImpuestos
FROM Familia fa
JOIN Producto p ON p.prod_familia = fa.fami_id
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
GROUP BY fa.fami_detalle, fa.fami_id
HAVING (SELECT SUM(i.item_cantidad * i.item_precio)
		FROM Producto p2
		JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
		JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
		WHERE p2.prod_familia = fa.fami_id AND YEAR(f2.fact_fecha) = 2012
		GROUP BY p2.prod_familia) > 20000
ORDER BY COUNT(DISTINCT i.item_producto) DESC

-- Ejercicio 12

SELECT p.prod_detalle, COUNT(DISTINCT f.fact_cliente) as CantCliDistVentas, AVG(i.item_precio) as ImportePromPag, 
	(SELECT COUNT(stoc_cantidad) FROM STOCK WHERE stoc_producto = p.prod_codigo AND stoc_cantidad > 0) as CantDepoConStock,
	(SELECT SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto = p.prod_codigo) as CantStockActual
FROM Producto p
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
WHERE p.prod_codigo IN (SELECT i2.item_producto
						FROM Item_Factura i2
						JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
						WHERE YEAR(f2.fact_fecha) = 2012)
GROUP BY p.prod_detalle, p.prod_codigo
ORDER BY SUM(i.item_precio) DESC

-- Ejercicio 13

SELECT p.prod_detalle, p.prod_precio, SUM(p2.prod_precio * c.comp_cantidad) as SumatoriaPrecioComponentes
FROM Producto p
JOIN Composicion c ON c.comp_producto = p.prod_codigo
JOIN Producto p2 ON p2.prod_codigo = c.comp_componente
GROUP BY p.prod_detalle, p.prod_precio
HAVING COUNT(c.comp_componente) > 0
ORDER BY COUNT(c.comp_componente) DESC

-- Ejercicio 14

SELECT c.clie_codigo, COUNT(f.fact_numero) as CantComprasUltAño, AVG(f.fact_total) PromCompraUltAño, COUNT(DISTINCT i.item_producto) CantProdDifUltAño, MAX(f.fact_total) MayorCompraUltAño
FROM Cliente c
LEFT JOIN Factura f ON f.fact_cliente = c.clie_codigo
JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero
WHERE YEAR(f.fact_fecha) = 2012 -- Ultimo año de la base de datos
GROUP BY c.clie_codigo
ORDER BY COUNT(f.fact_numero)

-- Ejercicio 15

SELECT p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle, COUNT(i1.item_numero) as CantVentasJuntos
FROM Producto p1 
JOIN Item_Factura i1 ON i1.item_producto = p1.prod_codigo
JOIN Item_Factura i2 ON i2.item_tipo+i2.item_sucursal+i2.item_numero=i1.item_tipo+i1.item_sucursal+i1.item_numero
JOIN Producto p2 ON p2.prod_codigo = i2.item_producto AND p2.prod_codigo > p1.prod_codigo
GROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
HAVING COUNT(i1.item_numero) > 500
ORDER BY COUNT(i1.item_numero)

-- Ejercicio 16

SELECT c.clie_razon_social, SUM(i.item_cantidad) as CantUnidVendidas,
	(SELECT TOP 1 SUM(i2.item_cantidad)
	FROM Item_Factura i2
	JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
	JOIN Cliente c2 ON c2.clie_codigo = f2.fact_cliente
	WHERE c2.clie_codigo = c.clie_codigo
	GROUP BY c2.clie_codigo, i2.item_producto
	ORDER BY i2.item_producto DESC) as ProductoMasVendido
FROM Cliente c
JOIN Factura f ON f.fact_cliente = c.clie_codigo
JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY c.clie_razon_social, c.clie_codigo,c.clie_domicilio
HAVING SUM(f.fact_total) < (SELECT TOP 1 AVG(i3.item_cantidad * i3.item_precio)*0.3
							FROM Item_Factura i3
							JOIN Factura f3 ON f3.fact_tipo+f3.fact_sucursal+f3.fact_numero=i3.item_tipo+i3.item_sucursal+i3.item_numero
							WHERE YEAR(f3.fact_fecha) = 2012
							ORDER BY SUM(i3.item_cantidad * i3.item_precio) DESC)
ORDER BY c.clie_domicilio ASC

-- Ejercicio 17

SELECT FORMAT(f.fact_fecha,'yyyy/MM') as Periodo, p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) as CantVendida,
	(SELECT ISNULL(SUM(ISNULL(i2.item_cantidad,0)),0)
	FROM Factura f2
	JOIN Item_Factura i2 ON i2.item_tipo+i2.item_sucursal+i2.item_numero=f2.fact_tipo+f2.fact_sucursal+f2.fact_numero
	WHERE i2.item_producto = p.prod_codigo AND YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) - 1 AND MONTH(f2.fact_fecha) = MONTH(f.fact_fecha)) as VentasAñoAnt,
	COUNT(f.fact_numero) as CantFacturas
FROM Producto p
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
GROUP BY p.prod_codigo, p.prod_detalle, f.fact_fecha
ORDER BY f.fact_fecha, p.prod_codigo

-- Ejercicio 18

SELECT r.rubr_detalle, SUM(i.item_cantidad * i.item_precio) as Ventas,
	ISNULL((SELECT TOP 1 p2.prod_codigo
	FROM Producto p2
	JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
	WHERE p2.prod_rubro = r.rubr_id
	GROUP BY p2.prod_codigo
	ORDER BY SUM(i2.item_cantidad) DESC),0) as PROD1,
	ISNULL((SELECT TOP 1 p3.prod_codigo
	FROM Producto p3
	JOIN Item_Factura i3 ON i3.item_producto = p3.prod_codigo
	WHERE p3.prod_rubro = r.rubr_id and p3.prod_codigo <> (SELECT TOP 1 p5.prod_codigo
															FROM Producto p5
															JOIN Item_Factura i5 ON i5.item_producto = p5.prod_codigo
															WHERE p5.prod_rubro = r.rubr_id
															GROUP BY p5.prod_codigo
															ORDER BY SUM(i5.item_cantidad) DESC)
	GROUP BY p3.prod_codigo
	ORDER BY SUM(i3.item_cantidad) DESC),0) as PROD2,
	(SELECT TOP 1 f4.fact_cliente
	FROM Factura f4
	JOIN Item_Factura i4 ON i4.item_tipo+i4.item_sucursal+i4.item_numero=f4.fact_tipo+f4.fact_sucursal+f4.fact_numero
	JOIN Producto p4 ON p4.prod_codigo = i4.item_producto
	JOIN Rubro r4 ON r4.rubr_id = p4.prod_rubro
	WHERE r4.rubr_id = r.rubr_id
	GROUP BY f4.fact_cliente,r4.rubr_id
	ORDER BY SUM(i4.item_cantidad) DESC) as Cliente
FROM Rubro r
JOIN Producto p ON p.prod_rubro = r.rubr_id
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
GROUP BY r.rubr_detalle, r.rubr_id
ORDER BY COUNT(DISTINCT i.item_producto)

-- Ejercicio 19

SELECT p.prod_codigo, p.prod_detalle, p.prod_familia, fa.fami_detalle,
	(SELECT TOP 1 fa2.fami_id
	FROM Producto p2
	JOIN Familia fa2 ON fa2.fami_id = p2.prod_familia
	WHERE LEFT(p2.prod_detalle,5) = LEFT(p.prod_detalle,5) AND p2.prod_familia != p.prod_familia
	GROUP BY fa2.fami_id, fa2.fami_detalle
	ORDER BY COUNT(fa2.fami_detalle) DESC, fa2.fami_detalle ASC) as CodFamSug,
	(SELECT TOP 1 fa2.fami_detalle
	FROM Producto p2
	JOIN Familia fa2 ON fa2.fami_id = p2.prod_familia
	WHERE LEFT(p2.prod_detalle,5) = LEFT(p.prod_detalle,5) AND p2.prod_familia != p.prod_familia
	GROUP BY fa2.fami_id, fa2.fami_detalle
	ORDER BY COUNT(fa2.fami_detalle) DESC, fa2.fami_detalle ASC) as DetFamSug
FROM Producto p
JOIN Familia fa on fa.fami_id = p.prod_familia
GROUP BY p.prod_codigo, p.prod_detalle, p.prod_familia, fa.fami_detalle
ORDER BY p.prod_detalle

-- Ejercicio 20

SELECT TOP 3 e.empl_codigo, e.empl_nombre, e.empl_apellido, YEAR(e.empl_ingreso) AS AñoIngreso,
	CASE
		WHEN (SELECT COUNT(f.fact_vendedor)
				FROM Factura f
				WHERE f.fact_vendedor = e.empl_codigo AND YEAR(f.fact_fecha) = 2011) >= 50
			THEN (SELECT COUNT(f2.fact_numero)
					FROM Factura f2
					WHERE f2.fact_total > 100 AND f2.fact_vendedor = e.empl_codigo AND YEAR(f2.fact_fecha) = 2011)
			ELSE (SELECT COUNT(f2.fact_numero) * 0.5
					FROM Factura f2
					JOIN Empleado e2 ON e2.empl_codigo = f2.fact_vendedor
					WHERE e2.empl_jefe = e.empl_codigo AND YEAR(f2.fact_fecha) = 2011)
				END 'Puntaje 2011',
	CASE
		WHEN (SELECT COUNT(f.fact_vendedor)
				FROM Factura f
				WHERE f.fact_vendedor = e.empl_codigo AND YEAR(f.fact_fecha) = 2012) >= 50
			THEN (SELECT COUNT(f2.fact_numero)
					FROM Factura f2
					WHERE f2.fact_total > 100 AND f2.fact_vendedor = e.empl_codigo AND YEAR(f2.fact_fecha) = 2012)
			ELSE (SELECT COUNT(f2.fact_numero) * 0.5
					FROM Factura f2
					JOIN Empleado e2 ON e2.empl_codigo = f2.fact_vendedor
					WHERE e2.empl_jefe = e.empl_codigo AND YEAR(f2.fact_fecha) = 2012)
				END 'Puntaje 2012'
FROM Empleado e
GROUP BY e.empl_codigo, e.empl_nombre, e.empl_apellido, YEAR(e.empl_ingreso)
ORDER BY 'Puntaje 2012' DESC

-- Ejercicio 21

SELECT YEAR(f.fact_fecha) as Año,
	COUNT(DISTINCT f.fact_cliente) as ClientesMalFacturados,
	COUNT(f.fact_numero) AS FacturasMalRealizadas
FROM Factura f
WHERE ABS((f.fact_total - f.fact_total_impuestos) - (SELECT SUM(i.item_cantidad * i.item_precio)
												FROM Item_Factura i
												WHERE i.item_tipo+i.item_sucursal+i.item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero)) > 1
GROUP BY YEAR(f.fact_fecha)
HAVING COUNT(*) > 0

-- Ejercicio 22

SELECT r.rubr_detalle, DATEPART(QUARTER,f.fact_fecha) AS NumeroTrimestre,
	COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as CantFacturas,
	COUNT(DISTINCT p.prod_codigo) as CantProd
FROM Rubro r
JOIN Producto p ON p.prod_rubro = r.rubr_id
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_tipo+f.fact_sucursal+f.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
WHERE p.prod_codigo NOT IN (SELECT comp_producto
						FROM Composicion)
GROUP BY r.rubr_detalle, DATEPART(QUARTER,f.fact_fecha)
HAVING COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) > 100
ORDER BY r.rubr_detalle, COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) DESC

-- Ejercicio 23

SELECT YEAR(f.fact_fecha) as Año,
	(SELECT TOP 1 p2.prod_detalle
			FROM Composicion c1
			JOIN Item_Factura i2 ON i2.item_producto = c1.comp_producto
			JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
			JOIN Producto p2 on p2.prod_codigo = c1.comp_producto
			WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
			GROUP BY p2.prod_detalle
			ORDER BY SUM(i2.item_cantidad) DESC) as ProdConCompMasVend,
	(SELECT TOP 1 COUNT(DISTINCT c1.comp_componente)
			FROM Composicion c1
			JOIN Item_Factura i2 ON i2.item_producto = c1.comp_producto
			JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
			WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
			GROUP BY c1.comp_producto
			ORDER BY SUM(i2.item_cantidad) DESC) as CantProdDelComp,
	(SELECT TOP 1 COUNT(DISTINCT f2.fact_tipo+f2.fact_sucursal+f2.fact_numero)
			FROM Composicion c1
			JOIN Item_Factura i2 ON i2.item_producto = c1.comp_producto
			JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
			WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
			GROUP BY c1.comp_producto
			ORDER BY SUM(i2.item_cantidad) DESC) as CantFacturas,
	(SELECT TOP 1 f2.fact_cliente
			FROM Composicion c1
			JOIN Item_Factura i2 ON i2.item_producto = c1.comp_producto
			JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
			WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
			GROUP BY c1.comp_producto, f2.fact_cliente
			ORDER BY SUM(i2.item_cantidad) DESC, f2.fact_cliente DESC) as ClienteMasCompras,
	(SELECT TOP 1 CAST(SUM(i.item_cantidad * i.item_precio)*100/SUM(f2.fact_total) AS DECIMAL(10,2))
			FROM Composicion c1
			JOIN Item_Factura i2 ON i2.item_producto = c1.comp_producto
			JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
			WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
			GROUP BY c1.comp_producto
			ORDER BY SUM(i2.item_cantidad) DESC) as PorcentajeVentaRespectoTotal
FROM Factura f
JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero
GROUP BY YEAR(f.fact_fecha)
ORDER BY SUM(f.fact_total) DESC

-- Ejercico 24

SELECT i.item_producto, p.prod_detalle, SUM(i.item_cantidad) as UnidadesFacturadas
FROM Item_Factura i
JOIN Factura F ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
JOIN Producto p ON p.prod_codigo = i.item_producto
WHERE f.fact_vendedor IN (SELECT TOP 2 e2.empl_codigo
							FROM Empleado e2
							ORDER BY e2.empl_comision DESC)
	AND p.prod_codigo IN (SELECT comp_producto FROM Composicion)
GROUP BY i.item_producto, p.prod_detalle
HAVING COUNT(i.item_tipo+i.item_sucursal+i.item_numero) >= 5
ORDER BY SUM(i.item_cantidad) DESC

-- Ejercicio 25

SELECT YEAR(f.fact_fecha) as Año, p.prod_familia AS FamMasVend,
	(SELECT COUNT(DISTINCT p3.prod_rubro)
	FROM Producto p3
	WHERE p3.prod_familia = p.prod_familia) AS CantRubrosFam,
	(SELECT COUNT(DISTINCT c2.comp_componente)
	FROM Composicion c2
	WHERE c2.comp_producto IN (SELECT TOP 1 p4.prod_codigo
								FROM Factura f4
								JOIN Item_Factura i4 ON i4.item_tipo+i4.item_sucursal+i4.item_numero=f4.fact_tipo+f4.fact_sucursal+f4.fact_numero
								JOIN Producto p4 ON p4.prod_codigo = i4.item_producto
								WHERE YEAR(f4.fact_fecha) = YEAR(f.fact_fecha) AND p4.prod_familia = p.prod_familia
								GROUP BY p4.prod_codigo
								ORDER BY SUM(i4.item_cantidad) DESC)) as CantComprProdMasVend,
	COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as CantFacturasFam,
	(SELECT TOP 1 f5.fact_cliente
	FROM Factura f5
	JOIN Item_Factura i5 ON i5.item_tipo+i5.item_sucursal+i5.item_numero=f5.fact_tipo+f5.fact_sucursal+f5.fact_numero
	JOIN Producto p5 ON p5.prod_codigo = i5.item_producto
	WHERE p5.prod_familia = p.prod_familia AND YEAR(f5.fact_fecha) = YEAR(f.fact_fecha)
	GROUP BY f5.fact_cliente
	ORDER BY SUM(i5.item_cantidad) DESC) as ClienteMasComprasFam,
	CAST(SUM(i.item_cantidad * i.item_precio) * 100/(SELECT SUM(f2.fact_total)
													 FROM Factura f2
													 WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)) AS Decimal(10,2)) as ProcentajeRespectoTotal
FROM Factura f
JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero
JOIN Producto p ON p.prod_codigo = i.item_producto
WHERE p.prod_familia IN (SELECT TOP 1 p2.prod_familia
						FROM Producto p2
						JOIN Item_Factura i2 ON i2.item_producto = p2.prod_codigo
						JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero
						WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
						GROUP BY p2.prod_familia,  YEAR(f2.fact_fecha)
						ORDER BY SUM(i2.item_cantidad) DESC)
GROUP BY YEAR(f.fact_fecha), p.prod_familia
ORDER BY SUM(i.item_cantidad*i.item_precio) DESC

-- Ejercicio 26

SELECT e.empl_codigo, (SELECT COUNT(d2.depo_codigo) FROM DEPOSITO d2 WHERE d2.depo_encargado = e.empl_codigo) AS CantDeposACargo, SUM(f.fact_total) AS TotalFacturado,
	(SELECT TOP 1 f2.fact_cliente
	FROM Factura f2
	WHERE f2.fact_vendedor = e.empl_codigo
	GROUP BY f2.fact_cliente
	ORDER BY COUNT(f2.fact_tipo+f2.fact_sucursal+f2.fact_numero) DESC) AS ClienteMasVendido,
	(SELECT TOP 1 i3.item_producto
	FROM Factura f3
	JOIN Item_Factura i3 ON i3.item_tipo+i3.item_sucursal+i3.item_numero=f3.fact_tipo+f3.fact_sucursal+f3.fact_numero
	WHERE f3.fact_vendedor = e.empl_codigo
	GROUP BY i3.item_producto
	ORDER BY SUM(i3.item_cantidad) DESC) as ProductoMasVendido,
	CAST(SUM(f.fact_total) * 100 / (SELECT SUM(f5.fact_total) FROM Factura f5) AS DECIMAL(10,2)) as PorcentajeVentaEmpleado
FROM Empleado e
LEFT JOIN Factura f ON f.fact_vendedor = e.empl_codigo
GROUP BY e.empl_codigo
ORDER BY COUNT(f.fact_tipo+f.fact_sucursal+f.fact_numero) DESC

-- Ejercicio 27

SELECT YEAR(f.fact_fecha) as Año, e.enva_codigo, e.enva_detalle,
	(SELECT COUNT(p2.prod_envase) FROM Producto p2
	WHERE p2.prod_envase = e.enva_codigo) as CantProductosEnvase,
	COUNT(f.fact_tipo+f.fact_sucursal+f.fact_numero) as CantProdFacturadosEnvase,
	(SELECT TOP 1 p3.prod_codigo
	FROM Producto p3
	JOIN Item_Factura i3 ON i3.item_producto = p3.prod_codigo
	JOIN Factura f3 ON f3.fact_tipo+f3.fact_sucursal+f3.fact_numero=i3.item_tipo+i3.item_sucursal+i3.item_numero
	WHERE p3.prod_envase = e.enva_codigo AND YEAR(f3.fact_fecha) = YEAR(f.fact_fecha)
	GROUP BY p3.prod_codigo
	ORDER BY SUM(i3.item_cantidad) DESC) as ProductoMasVendidoDelEnvase,
	SUM(i.item_cantidad * i.item_precio) as MontoTotalPorEnvase
FROM Factura f
JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero
JOIN Producto p ON p.prod_codigo = i.item_producto
JOIN Envases e ON e.enva_codigo = p.prod_envase
GROUP BY YEAR(f.fact_fecha), e.enva_codigo, e.enva_detalle
ORDER BY YEAR(f.fact_fecha), SUM(i.item_cantidad * i.item_precio) DESC

-- Ejercicio 28

SELECT YEAR(f.fact_fecha) as Año,
	f.fact_vendedor,
	e.empl_nombre,
	COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as CantFactVendedorAño,
	COUNT(DISTINCT f.fact_cliente) as CantClientes,
	(SELECT COUNT(DISTINCT c.comp_producto)
	FROM Factura f2
	JOIN Item_Factura i2 ON i2.item_tipo+i2.item_sucursal+i2.item_numero=f2.fact_tipo+f2.fact_sucursal+f2.fact_numero
	JOIN Composicion c ON c.comp_producto = i2.item_producto
	WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) AND f2.fact_vendedor = f.fact_vendedor) as CantProduCompFac,
	(SELECT COUNT(DISTINCT i3.item_producto)
	FROM Factura f3
	JOIN Item_Factura i3 ON i3.item_tipo+i3.item_sucursal+i3.item_numero=f3.fact_tipo+f3.fact_sucursal+f3.fact_numero
	WHERE i3.item_producto NOT IN (SELECT comp_producto FROM Composicion) AND YEAR(f3.fact_fecha) = YEAR(f.fact_fecha) AND f3.fact_vendedor = f.fact_vendedor) as CantProducSinComp,
	(SELECT SUM(f4.fact_total)
      FROM Factura f4
      WHERE YEAR(f4.fact_fecha) = YEAR(f.fact_fecha) AND f4.fact_vendedor = f.fact_vendedor) AS MontoTotal
FROM Factura f
JOIN Empleado e ON e.empl_codigo = f.fact_vendedor
JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero
GROUP BY YEAR(f.fact_fecha), f.fact_vendedor, e.empl_nombre
ORDER BY YEAR(f.fact_fecha), COUNT(DISTINCT i.item_producto) DESC

-- Ejercicio 29

SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) as CantVendida, COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as CantFacturas, SUM(i.item_cantidad * i.item_precio) as PrecioTotalFacturado
FROM Producto p
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
WHERE YEAR(f.fact_fecha) = '2011' AND p.prod_familia in (SELECT fa.fami_id
														 FROM Familia fa
														 JOIN Producto p2 ON p2.prod_familia = fa.fami_id
														 GROUP BY fami_id
														 HAVING COUNT(DISTINCT p2.prod_codigo) > 20)
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY SUM(i.item_cantidad) DESC

-- Ejercicio 30

SELECT j.empl_nombre,
	   COUNT(DISTINCT e.empl_codigo) as CantEmplACargo,
	   SUM(f.fact_total) as MontoTotalEmpl,
	   COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as CantFacEmpl,
	   (SELECT TOP 1 e2.empl_nombre
	   FROM Empleado e2
	   JOIN Factura f2 ON f2.fact_vendedor = e2.empl_codigo
	   WHERE e2.empl_jefe = j.empl_codigo AND YEAR(f2.fact_fecha) = '2012'
	   GROUP BY e2.empl_nombre
	   ORDER BY SUM(f2.fact_total) DESC) as EmpleadoMejoresVentas
FROM Empleado j
JOIN Empleado e ON e.empl_jefe = j.empl_codigo
JOIN Factura f ON f.fact_vendedor = e.empl_codigo
WHERE j.empl_codigo IN (SELECT j2.empl_jefe
						FROM Empleado j2)
	AND YEAR(f.fact_fecha) = '2012'
GROUP BY j.empl_nombre, j.empl_codigo
HAVING COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) > 10
ORDER BY SUM(f.fact_total) DESC

-- Ejercicio 31

SELECT YEAR(f.fact_fecha) as Año, e.empl_codigo, e.empl_nombre,
	COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as CantFact,
	COUNT(DISTINCT f.fact_cliente) as CantClientes,
	(SELECT COUNT(DISTINCT i.item_producto)
	FROM Item_Factura i
	JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
	WHERE i.item_producto IN (SELECT c.comp_producto FROM Composicion c)
		AND YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) AND f2.fact_vendedor = e.empl_codigo) as CantProdComposicion,
	(SELECT COUNT(DISTINCT i.item_producto)
	FROM Item_Factura i
	JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
	WHERE i.item_producto NOT IN (SELECT c.comp_producto FROM Composicion c)
		AND YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) AND f2.fact_vendedor = e.empl_codigo) as CantProdSinComposicion,
	SUM(f.fact_total) as MontoTotal
FROM Factura f
JOIN Empleado e ON e.empl_codigo = f.fact_vendedor
GROUP BY YEAR(f.fact_fecha), e.empl_codigo, e.empl_nombre
ORDER BY YEAR(f.fact_fecha), (SELECT COUNT(DISTINCT i.item_producto)
	FROM Item_Factura i
	JOIN Factura f2 ON f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=i.item_tipo+i.item_sucursal+i.item_numero
	WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha) AND f2.fact_vendedor = e.empl_codigo) DESC

-- Ejercico 32 (Esta mal el TotalVendido)

SELECT f1.fami_id, f1.fami_detalle, f2.fami_id, f2.fami_detalle,
	COUNT(DISTINCT i1.item_tipo+i1.item_sucursal+i1.item_numero) as CantFacturas,
	SUM(i1.item_cantidad * i1.item_precio) + SUM (i2.item_cantidad * i2.item_precio) as TotalVendido
FROM Familia f1
JOIN Producto p1 ON p1.prod_familia = f1.fami_id
JOIN Item_Factura i1 ON i1.item_producto = p1.prod_codigo
JOIN Item_Factura i2 ON i2.item_tipo+i2.item_sucursal+i2.item_numero = i1.item_tipo+i1.item_sucursal+i1.item_numero
JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
JOIN Familia f2 ON f2.fami_id = p2.prod_familia
WHERE f1.fami_id > f2.fami_id
GROUP BY f1.fami_id, f1.fami_detalle, f2.fami_id, f2.fami_detalle
HAVING COUNT(DISTINCT i1.item_tipo+i1.item_sucursal+i1.item_numero) > 10
ORDER BY SUM(i1.item_cantidad * i1.item_precio) + SUM (i2.item_cantidad * i2.item_precio)


-- Ejercicio 33

SELECT p.prod_codigo, p.prod_detalle,
	SUM(i.item_cantidad) as UnidadesVendidas,
	COUNT(DISTINCT i.item_tipo+i.item_sucursal+i.item_numero) as CantFacturas,
	AVG(i.item_precio) PrecioPromedioFacturado,
	SUM(i.item_cantidad * i.item_precio) as TotalFacturado
FROM Producto p
JOIN Item_Factura i ON i.item_producto = p.prod_codigo
JOIN Factura f ON f.fact_tipo+f.fact_sucursal+f.fact_numero = i.item_tipo+i.item_sucursal+i.item_numero
JOIN Composicion c ON c.comp_componente = p.prod_codigo
WHERE c.comp_producto IN (SELECT TOP 1 i1.item_producto
						 FROM Factura f1
						 JOIN Item_Factura i1 ON i1.item_tipo+i1.item_sucursal+i1.item_numero = f1.fact_tipo+f1.fact_sucursal+f1.fact_numero
						 WHERE i1.item_producto IN (SELECT c1.comp_producto FROM Composicion c1) AND YEAR(f1.fact_fecha) = '2012'
						 GROUP BY i1.item_producto
						 ORDER BY SUM(i1.item_cantidad) DESC)
	AND YEAR(f.fact_fecha) = '2012'
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY SUM(i.item_cantidad * i.item_precio) DESC

-- Ejercico 34

SELECT p.prod_rubro, MONTH(f.fact_fecha) as Mes, 
	ISNULL(COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero),0) as CantFactMalHechas
FROM Factura f
JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero
JOIN Producto p ON p.prod_codigo = i.item_producto
WHERE YEAR(f.fact_fecha) = '2011'
	AND f.fact_tipo+f.fact_sucursal+f.fact_numero IN (SELECT f2.fact_tipo+f2.fact_sucursal+f2.fact_numero
														FROM Factura f2
														JOIN Item_Factura i2 ON i2.item_tipo+i2.item_sucursal+i2.item_numero = f2.fact_tipo+f2.fact_sucursal+f2.fact_numero
														JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
														WHERE YEAR(f2.fact_fecha) = 2011
														GROUP BY f2.fact_tipo+f2.fact_sucursal+f2.fact_numero
														HAVING COUNT(DISTINCT p2.prod_rubro) > 1)
GROUP BY p.prod_rubro, MONTH(f.fact_fecha)

-- Ejercicio 35

SELECT YEAR(f.fact_fecha) as Año, p.prod_codigo, p.prod_detalle,
	COUNT(DISTINCT f.fact_tipo+f.fact_sucursal+f.fact_numero) as CantFacturas,
	COUNT(DISTINCT f.fact_vendedor) as CantVendedores,
	(SELECT (COUNT(DISTINCT c1.comp_componente))
	FROM Composicion c1
	WHERE c1.comp_producto = p.prod_codigo) as CantComponentesProd,
	SUM(i.item_cantidad*i.item_precio)*100/(SELECT SUM(f2.fact_total)
											FROM Factura f2
											WHERE YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)) as ProcentajeDeVenta
FROM Factura f
JOIN Item_Factura i ON i.item_tipo+i.item_sucursal+i.item_numero = f.fact_tipo+f.fact_sucursal+f.fact_numero
JOIN Producto p ON p.prod_codigo = i.item_producto
GROUP BY YEAR(f.fact_fecha), p.prod_codigo, p.prod_detalle
ORDER BY YEAR(f.fact_fecha), SUM(i.item_cantidad*i.item_precio) DESC