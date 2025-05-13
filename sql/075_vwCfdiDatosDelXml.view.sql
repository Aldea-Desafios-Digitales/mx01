IF (OBJECT_ID ('dbo.vwCfdiDatosDelXml', 'V') IS NULL)
   exec('create view dbo.vwCfdiDatosDelXml as SELECT 1 as t');
go

alter view dbo.vwCfdiDatosDelXml as
--Propósito. Lista los datos del xml emitido 
--21/11/17 jcf Creación cfdi 3.3
--25/01/18 jcf Agrega receptorRfc para conta electrónica
--
select lf.soptype, lf.sopnumbe, lf.secuencia, lf.estado, lf.mensaje, lf.estadoActual, lf.mensajeEA, 
	--Datos del xml sellado por el PAC:
	isnull(dx.SelloCFD, '') SelloCFD, 
	isnull(dx.FechaTimbrado, '') FechaTimbrado, 
	isnull(dx.UUID, '') UUID, 
	isnull(dx.NoCertificadoSAT, '') noCertificadoSAT, 
	isnull(dx.[Version], '') [version], 
	isnull(dx.selloSAT, '') selloSAT, 
	isnull(dx.FormaPago, '') FormaPago,
	isnull(dx.Sello, '') sello, 
	isnull(dx.NoCertificado, '') noCertificadoCSD, 
	isnull(dx.MetodoPago, '') MetodoPago,	
	isnull(dx.receptorRfc, '') receptorRfc,			
	isnull(dx.UsoCfdi, '') usoCfdi,			
	isnull(dx.RfcPAC, '') RfcPAC,
	isnull(dx.Leyenda, '') Leyenda,
	isnull(dx.TipoRelacion, '') TipoRelacion,
	isnull(dx.UUIDrelacionado, '') UUIDrelacionado,

	'||'+dx.[version]+'|'+dx.UUID+'|'+dx.FechaTimbrado+'|'+dx.RfcPAC + 
	case when isnull(dx.Leyenda, '') = '' then '' else '|'+dx.Leyenda end
	+'|'+dx.selloCFD+'|'+dx.noCertificadoSAT+'||' cadenaOriginalSAT

from cfdlogfacturaxml lf
	outer apply dbo.fCfdiDatosXmlParaImpresion(lf.archivoXML) dx

go
IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiDatosDelXml  '
ELSE PRINT 'Error en la creación de la vista: vwCfdiDatosDelXml '
GO
-----------------------------------------------------------------------------------------

IF (OBJECT_ID ('dbo.vwCfdiPagosDatosDelXml', 'V') IS NULL)
   exec('create view dbo.vwCfdiPagosDatosDelXml as SELECT 1 as t');
go

alter view dbo.vwCfdiPagosDatosDelXml as
--Propósito. Lista los datos del xml emitido 
--21/11/17 jcf Creación cfdi 3.3
--16/11/18 jcf Agrega FormaDePagoP
--
select lf.soptype, lf.sopnumbe, lf.secuencia, lf.estado, lf.mensaje, lf.estadoActual, lf.mensajeEA, 
	--Datos del xml sellado por el PAC:
	isnull(px.TipoCambioP, '') TipoCambioP,
	isnull(px.NumOperacion, '') NumOperacion,
	isnull(px.RfcEmisorCtaOrd, '') RfcEmisorCtaOrd,
	isnull(px.NomBancoOrdExt, '') NomBancoOrdExt,
	isnull(px.CtaOrdenante, '') CtaOrdenante,
	isnull(px.RfcEmisorCtaBen, '') RfcEmisorCtaBen,
	isnull(px.CtaBeneficiario, '') CtaBeneficiario,
	isnull(px.FormaDePagoP, '') FormaDePagoP

from cfdlogfacturaxml lf
	outer apply dbo.fCfdiPagosDatosXmlParaImpresion (lf.archivoXML) px

go
IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiPagosDatosDelXml  '
ELSE PRINT 'Error en la creación de la vista: vwCfdiPagosDatosDelXml '
GO
-----------------------------------------------------------------------------------------
