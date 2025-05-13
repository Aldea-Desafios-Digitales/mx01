
IF (OBJECT_ID ('dbo.vwCfdiTrasladoParaReporte', 'V') IS NULL)
   exec('create view dbo.vwCfdiTrasladoParaReporte as SELECT 1 as t');
go

ALTER VIEW [dbo].[vwCfdiTrasladoParaReporte] AS 
--Propósito. Representación impresa de Traslado México. Habilitar codigoBarras si usa Crystal!
--19/12/17 jcf Creación para cfdi 3.3
--
SELECT ivc.estadoContabilizado, ivc.soptype, ivc.docid, ivc.doctype, ivc.docnumbr sopnumbe, ivc.fechaHora, ivc.rfcReceptor TXRGNNUMCUST, 
		dpim.isocurrc,
		dpim.TipoDeComprobante,
		dpim.tdcmp_descripcion,
		dpim.codigoPostal,
		dpim.regimenFiscal,
		dpim.rgfs_descripcion,
		dpim.usoCfdi,
		dpim.uscf_descripcion,
		row_number() over(partition by ivc.doctype, ivc.docnumbr order by det.lnseqnbr) orden,
		det.ITEMNMBR,
		det.ClaveProdServ,
		det.ITEMDESC,
		det.UOFMsat UOFM,
		det.UOFMsat_descripcion,
		0 ORUNTPRC,
		0 OXTNDPRC,
		det.Cantidad QUANTITY,
		dpim.UUIDrelacionado,
		ISNULL(srl.SERLTQTY, det.Cantidad) SERLTQTY,
		srl.SERLTNUM,
		srl.LOTATRB1,
		srl.LOTATRB2,
		srl.LOTATRB3,
		srl.LOTATRB4,
		srl.LOTATRB5,
		RIGHT('0' + CAST(DAY(dpim.fechaHoraEmision) AS VARCHAR(2)),2) + '/' + RIGHT('0' + CAST(MONTH(dpim.fechaHoraEmision) AS VARCHAR(2)),2) + '/' + CAST(YEAR(dpim.fechaHoraEmision) AS CHAR(4)) + ' ' + RIGHT('0' + CAST(DATEPART(HOUR,dpim.fechaHoraEmision) AS VARCHAR(2)),2) + ':' + RIGHT('0' + CAST(DATEPART(MINUTE,dpim.fechaHoraEmision) AS VARCHAR(2)),2) + ':' + RIGHT('0' + CAST(DATEPART(SECOND,dpim.fechaHoraEmision) AS VARCHAR(2)),2) AS fechaHoraEmision,
		dpim.rfcReceptor,
		dpim.nombreCliente,
		dpim.total,
		dpim.folioFiscal,
		dpim.noCertificadoCSD,
		dpim.version,
		dpim.selloCFD,
		dpim.selloSAT,
		dpim.cadenaOriginalSAT,
		dpim.noCertificadoSAT,
		dpim.RfcPAC,
		dpim.Leyenda,
		RIGHT('0' + CAST(DAY(dpim.FechaTimbrado) AS VARCHAR(2)),2) + '/' + RIGHT('0' + CAST(MONTH(dpim.FechaTimbrado) AS VARCHAR(2)),2) + '/' + CAST(YEAR(dpim.FechaTimbrado) AS CHAR(4)) + ' ' + RIGHT('0' + CAST(DATEPART(HOUR,dpim.FechaTimbrado) AS VARCHAR(2)),2) + ':' + RIGHT('0' + CAST(DATEPART(MINUTE,dpim.FechaTimbrado) AS VARCHAR(2)),2) + ':' + RIGHT('0' + CAST(DATEPART(SECOND,dpim.FechaTimbrado) AS VARCHAR(2)),2) AS FechaTimbrado,

		RTRIM(dpim.rutaYNomArchivo) AS rutaYNomArchivo,
		RTRIM(dpim.rutaYNomArchivoNet) AS rutaYNomArchivoNet
		--dbo.fCfdObtieneImagenC(dpim.rutaYNomArchivo) codigoBarras
FROM dbo.vwCfdiTrasladosInventario	IVC
outer apply dbo.fCfdiTrasladoConceptos(IVC.doctype, IVC.docnumbr) det
LEFT OUTER JOIN (
		-- DATOS DE LOTES/SERIES UTILIZADOS EN TRX DE VENTAS (TANTO EN LOTE COMO CONTABILIZADAS)
		SELECT A.ivdoctyp, A.docnumbr, A.lnseqnbr, A.serltnum, A.serltqty, A.itemnmbr,
				B.LOTATRB1,
				B.LOTATRB2,
				B.LOTATRB3,
				B.LOTATRB4,
				B.LOTATRB5
		FROM iv30400 A WITH (NOLOCK) 
			INNER JOIN IV00301 B WITH (NOLOCK) 
				ON A.ITEMNMBR = B.ITEMNMBR 
				AND A.SERLTNUM = B.LOTNUMBR
		) srl
		ON det.doctype = srl.ivdoctyp 
		AND det.docnumbr = srl.docnumbr 
		AND det.lnseqnbr = srl.lnseqnbr

LEFT OUTER JOIN dbo.vwCfdiTrasladosDatosParaImprimir dpim WITH (NOLOCK)
	ON IVC.SOPTYPE = dpim.soptype 
	AND IVC.docnumbr = dpim.sopnumbe

	
--INNER JOIN RM00102 AS SOPINVOICEINFO WITH (NOLOCK)
--	ON IVC.PRBTADCD = SOPINVOICEINFO.ADRSCODE AND IVC.CUSTNMBR = SOPINVOICEINFO.CUSTNMBR

--INNER JOIN RM00102 as SOPSHIPMENTINFO WITH (NOLOCK)
--	ON IVC.PRSTADCD = SOPSHIPMENTINFO.ADRSCODE AND IVC.CUSTNMBR = SOPSHIPMENTINFO.CUSTNMBR

--INNER JOIN RM00101 as RMCUSTOMER WITH (NOLOCK)
--	ON IVC.CUSTNMBR = RMCUSTOMER.CUSTNMBR

--left join sop10106 cm
--	on cm.sopnumbe = IVC.sopnumbe
--	and cm.soptype = IVC.soptype


GO


