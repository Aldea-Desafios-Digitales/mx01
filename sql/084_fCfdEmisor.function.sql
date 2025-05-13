--use mtp1

IF OBJECT_ID ('dbo.fCfdEmisor') IS NOT NULL
   DROP FUNCTION dbo.fCfdEmisor
GO

create function dbo.fCfdEmisor()
returns table
as
--Propósito. Devuelve datos del emisor
--Requisitos. Los impuestos están configurados en el campo texto de la compañía. 
--			Debe indicar el parámetros IMPUESTOS=[idImpuesto1],[idImpuesto2],etc.
--Utilizado por. fCfdDatosAdicionales()
--24/04/12 jcf Creación cfdi
--02/07/12 jcf Agrega parámetro OTROS. 
--08/02/17 jcf Elimina estado de lugarExpedicion
--14/09/17 jcf Usa fCfdiParametros y agrega estado a lugarExpedicion
--19/12/17 jcf Agrega utc
--11/01/18 jcf Agrega comercioExterior
--19/12/18 jcf Agrega nombreLoc
--18/01/19 jcf Agrega ruta y nombre del logo
--01/04/19 jcf Agrega locatnnm
--
return
( 
select rtrim(replace(ci.TAXREGTN, 'RFC ', '')) rfc, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.locatnnm)), 10) locatnnm, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.ADRCNTCT)), 10) nombreLoc, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.ADRCNTCT)), 10) nombre, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(rtrim(ci.ADDRESS1)), 10) calle, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(rtrim(ci.ADDRESS2)), 10) colonia, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.CITY)), 10) ciudad, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.COUNTY)), 10) municipio, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.[STATE])), 10) estado,  
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.CMPCNTRY)), 10) pais, 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(ci.ZIPCODE)), 10) codigoPostal, 
	left(dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(
			rtrim(ci.ADDRESS1)+' '+rtrim(ci.ADDRESS2)+' '+RTRIM(ci.ZIPCODE)+' '+RTRIM(ci.COUNTY)+' '+RTRIM(ci.CITY)+' '+RTRIM(ci.[STATE])+' '+RTRIM(ci.CMPCNTRY)), 10), 250) LugarExpedicion,
	nt.param1 [version], 
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(ISNULL(nt.INET7, '')), 10) rutaXml,
	dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(ISNULL(nt.INET8, '')), 10) regimen,
	nt.param2 impuestos,
	nt.param3 otrosDatos,	--cfdi 3.2 deprecated
	nt.param4 incluyeAddendaDflt,
	nt.param5 utc,
	nt.param6 comercioExterior,
	'file:'+ replace(img.fileName, '\', '/')  rutaYNombreDelLogo
from DYNAMICS..SY01500 ci				--sy_company_mstr
outer apply (select top(1) im.fileName 
			from DYNAMICS..SY01501 im	--img
			where im.cmpanyid = ci.cmpanyid) img
cross apply dbo.fCfdiParametros('VERSION', 'IMPUESTOS', 'OTROS', 'ADDENDADFLT', 'UTC', 'CFDIEXPORTA', ci.LOCATNID) nt
where ci.INTERID = DB_NAME()
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdEmisor()'
ELSE PRINT 'Error en la creación de la función: fCfdEmisor()'
GO

------------------------------------------------------------------------------------
--select *
--from dbo.fCfdEmisor()

