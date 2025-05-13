IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwCfdiPagosSimultaneos]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.vwCfdiPagosSimultaneos;
GO
create view dbo.vwCfdiPagosSimultaneos
--Propósito. Obtiene facturas totalmente pagadas en simultáneo
--Utilizado por: 
--1/11/17 JCF Creación
--
as
	select apfrdcty, apfrdcnm, ap.APTODCTY+2 APTODCTY, ap.APTODCNM 
	from dbo.tii_vwRmTrxAplicadasExtendidas ap
	where ap.cashamnt_apto = ap.ortrxamt_apto
go

IF (@@Error = 0) PRINT 'Creación exitosa de: vwCfdiPagosSimultaneos'
ELSE PRINT 'Error en la creación de: vwCfdiPagosSimultaneos'
GO

------------------------------------------
