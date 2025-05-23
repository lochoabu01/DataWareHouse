-- crear tablas DataLake

CREATE TABLE DataLake.dbo.dl_departamentos (
	COD_DPTO tinyint NULL,
	NOM_DPTO nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	LATITUD float NULL,
	LONGITUD float NULL,
	[Geo Departamento] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

CREATE TABLE DataLake.dbo.dl_municipios (
	COD_DPTO tinyint NULL,
	NOM_DPTO nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	COD_MPIO int NULL,
	NOM_MPIO nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	TIPO varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	LATITUD float NULL,
	LONGITUD float NULL,
	[Geo Municipio] varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
);

CREATE TABLE DataLake.dbo.dl_homicidios (
	FECHA_HECHO date NULL,
	COD_DEPTO tinyint NULL,
	DEPARTAMENTO varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	COD_MUNI int NULL,
	MUNICIPIO varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ZONA nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SEXO nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CANTIDAD tinyint NULL
);


--crear dimensiones DataWareHouse

CREATE TABLE DataWareHouse.dbo.dim_departamentos (
	CodDepto tinyint NOT NULL,
	NomDepto nvarchar(60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Latitud float NULL,
	Longitud float NULL,
	CONSTRAINT dim_departamentos_pk PRIMARY KEY (CodDepto)
);

CREATE TABLE DataWareHouse.dbo.dim_municipios (
	CodMpio int NOT NULL,
	NomMpio nvarchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	Latitud float NULL,
	Longitud float NULL,
	CodDepto tinyint NULL,
	CONSTRAINT dim_municipios_pk PRIMARY KEY (CodMpio),
	CONSTRAINT dim_municipios_dim_departamentos_FK FOREIGN KEY (CodDepto) REFERENCES DataWareHouse.dbo.dim_departamentos(CodDepto) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE DataWareHouse.dbo.dim_zonas (
	IdZona tinyint IDENTITY(1,1) NOT NULL,
	NomZona nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	CONSTRAINT dim_zonas_pk PRIMARY KEY (IdZona)
);

CREATE TABLE DataWareHouse.dbo.dim_sexos (
	IdSexo tinyint IDENTITY(1,1) NOT NULL,
	NomSexo nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT dim_sexos_pk PRIMARY KEY (IdSexo)
);

CREATE TABLE DataWareHouse.dbo.dim_fechas (
	Annio int NOT NULL,
	Mes tinyint NOT NULL,
	Dia tinyint NOT NULL,
	Semana tinyint NULL,
	Trimestre tinyint NULL,
	DiaSemana tinyint NULL,
	CONSTRAINT dim_fechas_pk PRIMARY KEY (Annio,Mes,Dia)
);

CREATE TABLE DataWareHouse.dbo.fac_homicidios (
	IdHomicidio int IDENTITY(1,1) NOT NULL,
	FechaHecho date NOT NULL,
	CodMpio int NOT NULL,
	IdZona tinyint NOT NULL,
	IdSexo tinyint NOT NULL,
	Cantidad tinyint NOT NULL,
	CONSTRAINT fac_homicidios_pk PRIMARY KEY (IdHomicidio),
	CONSTRAINT fac_homicidios_dim_fechas_FK FOREIGN KEY (FechaHecho) REFERENCES DataWareHouse.dbo.dim_fechas(FechaHecho),
	CONSTRAINT fac_homicidios_dim_municipios_FK FOREIGN KEY (CodMpio) REFERENCES DataWareHouse.dbo.dim_municipios(CodMpio),
	CONSTRAINT fac_homicidios_dim_sexos_FK FOREIGN KEY (IdSexo) REFERENCES DataWareHouse.dbo.dim_sexos(IdSexo),
	CONSTRAINT fac_homicidios_dim_zonas_FK FOREIGN KEY (IdZona) REFERENCES DataWareHouse.dbo.dim_zonas(IdZona)
);

--Sincronizar informacion del DataLake al DataWareHouse

insert into DataWareHouse.dbo.dim_departamentos (CodDepto,NomDepto,Latitud,Longitud)
select COD_DPTO ,NOM_DPTO ,Latitud,Longitud
from DataLake.dbo.dl_departamentos

insert into DataWareHouse.dbo.dim_municipios (CodMpio,NomMpio,Latitud,Longitud ,CodDepto)
select COD_MPIO ,NOM_MPIO ,LATITUD ,LONGITUD ,COD_DPTO 
from DataLake.dbo.dl_municipios

insert into DataWareHouse.dbo.dim_zonas (NomZona)
select distinct ZONA 
from DataLake.dbo.dl_homicidios

insert into DataWareHouse.dbo.dim_sexos (NomSexo)
select distinct SEXO 
from DataLake.dbo.dl_homicidios


insert into DataWareHouse.dbo.dim_departamentos (CodDepto,NomDepto,Latitud,Longitud)
select COD_DPTO ,NOM_DPTO ,Latitud,Longitud
from DataLake.dbo.dl_departamentos

insert into DataWareHouse.dbo.dim_municipios (CodMpio,NomMpio,Latitud,Longitud ,CodDepto)
select COD_MPIO ,NOM_MPIO ,LATITUD ,LONGITUD ,COD_DPTO 
from DataLake.dbo.dl_municipios

insert into DataWareHouse.dbo.dim_zonas (NomZona)
select distinct ZONA 
from DataLake.dbo.dl_homicidios

insert into DataWareHouse.dbo.dim_sexos (NomSexo)
select distinct SEXO 
from DataLake.dbo.dl_homicidios

--Toma el lunes como el dia 1
set datefirst 1

insert into DataWareHouse.dbo.dim_fechas (Annio,Mes,Dia,Semana,Trimestre,DiaSemana)
select distinct year(FECHA_HECHO), month(FECHA_HECHO),day(FECHA_HECHO),DATEPART(WEEK,FECHA_HECHO),DATEPART(quarter,FECHA_HECHO),DATEPART(weekday,FECHA_HECHO)
from DataLake.dbo.dl_homicidios
order by year(FECHA_HECHO), month(FECHA_HECHO),day(FECHA_HECHO),DATEPART(WEEK,FECHA_HECHO),DATEPART(quarter,FECHA_HECHO),DATEPART(weekday,FECHA_HECHO)

select count(*) from DataWareHouse.dbo.dim_departamentos
select count(*) from DataWareHouse.dbo.dim_municipios
select count(*) from DataWareHouse.dbo.dim_zonas
select count(*) from DataWareHouse.dbo.dim_sexos
select count(*) from DataWareHouse.dbo.dim_fechas