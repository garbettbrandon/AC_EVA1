DROP TABLE LINEASVENTAS CASCADE CONSTRAINTS;
DROP TABLE VENTAS CASCADE CONSTRAINTS;
DROP TABLE PRODUCTOS CASCADE CONSTRAINTS;
DROP TABLE CLIENTE CASCADE CONSTRAINTS; 

CREATE TABLE CLIENTE(
	IDCLIENTE NUMBER,
	NOMBRE VARCHAR(30),
	DIRECCION VARCHAR(30),
	POBLACION VARCHAR(30),
	CODPOSTAL NUMBER(5),
	PROVINCIA VARCHAR(20),
	NIF VARCHAR(9),
	TEL1 NUMBER(6),
	TEL2 NUMBER(6),
	TEL3 NUMBER(6),
	CONSTRAINT PK_C PRIMARY KEY (IDCLIENTE)
);
CREATE TABLE PRODUCTOS(
	IDPRODUCTO NUMBER,
	DESCRIPCION VARCHAR(50),
	PVP NUMBER(4),
	STOCKACTUAL NUMBER(6),
	CONSTRAINT PK_P PRIMARY KEY (IDPRODUCTO)
);

CREATE TABLE VENTAS (
	IDVENTA NUMBER,
	FECHAVENTA DATE,
	IDCLIENTE NUMBER(3),
	CONSTRAINT PK_V PRIMARY KEY (IDVENTA),
	CONSTRAINT FK_V FOREIGN KEY (IDCLIENTE) REFERENCES CLIENTE (IDCLIENTE)
);

CREATE TABLE LINEASVENTAS(
	IDVENTA NUMBER,
	NUMEROLINEA NUMBER(6),
	IDPRODUCTO NUMBER,
	CANTIDAD NUMBER(6),
	CONSTRAINT PK_LVENTAS PRIMARY KEY(IDVENTA,NUMEROLINEA),
	CONSTRAINT FK_LVV FOREIGN KEY(IDVENTA) REFERENCES VENTAS(IDVENTA),
	CONSTRAINT FK_LVP FOREIGN KEY(IDPRODUCTO) REFERENCES PRODUCTOS(IDPRODUCTO)
);

DROP TYPE TIP_LINEAS_VENTA;
DROP TYPE TIP_VENTA;
DROP TYPE TIP_LINEA_VENTA;
DROP TYPE TIP_PRODUCTO;
DROP TYPE TIP_CLIENTE;
DROP TYPE TIP_DIRECCION;
DROP TYPE TIP_TELEFONOS; 

CREATE OR REPLACE TYPE TIP_TELEFONOS IS VARRAY(3) OF VARCHAR(15);
/
CREATE OR REPLACE TYPE TIP_DIRECCION AS OBJECT(
	CALLE VARCHAR(50),
	POBLACION VARCHAR(50),
	CODPOS VARCHAR(20),
	PROVINCIA VARCHAR(40)
);
/
CREATE OR REPLACE TYPE TIP_CLIENTE AS OBJECT(
	IDCLIENTE NUMBER,
	NOMBRE VARCHAR(50),
	DIREC TIP_DIRECCION,
	NIF varchar2(9),
	TELEF TIP_TELEFONOS
);
/
CREATE OR REPLACE TYPE TIP_PRODUCTO AS OBJECT(
	IDPRODUCTO NUMBER,
	DESCRIPCION VARCHAR(80),
	PVP NUMBER,
	STOCKACTUAL NUMBER
);
/
CREATE OR REPLACE TYPE TIP_LINEA_VENTA AS OBJECT(
	NUMEROLINEA NUMBER,
	IDPRODUCTO REF TIP_PRODUCTO,
	CANTIDAD NUMBER
);
/

CREATE OR REPLACE TYPE TIP_LINEAS_VENTA AS TABLE OF TIP_LINEA_VENTA;
/

CREATE TYPE TIP_VENTA AS OBJECT (
	IDVENTA NUMBER,
	IDCLIENTE REF TIP_CLIENTE,
	FECHAVENTA DATE,
	--NO ES NESTED TABLE
	LINEAS TIP_LINEAS_VENTA,
	MEMBER FUNCTION TOTAL_VENTA RETURN NUMBER
);
/

create or replace type body TIP_VENTA as 
	member function TOTAL_VENTA return number is
		TOTAL number:=0;
		LINEA TIP_LINEA_VENTA;
		PRODUCT TIP_PRODUCTO;
	begin
		for i in 1..LINEAS.count loop
			LINEA := LINEAS (i);
			select deref(LINEA.IDPRODUCTO) into PRODUCT from dual;
			TOTAL:= TOTAL + LINEA.CANTIDAD * PRODUCT.PVP;
		end loop;
		return TOTAL;
	end;
end;
/

DROP TABLE TABLA_CLIENTES;
CREATE TABLE TABLA_CLIENTES OF TIP_CLIENTE(IDCLIENTE PRIMARY KEY);
DROP TABLE TABLA_PRODUCTOS;
CREATE TABLE TABLA_PRODUCTOS OF TIP_PRODUCTO (IDPRODUCTO PRIMARY KEY);
DROP TABLE TABLA_VENTAS;
CREATE TABLE TABLA_VENTAS OF TIP_VENTA (IDVENTA PRIMARY KEY)
nested table lineas store as TABLA_LINEAS;

-- 5. Inserta los datos

INSERT INTO TABLA_CLIENTES VALUES(1,'LUIS GARCIA', TIP_DIRECCION('CALLE LAS FLORES,23','GUADALAJARA',19003,'GUADALAJARA'),'34343434L',TIP_TELEFONOS(949876655,949876655));
INSERT INTO TABLA_CLIENTES VALUES(2,'ANA SERRANO', TIP_DIRECCION('CALLE GALIANA,6','GUADALAJARA',19004,'GUADALAJARA'),'76767667F',TIP_TELEFONOS(94980009));

insert into tabla_productos values(1, 'caja de cristal de murano',100,5);
insert into tabla_productos values(2, 'bicicleta city',120,15);
insert into tabla_productos values(3, '100 lapices de colores',20,5);
insert into tabla_productos values(4, 'ipad',600,5);
insert into tabla_productos values(5, 'ordenador portatil',400,10);							

INSERT INTO TABLA_VENTAS VALUES (
	1,
	(SELECT REF(C) FROM TABLA_CLIENTES C WHERE C.IDCLIENTE=1),
	SYSDATE,
	TIP_LINEAS_VENTA(
		TIP_LINEA_VENTA(
			1,
			(SELECT REF(P) FROM TABLA_PRODUCTOS P WHERE IDPRODUCTO = 1),
			1
		),
		TIP_LINEA_VENTA(
			2,
			(SELECT REF(P) FROM TABLA_PRODUCTOS P WHERE IDPRODUCTO=2),
			2)
	)
);

INSERT INTO TABLA_VENTAS VALUES (
	2,
	(SELECT REF(C) FROM TABLA_CLIENTES C WHERE C.IDCLIENTE=1),
	SYSDATE,
	TIP_LINEAS_VENTA(
		TIP_LINEA_VENTA(
			1,
			(SELECT REF(P) FROM TABLA_PRODUCTOS P WHERE IDPRODUCTO = 1),
			2
		),
		TIP_LINEA_VENTA(
			2,
			(SELECT REF(P) FROM TABLA_PRODUCTOS P WHERE IDPRODUCTO=2),
			1
		),
		TIP_LINEA_VENTA(
			3,
			(SELECT REF(P) FROM TABLA_PRODUCTOS P WHERE IDPRODUCTO=3),
			4
		)
	)
);