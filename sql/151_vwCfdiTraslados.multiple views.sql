--FACTURA ELECTRONICA GP - MEXICO
--Proyectos:		Maclean
--Propósito:		Genera funciones y vistas de Traslados de inventario para cfdi 3.3 en GP - MEXICO
--Referencia:		
--		19/12/17 Versión CFDI 3.3 - cfdv33.pdf
--Utilizado por:	Aplicación C# de generación de factura electrónica México
--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiTrasladoConceptos') IS NOT NULL
   DROP FUNCTION dbo.fCfdiTrasladoConceptos
GO

create function dbo.fCfdiTrasladoConceptos(@p_doctype smallint, @p_docnumbr varchar(21))
returns table 
as
--Propósito. Obtiene las líneas transferencias de inventario
--20/11/17 jcf Creación cfdi 3.3
--
return(
		select Concepto.doctype, Concepto.docnumbr, Concepto.lnseqnbr, Concepto.ITEMNMBR, 
			Concepto.ITEMDESC, 
			case when pa.param3 = 'CATEGORIA' 
				then Concepto.uscatvls_6
				else pa.param3 
			end ClaveProdServ,
			--rtrim(Concepto.uscatvls_6) ClaveProdServ,
			dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(Concepto.ITEMNMBR))),10)  NoIdentificacion,
			Concepto.trxqty				Cantidad, 
			rtrim(um.UOFMLONGDESC)		UOFMsat, 
			udmfa.descripcion			UOFMsat_descripcion,
			dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(Concepto.ITEMDESC))), 10) Descripcion
		from dbo.vwIvTransaccionesTHDet Concepto
			outer apply dbo.fCfdUofMSAT(Concepto.UOMSCHDL, Concepto.uofm) um
			outer apply dbo.fCfdiCatalogoGetDescripcion('UDM', um.UOFMLONGDESC) udmfa
			outer apply dbo.fcfdiparametros('NA','NA','CLPRODORIGEN','NA','NA','NA','PREDETERMINADO') pa
		where Concepto.doctype = @p_doctype
		and Concepto.docnumbr = @p_docnumbr
)

go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiTrasladoConceptos()'
ELSE PRINT 'Error en la creación de: fCfdiTrasladoConceptos()'
GO

--------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiTrasladoConceptosXML') IS NOT NULL
   DROP FUNCTION dbo.fCfdiTrasladoConceptosXML
GO

create function dbo.fCfdiTrasladoConceptosXML(@p_doctype smallint, @p_docnumbr varchar(21))
returns xml 
as
--Propósito. Obtiene las líneas de un traslado en formato xml para CFDI
--19/12/17 jcf Creación cfdi 3.3
--
begin
	declare @cncp xml;
	WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
	select @cncp = (
		select 
			ClaveProdServ        '@ClaveProdServ',
			NoIdentificacion     '@NoIdentificacion',
			Cantidad             '@Cantidad', 
			UOFMsat              '@ClaveUnidad', 
			Descripcion          '@Descripcion', 
			cast(0.00 as numeric(19, 2))   '@ValorUnitario',
			cast(0.00 as numeric(19,2))	'@Importe'
		from dbo.fCfdiTrasladoConceptos(@p_doctype, @p_docnumbr) Concepto
		FOR XML path('cfdi:Concepto'), type, root('cfdi:Conceptos')
	)
	return @cncp
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiTrasladoConceptosXML()'
ELSE PRINT 'Error en la creación de: fCfdiTrasladoConceptosXML()'
GO


--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiGeneraDocumentoDeTrasladoXML') IS NOT NULL
   DROP FUNCTION dbo.fCfdiGeneraDocumentoDeTrasladoXML
GO

create function dbo.fCfdiGeneraDocumentoDeTrasladoXML (@p_doctype smallint, @p_docnumbr varchar(21))
returns xml 
as
--Propósito. Elabora un comprobante xml de traslado para factura electrónica cfdi
--Requisitos. 
--19/12/17 jcf Creación cfdi 3.3
--
begin
	declare @cfd xml;
	WITH XMLNAMESPACES
	(
				'http://www.w3.org/2001/XMLSchema-instance' as "xsi",
				'http://www.sat.gob.mx/cfd/3' as "cfdi"
	)
	select @cfd = 
	(
	select 
		'http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd'	'@xsi:schemaLocation',
		emi.[version]										'@Version',
		rtrim(tv.docid)										'@Serie',
		rtrim(tv.docnumbr)									'@Folio',
		--convert(datetime, 
			DATEADD(hour, convert(int, emi.utc), tv.fechaHora) '@Fecha',
		--	,126)											'@Fecha',
		''													'@Sello', 
		--'99'												'@FormaPago',
		''													'@NoCertificado', 
		''													'@Certificado', 
		cast(0.00 as numeric(19,2))							'@SubTotal',
		'MXN'												'@Moneda',
		cast(0.00  as numeric(19, 2))						'@Total',
		'T'													'@TipoDeComprobante',
		--													'@MetodoPago',
		emi.codigoPostal									'@LugarExpedicion',
        --tr.TipoRelacion										'cfdi:CfdiRelacionados/@TipoRelacion',
		--dbo.fCfdiRelacionadosXML(tv.soptype, tv.sopnumbe, tv.docid, tr.TipoRelacion) 'cfdi:CfdiRelacionados',
		emi.rfc												'cfdi:Emisor/@Rfc',
		emi.nombre											'cfdi:Emisor/@Nombre', 
		emi.regimen											'cfdi:Emisor/@RegimenFiscal',
		tv.rfcReceptor								        'cfdi:Receptor/@Rfc',
		--''									'cfdi:Receptor/@Nombre', 
		tv.usoCfdi											'cfdi:Receptor/@UsoCFDI',
		dbo.fCfdiTrasladoConceptosXML(tv.doctype, tv.docnumbr),
		''													'cfdi:Complemento'
	from  dbo.vwCfdiTrasladosInventario tv
		cross join dbo.fCfdEmisor() emi
	where tv.docnumbr =	@p_docnumbr		
	and tv.doctype = @p_doctype
	FOR XML path('cfdi:Comprobante'), type
	)
	return @cfd;
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiGeneraDocumentoDeTrasladoXML ()'
ELSE PRINT 'Error en la creación de la función: fCfdiGeneraDocumentoDeTrasladoXML ()'
GO
-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiTrasladosUserInterface', 'V') IS NULL)
   exec('create view dbo.vwCfdiTrasladosUserInterface as SELECT 1 as t');
go

alter view dbo.vwCfdiTrasladosUserInterface as
--Propósito. Transferencias de inventario
--			Si el documento no fue emitido, genera el comprobante xml en el campo comprobanteXml
--Usado por. App Factura digital (doodads)
--Requisitos. El estado "no emitido" indica que no se ha emitido el archivo xml pero que está listo para ser generado.
--			El estado "inconsistente" indica que existe un problema en el folio o certificado, por tanto no puede ser generado.
--			El estado "emitido" indica que el archivo xml ha sido generado y sellado por el PAC y está listo para ser impreso.
--19/12/17 jcf Creación cfdi 3.3 traslado
--
select tv.estadoContabilizado, tv.soptype, rtrim(tv.docid) docid, rtrim(tv.docnumbr) sopnumbe, tv.fechahora, 
	'' CUSTNMBR, '' nombreCliente, '' idImpuestoCliente, 
	--isnull(gr2.txrgnnum, '') CUSTNMBR, isnull(gr2.custname, '') nombreCliente, isnull(gr2.txrgnnum, '') idImpuestoCliente, 
	0.00 total, 0.00 montoActualOriginal, cast(0 as smallint) voidstts, 

	isnull(lf.estado, isnull(fv.estado, 'inconsistente')) estado,

	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'inconsistente' 
		then 'folio o certificado inconsistente'
		else ISNULL(lf.mensaje, tv.estadoContabilizado)
	end mensaje,
	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'no emitido' and tv.estadoContabilizado = 'contabilizado'
		then dbo.fCfdiGeneraDocumentoDeTrasladoXML (tv.doctype, tv.docnumbr) 
		else cast('' as xml) 
	end comprobanteXml,
	
	fv.ID_Certificado, fv.ruta_certificado, fv.ruta_clave, fv.contrasenia_clave, 
	isnull(pa.ruta_certificado, '_noexiste') ruta_certificadoPac, isnull(pa.ruta_clave, '_noexiste') ruta_clavePac, isnull(pa.contrasenia_clave, '') contrasenia_clavePac, 
	emi.rfc, emi.regimen, emi.rutaXml, emi.codigoPostal,
	isnull(lf.estadoActual, '000000') estadoActual, 
	
	isnull(lf.mensajeEA, tv.estadoContabilizado) mensajeEA,

	tv.moneda isocurrc,
	cast('' as xml) addenda
from dbo.vwCfdiTrasladosInventario tv
	cross join dbo.fCfdEmisor() emi
	outer apply dbo.fCfdCertificadoVigente(tv.fechahora) fv
	outer apply dbo.fCfdCertificadoPAC(tv.fechahora) pa
	left join cfdlogfacturaxml lf
		on lf.soptype = tv.soptype
		and lf.sopnumbe = tv.docnumbr
		and lf.estado = 'emitido'
go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiTrasladosUserInterface'
ELSE PRINT 'Error en la creación de la vista: vwCfdiTrasladosUserInterface'
GO

-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiTrasladosDatosParaImprimir', 'V') IS NULL)
   exec('create view dbo.vwCfdiTrasladosDatosParaImprimir as SELECT 1 as t');
go

alter view dbo.vwCfdiTrasladosDatosParaImprimir as
--Propósito. Lista los documentos cfdi que están listos para imprimirse: facturas y notas de crédito. 
--			Incluye los datos del cfdi.
--07/05/12 jcf Creación
--25/10/17 jcf Cambio estructural para cfdi 3.3
--
select tv.soptype, tv.docid, tv.sopnumbe, tv.fechahora fechaHoraEmision, 
	tv.regimen regimenFiscal, isnull(rgfs.descripcion, 'NA') rgfs_descripcion, tv.codigoPostal, 
	tv.idImpuestoCliente rfcReceptor, tv.nombreCliente, tv.total, tv.isocurrc, tv.mensajeEA, 
	'T'	TipoDeComprobante,
	'Traslado' tdcmp_descripcion,
	
	--Datos del xml sellado por el PAC:
	dx.SelloCFD, 
	dx.FechaTimbrado, 
	dx.UUID folioFiscal, 
	dx.NoCertificadoSAT, 
	dx.[Version], 
	dx.selloSAT, 
	dx.Sello, 
	dx.NoCertificadoCSD, 
	dx.UsoCfdi,							isnull(uscf.descripcion, 'NA') uscf_descripcion,
	dx.RfcPAC,
	dx.Leyenda,
	dx.UUIDrelacionado,
	dx.cadenaOriginalSAT,

	--tv.rutaxml								+ 'cbb\' + replace(tv.mensaje, 'Almacenado en '+tv.rutaxml, '')+'.jpg' rutaYNomArchivoNet,
	'file:'+replace(tv.rutaxml, '\', '/') + 'cbb/' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivo, 
	tv.rutaxml								+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivoNet,
	'file://c:\getty' + substring(tv.rutaxml, charindex('\', tv.rutaxml, 3), 250) 
											+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaFileDrive
from dbo.vwCfdiTrasladosUserInterface tv
	inner join dbo.vwCfdiDatosDelXml dx
		on dx.soptype = tv.SOPTYPE
		and dx.sopnumbe = tv.sopnumbe
		and dx.estado = 'emitido'
	outer apply dbo.fCfdiCatalogoGetDescripcion('RGFS', tv.regimen) rgfs
	outer apply dbo.fCfdiCatalogoGetDescripcion('USCF', dx.usoCfdi) uscf

go
IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiTrasladosDatosParaImprimir  '
ELSE PRINT 'Error en la creación de la vista: vwCfdiTrasladosDatosParaImprimir '
GO
-----------------------------------------------------------------------------------------

-- FIN DE SCRIPT ***********************************************

--test
--select 'cfdi.Add(new CfdiUUID() { Sopnumbe = "'+rtrim(sopnumbe)+'", Uuid="'+rtrim(folioFiscal)+'", Sello= "'+ rtrim(sello)+'"});',
--sopnumbe, folioFiscal, sello, *
--from vwCfdiTrasladosDatosParaImprimir
--where month(fechaHoraEmision) = 12
--order by 1
