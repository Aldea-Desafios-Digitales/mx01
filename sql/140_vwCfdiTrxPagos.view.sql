
IF (OBJECT_ID ('dbo.vwCfdiTrxCobros', 'V') IS NULL)
   exec('create view dbo.vwCfdiTrxCobros as SELECT 1 as t');
go

alter view dbo.vwCfdiTrxCobros as
--Propósito. Todos los cobros 
--			Incluye la cadena original para el cfdi.
--			Si el documento no fue emitido, genera el comprobante xml en el campo comprobanteXml
--Usado por. App Factura digital (doodads)
--Requisitos. El estado "no emitido" indica que no se ha emitido el archivo xml pero que está listo para ser generado.
--			El estado "inconsistente" indica que existe un problema en el folio o certificado, por tanto no puede ser generado.
--			El estado "emitido" indica que el archivo xml ha sido generado y sellado por el PAC y está listo para ser impreso.
--30/10/17 jcf Creación cfdi 3.3
--24/01/18 jcf usa montoActualOriginal para validar que esté totalmente aplicado
--
select case when cb.rmTipoTrx in ('A', 'H') then 'contabilizado' else 'en lote' end estadoContabilizado, 
	cb.rmdtypal soptype, 'CBR' docid, cb.docnumbr sopnumbe, convert(datetime, cb.docdate, 126) fechahora,
 
	cb.CUSTNMBR, custname nombreCliente, cb.txrgnnum idImpuestoCliente, cast(cb.ororgtrx as numeric(18,2)) total, cb.montoActualOriginal, cb.voidstts, 

	isnull(lf.estado, isnull(fv.estado, 'inconsistente')) estado,
	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'inconsistente' 
		then 'folio o certificado inconsistente'
		else ISNULL(lf.mensaje, 'contabilizado')
	end mensaje,

	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'no emitido' 
		then [dbo].[fCfdiDocumentoDePagoXML] (cb.RMDTYPAL, cb.DOCNUMBR)
		else cast('' as xml) 
	end comprobanteXml,
	
	fv.ID_Certificado, fv.ruta_certificado, fv.ruta_clave, fv.contrasenia_clave, 
	isnull(pa.ruta_certificado, '_noexiste') ruta_certificadoPac, isnull(pa.ruta_clave, '_noexiste') ruta_clavePac, isnull(pa.contrasenia_clave, '') contrasenia_clavePac, 
	emi.rfc, emi.regimen, emi.rutaXml, emi.codigoPostal,
	isnull(lf.estadoActual, '000000') estadoActual, 
	isnull(lf.mensajeEA, 
			case when cb.montoActualOriginal != 0 then 'parcialmente aplicado'
			else 'contabilizado'
			end
			) mensajeEA,
	rtrim(mo.isocurrc) isocurrc,
	null addenda
from dbo.vwRmTransaccionesTodas cb
	cross join dbo.fCfdEmisor() emi
	outer apply dbo.fCfdCertificadoVigente(cb.docdate) fv
	outer apply dbo.fCfdCertificadoPAC(cb.docdate) pa
	left join cfdlogfacturaxml lf
		on lf.soptype = cb.rmdtypal
		and lf.sopnumbe = cb.docnumbr
		and lf.estado = 'emitido'
	left outer join dynamics..mc40200 mo
		on mo.CURNCYID = cb.curncyid
--	outer apply dbo.fCfdiDatosXmlParaImpresion(lf.archivoXML) dx
where cb.rmdtypal = 9

go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiTrxCobros'
ELSE PRINT 'Error en la creación de la vista: vwCfdiTrxCobros'
GO
----------------------------------------------------------------------------------------------------

IF (OBJECT_ID ('dbo.vwCfdiCobrosAImprimir', 'V') IS NULL)
   exec('create view dbo.vwCfdiCobrosAImprimir as SELECT 1 as t');
go

alter view dbo.vwCfdiCobrosAImprimir as
--Propósito. Lista los cobros que están listos para imprimir
--			Incluye los datos del cfdi.
--20/11/17 jcf Creación cfdi 3.3
--16/11/18 jcf Agrega FormaDePagoP
--
select tv.soptype, tv.docid, tv.sopnumbe, tv.fechahora fechaHoraEmision, 
	tv.regimen regimenFiscal, isnull(rgfs.descripcion, 'NA') rgfs_descripcion, tv.codigoPostal, 
	tv.idImpuestoCliente rfcReceptor, tv.custnmbr, tv.nombreCliente, tv.total, tv.isocurrc,
	'P'	TipoDeComprobante,
	'Pago' tdcmp_descripcion,
	--tv.formaDePago, isnull(frpg.descripcion, 'NA') frpg_descripcion,
	--tv.metodoDePago, isnull(mtdpg.descripcion, 'NA') mtdpg_descripcion,
	pa.param1 ClaveProdServ, pa.param2 ClaveUnidad, 1 cantidad, 'Pago' ITEMDESC, 0 ORUNTPRC, 0 XTNDPRCE,

	--Datos del xml sellado por el PAC:
	dx.SelloCFD, 
	dx.FechaTimbrado, 
	dx.UUID folioFiscal, 
	dx.NoCertificadoSAT, 
	dx.[Version], 
	dx.selloSAT, 
	dx.FormaPago formaDePago,			
	dx.Sello, 
	dx.NoCertificadoCSD, 
	dx.MetodoPago metodoDePago,			
	dx.UsoCfdi,							isnull(uscf.descripcion, 'NA') uscf_descripcion,
	dx.RfcPAC,
	dx.Leyenda,
	dx.TipoRelacion,					isnull(tprl.descripcion, 'NA') tprl_descripcion,
	dx.UUIDrelacionado,
	dx.cadenaOriginalSAT,

	px.TipoCambioP,
	px.NumOperacion,
	px.RfcEmisorCtaOrd,
	px.NomBancoOrdExt,
	px.CtaOrdenante,
	px.RfcEmisorCtaBen,
	px.CtaBeneficiario,
	px.FormaDePagoP,
	--tv.rutaxml								+ 'cbb\' + replace(tv.mensaje, 'Almacenado en '+tv.rutaxml, '')+'.jpg' rutaYNomArchivoNet,
	'file://'+replace(tv.rutaxml, '\', '/') + 'cbb/' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivo, 
	tv.rutaxml								+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivoNet,
	'file://c:\getty' + substring(tv.rutaxml, charindex('\', tv.rutaxml, 3), 250) 
											+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaFileDrive
from dbo.vwCfdiTrxCobros tv
	inner join dbo.vwCfdiDatosDelXml dx
		on dx.soptype = tv.SOPTYPE
		and dx.sopnumbe = tv.sopnumbe
		and dx.estado = 'emitido'
	left join dbo.vwCfdiPagosDatosDelXml px
		on px.soptype = tv.SOPTYPE
		and px.sopnumbe = tv.sopnumbe
		and px.estado = 'emitido'
	outer apply dbo.fcfdiparametros('CLPRODSERV','CLUNIDAD','NA','NA','NA','NA','PREDETERMINADO') pa
	outer apply dbo.fCfdiCatalogoGetDescripcion('RGFS', tv.regimen) rgfs
	outer apply dbo.fCfdiCatalogoGetDescripcion('USCF', dx.usoCfdi) uscf
	outer apply dbo.fCfdiCatalogoGetDescripcion('TPRL', dx.TipoRelacion) tprl

go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiCobrosAImprimir  '
ELSE PRINT 'Error en la creación de la vista: vwCfdiCobrosAImprimir '
GO
-----------------------------------------------------------------------------------------

-- FIN DE SCRIPT ***********************************************
