IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[tii_vwRmTrxAplicadasExtendidas]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.tii_vwRmTrxAplicadasExtendidas;
GO
create view tii_vwRmTrxAplicadasExtendidas
--Propósito. Documentos aplicados de Receivables Management abiertos e históricos, con datos adicionales del pago
--Utilizado por: Smartlist
--28/8/08 JCF Creación
--25/11/09 jcf Añade tasa al último día del mes pasado en referencia a la fecha del pago. Sirve para obtener reversión a revaluación clientes.
--04/04/17 jcf Agrega postdate_apfr, postdate_apto. Corrige join.
--24/10/17 jcf Agrega cshrctyp, cashamnt, ortrxamt
--
as
select --aplicados de - a
       ap.rmTipoTrx, ap.APFRDCTY, ap.APFRDCNM, ap.APFRDCDT, ap.APTODCTY, ap.APTODCNM, ap.CUSTNMBR, ap.APTODCDT, 
       ap.CPRCSTNM, ap.TRXSORCE, ap.GLPOSTDT, ap.POSTED, ap.TAXDTLID, ap.APPLYTOGLPOSTDATE, ap.CURNCYID, 
       ap.APPTOAMT, ap.ORAPTOAM, ap.APTOEXRATE, ap.APPLYFROMGLPOSTDATE, ap.FROMCURR, ap.APFRMAPLYAMT, ap.ACTUALAPPLYTOAMOUNT,
       --datos adicionales del pago
       rm.bachnumb, rm.tipodoc tipodoc_apfr, rm.custname, rm.rmtipotrx rmtipotrx_apfr, rm.ortrxamt ortrxamt_apfr, rm.postdate postdate_apfr, rm.cshrctyp, 
       --datos adicionales de la factura, cargo...
       rmat.tipodoc tipodoc_apto, ROUND(isnull(rmat.orctrxam, rmat.curtrxam), 2) orctrxam_apto, rmat.postdate postdate_apto, rmat.ortrxamt ortrxamt_apto, rmat.cashamnt cashamnt_apto,
		DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,ap.APFRDCDT) ,0)) fechaUltimaReval,
		isnull(C.XCHGRATE, 0) tcUltimaReval, ROUND(ap.oraptoam * (aptoexrate - isnull(C.XCHGRATE, 0)), 2) revalDeFacturaPagada
  from vwRmTransaccionesTodas rm --[CUSTNMBR, DOCNUMBR, RMDTYPAL]
    INNER JOIN vwRmTrxAplicadas ap       --[APTODCNM, APTODCTY, APFRDCNM, APFRDCTY]
       ON --rm.CUSTNMBR = ap.CUSTNMBR
        rm.docnumbr = ap.APFRDCNM
       and rm.rmdtypal = ap.APFRDCTY
    INNER JOIN vwRmTransaccionesTodas rmat --[CUSTNMBR, DOCNUMBR, RMDTYPAL]
       ON --rmat.CUSTNMBR = ap.CUSTNMBR
        rmat.docnumbr = ap.APTODCNM
       and rmat.rmdtypal = ap.APTODCTY
	LEFT JOIN DYNAMICS..MC00100 C		--tasa al último día del mes pasado en referencia a la fecha del pago
		ON	C.EXGTBLID = 'USD_COMPRA'
		AND datediff(dd, DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,ap.APFRDCDT) ,0)), C.EXCHDATE) = 0
GO

IF (@@Error = 0) PRINT 'Creación exitosa de: tii_vwRmTrxAplicadasExtendidas'
ELSE PRINT 'Error en la creación de: tii_vwRmTrxAplicadasExtendidas'
GO

grant select on tii_vwRmTrxAplicadasExtendidas to DYNGRP
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------
