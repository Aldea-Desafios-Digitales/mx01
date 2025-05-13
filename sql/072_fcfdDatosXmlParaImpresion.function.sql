IF OBJECT_ID ('dbo.fCfdiDatosXmlParaImpresion') IS NOT NULL
   drop function dbo.fCfdiDatosXmlParaImpresion
go

create function dbo.fCfdiDatosXmlParaImpresion(@archivoXml xml)
--Propósito. Obtiene los datos de la factura electrónica
--Usado por. vwCfdTransaccionesDeVenta
--Requisitos. CFDI
--25/10/17 jcf Creación cfdi 3.3
--25/01/18 jcf Agrega receptorRfc
--
returns table
return(
	WITH XMLNAMESPACES('http://www.sat.gob.mx/TimbreFiscalDigital' as "tfd", 
						'http://www.sat.gob.mx/cfd/3' as "cfdi")
	select 
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@Version)[1]', 'varchar(5)') [version],
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@UUID)[1]', 'varchar(50)') UUID,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@FechaTimbrado)[1]', 'varchar(20)') FechaTimbrado,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@RfcProvCertif)[1]', 'varchar(20)') RfcPAC,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@Leyenda)[1]', 'varchar(150)') Leyenda,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@SelloCFD)[1]', 'varchar(8000)') SelloCFD,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@NoCertificadoSAT)[1]', 'varchar(20)') NoCertificadoSAT,
	@archivoXml.value('(//tfd:TimbreFiscalDigital/@SelloSAT)[1]', 'varchar(8000)') SelloSAT,
	@archivoXml.value('(//@Sello)[1]', 'varchar(8000)') Sello,
	@archivoXml.value('(//@NoCertificado)[1]', 'varchar(20)') NoCertificado,
	@archivoXml.value('(//@FormaPago)[1]', 'varchar(50)') FormaPago,
	@archivoXml.value('(//@MetodoPago)[1]', 'varchar(21)') MetodoPago,
	@archivoXml.value('(//cfdi:Receptor/@Rfc)[1]', 'varchar(15)') receptorRfc,
	@archivoXml.value('(//cfdi:Receptor/@UsoCFDI)[1]', 'varchar(4)') UsoCFDI,
	@archivoXml.value('(//cfdi:CfdiRelacionados/@TipoRelacion)[1]', 'varchar(4)') TipoRelacion,
	@archivoXml.value('(//cfdi:CfdiRelacionado/@UUID)[1]', 'varchar(60)') UUIDrelacionado
	)
	go

IF (@@Error = 0) PRINT 'Creación exitosa de: [fCfdiDatosXmlParaImpresion]()'
ELSE PRINT 'Error en la creación de: [fCfdiDatosXmlParaImpresion]()'
GO

--------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiPagosDatosXmlParaImpresion') IS NOT NULL
   drop function dbo.fCfdiPagosDatosXmlParaImpresion
go

create function dbo.fCfdiPagosDatosXmlParaImpresion(@archivoXml xml)
--Propósito. Obtiene los datos del complemento de pago
--Usado por. vwCfdiCobrosAImprimir
--Requisitos. CFDI
--21/11/17 jcf Creación cfdi 3.3
--16/11/18 jcf Agrega FormaDePagoP
--
returns table
return(
	WITH XMLNAMESPACES('http://www.sat.gob.mx/Pagos' as "pago10")
	select 
	@archivoXml.value('(//pago10:Pago/@TipoCambioP)[1]', 'varchar(12)') TipoCambioP,
	@archivoXml.value('(//pago10:Pago/@NumOperacion)[1]', 'varchar(30)') NumOperacion,
	@archivoXml.value('(//pago10:Pago/@RfcEmisorCtaOrd)[1]', 'varchar(15)') RfcEmisorCtaOrd,
	@archivoXml.value('(//pago10:Pago/@NomBancoOrdExt)[1]', 'varchar(50)') NomBancoOrdExt,
	@archivoXml.value('(//pago10:Pago/@CtaOrdenante)[1]', 'varchar(50)') CtaOrdenante,
	@archivoXml.value('(//pago10:Pago/@RfcEmisorCtaBen)[1]', 'varchar(15)') RfcEmisorCtaBen,
	@archivoXml.value('(//pago10:Pago/@CtaBeneficiario)[1]', 'varchar(50)') CtaBeneficiario,
	@archivoXml.value('(//pago10:Pago/@FormaDePagoP)[1]', 'varchar(5)') FormaDePagoP
	)
	go

IF (@@Error = 0) PRINT 'Creación exitosa de: [fCfdiPagosDatosXmlParaImpresion]()'
ELSE PRINT 'Error en la creación de: [fCfdiPagosDatosXmlParaImpresion]()'
GO

--------------------------------------------------------------------------------------

--PRUEBAS--

--select lf.*, dx.*
--from vwSopTransaccionesVenta tv
--	cross join dbo.fCfdEmisor() emi
--	outer apply dbo.fCfdCertificadoVigente(tv.fechahora) fv
--	outer apply dbo.fCfdCertificadoPAC(tv.fechahora) pa
--	left join cfdlogfacturaxml lf
--		on lf.soptype = tv.SOPTYPE
--		and lf.sopnumbe = tv.sopnumbe
--		and lf.estado = 'emitido'
--	outer apply dbo.fCfdiDatosXmlParaImpresion(lf.archivoXML) dx
