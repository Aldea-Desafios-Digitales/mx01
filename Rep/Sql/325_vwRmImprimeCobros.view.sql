IF (OBJECT_ID ('dbo.vwRmImprimeCobros', 'V') IS NULL)
   exec('create view dbo.vwRmImprimeCobros as SELECT 1 as t');
go

ALTER VIEW [dbo].[vwRmImprimeCobros] AS 
--Propósito. Representación impresa de cfdi cobros México. Habilitar codigoBarras si usa Crystal!
--20/11/17 jcf Creación
--
SELECT 
		cob.[soptype],cob.[docid],cob.[sopnumbe],
		cob.[regimenFiscal],cob.[rgfs_descripcion],cob.[codigoPostal],
		cob.[rfcReceptor] TXRGNNUMCUST, cob.custnmbr, cob.[nombreCliente] CUSTNAME, abs(cob.[total]) total, cob.[isocurrc],
		cob.[TipoDeComprobante],cob.[tdcmp_descripcion],
		cob.[usoCfdi],cob.[uscf_descripcion],
		cob.[folioFiscal],cob.[noCertificadoCSD],cob.[version],
		cob.[selloCFD],
		cob.[selloSAT],
		cob.[cadenaOriginalSAT],
		cob.[noCertificadoSAT],	
		cob.RfcPAC, cob.Leyenda,
		cob.TipoRelacion,
		cob.tprl_descripcion,
		cob.UUIDrelacionado,

		CASE
			WHEN cob.isocurrc = 'MXN' THEN UPPER(DBO.TII_INVOICE_AMOUNT_LETTERS(abs(cob.[total]), 'PESOS ')) + ' M.N.'
			WHEN cob.isocurrc = 'USD' THEN UPPER(DBO.TII_INVOICE_AMOUNT_LETTERS(abs(cob.[total]), 'DOLARES AMERICANOS '))
		ELSE
			UPPER(DBO.TII_INVOICE_AMOUNT_LETTERS(abs(cob.[total]), default)) 
		END  AS AMOUNT_LETTERS,
		cob.ClaveProdServ, cob.ClaveUnidad, cob.cantidad, cob.ITEMDESC, cob.ORUNTPRC, cob.XTNDPRCE,
		RIGHT('0' + CAST(DAY(cob.fechaHoraEmision) AS VARCHAR(2)),2) + '/' + RIGHT('0' + CAST(MONTH(cob.fechaHoraEmision) AS VARCHAR(2)),2) + '/' + CAST(YEAR(cob.fechaHoraEmision) AS CHAR(4)) + ' ' + RIGHT('0' + CAST(DATEPART(HOUR,cob.fechaHoraEmision) AS VARCHAR(2)),2) + ':' + RIGHT('0' + CAST(DATEPART(MINUTE,cob.fechaHoraEmision) AS VARCHAR(2)),2) + ':' + RIGHT('0' + CAST(DATEPART(SECOND,cob.fechaHoraEmision) AS VARCHAR(2)),2) AS fechaHoraEmision,
		RIGHT('0' + CAST(DAY(cob.FechaTimbrado) AS VARCHAR(2)),2) + '/' + RIGHT('0' + CAST(MONTH(cob.FechaTimbrado) AS VARCHAR(2)),2) + '/' + CAST(YEAR(cob.FechaTimbrado) AS CHAR(4)) + ' ' + RIGHT('0' + CAST(DATEPART(HOUR,cob.FechaTimbrado) AS VARCHAR(2)),2) + ':' + RIGHT('0' + CAST(DATEPART(MINUTE,cob.FechaTimbrado) AS VARCHAR(2)),2) + ':' + RIGHT('0' + CAST(DATEPART(SECOND,cob.FechaTimbrado) AS VARCHAR(2)),2) AS FechaTimbrado,
		RTRIM(cob.rutaYNomArchivo) AS rutaYNomArchivo,
		cob.[rutaYNomArchivoNet],
		cob.[rutaFileDrive],
		adi.docdate,
		adi.FormaDePagoP,
		isnull(frpg.descripcion, 'NA') frpg_P_descripcion,
		adi.MonedaP,
		adi.TipoCambioP,
		adi.Monto,
		adi.NumOperacion,
		case when adi.RfcEmisorCtaOrd like 'no existe tag%' then '' else adi.RfcEmisorCtaOrd end RfcEmisorCtaOrd,
		case when adi.NomBancoOrdExt like 'no existe tag%' then '' else adi.NomBancoOrdExt end NomBancoOrdExt,
		case when adi.CtaOrdenante like 'no existe tag%' then '' else adi.CtaOrdenante end CtaOrdenante,
		adi.RfcEmisorCtaBen,
		adi.CtaBeneficiario,
		rel.APTODCNM,
		rel.IdDocumento,
		rel.MonedaDR,
		rel.TipoCambioDR,
		rel.MetodoDePagoDR,
		isnull(mtdpg.descripcion, 'NA') mtdpg_DR_descripcion,
		rel.NumParcialidad,
		rel.ImpSaldoAnt,
		rel.ImpPagado,
		rel.ImpSaldoInsoluto,
		dbo.fCfdObtieneImagenC(cob.rutaFileDrive) codigoBarras
FROM dbo.vwCfdiCobrosAImprimir cob WITH (NOLOCK)
	outer apply dbo.fCfdiDocumentoDePagoRelacionado (cob.soptype, cob.sopnumbe) rel
	outer apply dbo.fCfdiDocumentoDePago (cob.soptype, cob.sopnumbe) adi
	outer apply dbo.fCfdiCatalogoGetDescripcion('MTDPG',rel.MetodoDePagoDR) mtdpg
	outer apply dbo.fCfdiCatalogoGetDescripcion('FRPG', adi.FormaDePagoP) frpg

GO
-------------------------------------------------------------------------
--select * from [vwRmImprimeCobros]
--sp_columns fCfdiDocumentoDePagoRelacionado 
