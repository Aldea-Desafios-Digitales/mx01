-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiTransaccionesDeVenta', 'V') IS NULL)
   exec('create view dbo.vwCfdiTransaccionesDeVenta as SELECT 1 as t');
go

alter view dbo.vwCfdiTransaccionesDeVenta as
--Propósito. Todos los documentos de venta: facturas y notas de crédito. 
--			Incluye la cadena original para el cfdi.
--			Si el documento no fue emitido, genera el comprobante xml en el campo comprobanteXml
--Usado por. App Factura digital (doodads)
--Requisitos. El estado "no emitido" indica que no se ha emitido el archivo xml pero que está listo para ser generado.
--			El estado "inconsistente" indica que existe un problema en el folio o certificado, por tanto no puede ser generado.
--			El estado "emitido" indica que el archivo xml ha sido generado y sellado por el PAC y está listo para ser impreso.
--24/04/12 jcf Creación cfdi
--23/05/12 jcf Agrega datos del certificado del PAC
--10/07/12 jcf Agrega metodoDePago, NumCtaPago
--07/11/12 jcf Agrega parámetro a fCfdAddendaXML
--24/02/14 jcf Agrega parámetro a fCfdAddendaXML para cliente Mabe
--14/09/17 jcf Agrega parámetros incluyeAddendaDflt para addenda predeterminada para todos los clientes. Utilizado en MTP
--				Agrega isocurrc
--30/11/17 jcf Reestructura para cfdi 3.3
--12/12/17 jcf Agrega mensaje en docs anulados
--16/01/18 jcf Agrega fCfdiGeneraDocumentoVentaComercioExteriorXML
--16/02/18 jcf Permite mostrar las facturas incluso si no está configurada la compañía como Emisor
--15/05/20 jcf Agrega mensaje cuando el csd está próximo a caducar
--
select tv.estadoContabilizado, tv.soptype, tv.docid, tv.sopnumbe, tv.fechahora, 
	tv.CUSTNMBR, tv.nombreCliente, tv.idImpuestoCliente, cast(tv.total as numeric(19,2)) total, tv.montoActualOriginal, tv.voidstts, 

	isnull(lf.estado, isnull(fv.estado, 'inconsistente')) estado,
	case when isnull(lf.estado, isnull(fv.estado, 'csd err')) = 'csd err' 
			then 'El CSD ha caducado o no existe para esta factura'
		when isnull(lf.estado, fv.estado) = 'inconsistente'
			then 'Hay más de un CSD configurado para la misma fecha'
		else ISNULL(lf.mensaje, fv.msjCaducaEn + tv.estadoContabilizado)
	end mensaje,
	case when isnull(lf.estado, isnull(fv.estado, 'inconsistente')) = 'no emitido' 
		then 
			case when emi.comercioExterior = tv.docid 
				then dbo.fCfdiGeneraDocumentoVentaComercioExteriorXML(tv.soptype, tv.sopnumbe) 
				else dbo.fCfdiGeneraDocumentoDeVentaXML (tv.soptype, tv.sopnumbe) 
			end
		else cast('' as xml) 
	end comprobanteXml,
	
	fv.ID_Certificado, fv.ruta_certificado, fv.ruta_clave, fv.contrasenia_clave, 
	isnull(pa.ruta_certificado, '_noexiste') ruta_certificadoPac, isnull(pa.ruta_clave, '_noexiste') ruta_clavePac, isnull(pa.contrasenia_clave, '') contrasenia_clavePac, 
	emi.rfc, emi.regimen, emi.rutaXml, emi.codigoPostal,
	isnull(lf.estadoActual, '000000') estadoActual, 
	
	isnull(lf.mensajeEA, tv.estadoContabilizado) +
	case when tv.voidstts = 0 then '' else ' ANULADO.' end mensajeEA,

	tv.curncyid isocurrc,
	dbo.fCfdAddendaXML(tv.custnmbr,  tv.soptype, tv.sopnumbe, tv.docid, tv.cstponbr, tv.curncyid, tv.docdate, tv.xchgrate, tv.subtotal, tv.total, emi.incluyeAddendaDflt) addenda
from dbo.vwCfdiSopTransaccionesVenta tv
	outer apply dbo.fCfdEmisor() emi
	outer apply dbo.fCfdCertificadoVigente(tv.fechahora) fv
	outer apply dbo.fCfdCertificadoPAC(tv.fechahora) pa
	left join cfdlogfacturaxml lf
		on lf.soptype = tv.SOPTYPE
		and lf.sopnumbe = tv.sopnumbe
		and lf.estado = 'emitido'
--	outer apply dbo.fCfdiDatosXmlParaImpresion(lf.archivoXML) dx
go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiTransaccionesDeVenta'
ELSE PRINT 'Error en la creación de la vista: vwCfdiTransaccionesDeVenta'
GO

-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiDocumentosAImprimir', 'V') IS NULL)
   exec('create view dbo.vwCfdiDocumentosAImprimir as SELECT 1 as t');
go

alter view dbo.vwCfdiDocumentosAImprimir as
--Propósito. Lista los documentos cfdi que están listos para imprimirse: facturas y notas de crédito. 
--			Incluye los datos del cfdi.
--07/05/12 jcf Creación
--25/10/17 jcf Cambio estructural para cfdi 3.3
--
select tv.soptype, tv.docid, tv.sopnumbe, tv.fechahora fechaHoraEmision, 
	tv.regimen regimenFiscal, isnull(rgfs.descripcion, 'NA') rgfs_descripcion, tv.codigoPostal, 
	tv.idImpuestoCliente rfcReceptor, tv.nombreCliente, tv.total, tv.isocurrc, tv.mensajeEA, 
	case when tv.SOPTYPE = 3 then 'I' 	else 'E' 	end	TipoDeComprobante,
	case when tv.SOPTYPE = 3 then 'Ingreso'	else 'Egreso' end tdcmp_descripcion,
	
	--Datos del xml sellado por el PAC:
	dx.SelloCFD, 
	dx.FechaTimbrado, 
	dx.UUID folioFiscal, 
	dx.NoCertificadoSAT, 
	dx.[Version], 
	dx.selloSAT, 
	dx.FormaPago formaDePago,			isnull(frpg.descripcion, 'NA') frpg_descripcion,
	dx.Sello, 
	dx.NoCertificadoCSD, 
	dx.MetodoPago metodoDePago,			isnull(mtdpg.descripcion, 'NA') mtdpg_descripcion,
	dx.UsoCfdi,							isnull(uscf.descripcion, 'NA') uscf_descripcion,
	dx.RfcPAC,
	dx.Leyenda,
	dx.TipoRelacion,					isnull(tprl.descripcion, 'NA') tprl_descripcion,
	dx.UUIDrelacionado,
	dx.cadenaOriginalSAT,

	--tv.rutaxml								+ 'cbb\' + replace(tv.mensaje, 'Almacenado en '+tv.rutaxml, '')+'.jpg' rutaYNomArchivoNet,
	'file:'+replace(tv.rutaxml, '\', '/') + 'cbb/' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivo, 
	tv.rutaxml								+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaYNomArchivoNet,
	'file://c:\getty' + substring(tv.rutaxml, charindex('\', tv.rutaxml, 3), 250) 
											+ 'cbb\' + RIGHT( tv.mensaje, CHARINDEX( '\', REVERSE( tv.mensaje ) + '\' ) - 1 ) +'.jpg' rutaFileDrive
from dbo.vwCfdiTransaccionesDeVenta tv
	inner join dbo.vwCfdiDatosDelXml dx
		on dx.soptype = tv.SOPTYPE
		and dx.sopnumbe = tv.sopnumbe
		and dx.estado = 'emitido'
	outer apply dbo.fCfdiCatalogoGetDescripcion('MTDPG', dx.MetodoPago) mtdpg
	outer apply dbo.fCfdiCatalogoGetDescripcion('FRPG', dx.FormaPago) frpg
	outer apply dbo.fCfdiCatalogoGetDescripcion('RGFS', tv.regimen) rgfs
	outer apply dbo.fCfdiCatalogoGetDescripcion('USCF', dx.usoCfdi) uscf
	outer apply dbo.fCfdiCatalogoGetDescripcion('TPRL', dx.TipoRelacion) tprl

go
IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiDocumentosAImprimir  '
ELSE PRINT 'Error en la creación de la vista: vwCfdiDocumentosAImprimir '
GO
-----------------------------------------------------------------------------------------

-- FIN DE SCRIPT ***********************************************

--test
--select 'cfdi.Add(new CfdiUUID() { Sopnumbe = "'+rtrim(sopnumbe)+'", Uuid="'+rtrim(folioFiscal)+'", Sello= "'+ rtrim(sello)+'"});',
--sopnumbe, folioFiscal, sello, *
--from vwCfdiDocumentosAImprimir
--where month(fechaHoraEmision) = 12
--order by 1
