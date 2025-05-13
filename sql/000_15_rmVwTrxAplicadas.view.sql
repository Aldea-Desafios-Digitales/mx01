IF (OBJECT_ID ('dbo.vwRmTrxAplicadas', 'V') IS NULL)
   exec('create view dbo.vwRmTrxAplicadas as SELECT 1 as t');
go

--IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwRmTrxAplicadas]') AND OBJECTPROPERTY(id,N'IsView') = 1)
--    DROP view dbo.[vwRmTrxAplicadas];
--GO

alter view dbo.vwRmTrxAplicadas 
--Propósito. Documentos aplicados de Receivables Management abiertos e históricos
--Usado por. vwSopTrxAplicadasExtendidas
--5/5/08 JCF Creación
--28/8/08 JCF Adición de campos
--20/10/11 jcf Agrega idPago para usar en el acumulado de vwSopTrxAplicadasExtendidas
--08/03/12 jcf Corrige aplicaciones históricas. Sólo es histórico cuando la factura Y el pago son históricos. 
--				Agrega monto por diferencias de cambio (rlganlos) y condonación (apfrmwrofamt)
--
as
--
select 'A' rmTipoTrx, APFRDCTY, APFRDCNM, APFRDCDT, APTODCTY, APTODCNM, CUSTNMBR, APTODCDT, CPRCSTNM, TRXSORCE, GLPOSTDT, POSTED, TAXDTLID, 
	APPLYTOGLPOSTDATE, CURNCYID, APPTOAMT, ORAPTOAM, APTOEXRATE, APPLYFROMGLPOSTDATE, FROMCURR, APFRMAPLYAMT, ACTUALAPPLYTOAMOUNT, 
	RLGANLOS, APFRMWROFAMT, ActualWriteOffAmount, convert(varchar(12), APFRDCDT, 112) + rtrim(APFRDCNM) idPago
from rm20201			--rm_applied_open [APTODCNM, APTODCTY, APFRDCNM, APFRDCTY]
union all
select 'H' rmTipoTrx, ah.APFRDCTY, ah.APFRDCNM, ah.APFRDCDT, ah.APTODCTY, ah.APTODCNM, ah.CUSTNMBR, ah.APTODCDT, ah.CPRCSTNM, ah.TRXSORCE, ah.GLPOSTDT, ah.POSTED, 
	ah.TAXDTLID, ah.APPLYTOGLPOSTDATE, ah.CURNCYID, ah.APPTOAMT, ah.ORAPTOAM, ah.APTOEXRATE, ah.APPLYFROMGLPOSTDATE, ah.FROMCURR, ah.APFRMAPLYAMT, ah.ACTUALAPPLYTOAMOUNT, 
	ah.RLGANLOS, ah.APFRMWROFAMT, ActualWriteOffAmount, convert(varchar(12), ah.APFRDCDT, 112) + rtrim(ah.APFRDCNM) idPago
from rm30201 ah			--rm_Applied_history [APTODCNM, APTODCTY, APFRDCNM, APFRDCTY]
inner join rm30101 pg	--rm_history [CUSTNMBR, DOCNUMBR, RMDTYPAL]
	on pg.RMDTYPAL = ah.APFRDCTY
	and pg.DOCNUMBR = ah.APFRDCNM
inner join rm30101 ft	--rm_history [CUSTNMBR, DOCNUMBR, RMDTYPAL]
	on ft.RMDTYPAL = ah.APTODCTY
	and ft.DOCNUMBR = ah.APTODCNM

go
IF (@@Error = 0) PRINT 'Creación exitosa de: vwRmTrxAplicadas'
ELSE PRINT 'Error en la creación de: vwRmTrxAplicadas'
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------

--PRUEBAS
--select *
--from rm20201 
--where APFRDCNM = 'COBCLI00006346'
--and APFRDCTY= 9
--and APTODCTY = 1
--and APTODCNM = '0002653'                 

--aplicaciones de cobros en trabajo
--select a.date1,
-- 'A' rmTipoTrx, APFRDCTY, APFRDCNM, APFRDCDT, APTODCTY, APTODCNM, a.CUSTNMBR, APTODCDT, CPRCSTNM, TRXSORCE, a.GLPOSTDT, a.POSTED, TAXDTLID, 
--	APPLYTOGLPOSTDATE, a.CURNCYID, APPTOAMT, ORAPTOAM, APTOEXRATE, APPLYFROMGLPOSTDATE, FROMCURR, APFRMAPLYAMT, ACTUALAPPLYTOAMOUNT, 
--	RLGANLOS, APFRMWROFAMT, ActualWriteOffAmount, convert(varchar(12), APFRDCDT, 112) + rtrim(APFRDCNM) idPago
--from rm10201 r
--	left join rm20201 a			--rm_applied_open [APTODCNM, APTODCTY, APFRDCNM, APFRDCTY]
--	on a.apfrdcnm = r.docnumbr
--where r.bachnumb = 'OUTUBRO-PAGOS  '
--order by 1

--select top 100 *
--from vwRmTrxAplicadas
--where apfrdcnm = '0109'
