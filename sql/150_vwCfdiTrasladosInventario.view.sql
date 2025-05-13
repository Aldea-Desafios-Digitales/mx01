-----------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiTrasladosInventario', 'V') IS NULL)
   exec('create view dbo.vwCfdiTrasladosInventario as SELECT 1 as t');
go

alter view dbo.vwCfdiTrasladosInventario as
--Propósito. Transacciones de inventario a nivel de cabecera. 
--			Suma 15 al tipo de documento de IV para no colisionar con transacciones de SOP, RM
--Requisitos. Es probable que no requiera del chunk Guía de remisión GREM.cnk
--19/12/17 jcf Creación cfdi 3.3 traslado
--
select tv.estadoContabilizado, tv.soptype, 
	'REMTRASLADO' docid,
	--isnull(gr.docid, '') docid, 
	tv.doctype, tv.docnumbr, tv.dex_row_ts, 
	--convert(datetime, left(convert(varchar(25), tv.dex_row_ts, 126), 19), 126) fechaHora,

	convert(datetime,
			replace(convert(varchar(20), tv.DOCDATE, 102), '.', '-')+'T'+substring(convert(varchar(25), tv.dex_row_ts, 126), 12, 8)
			,126) fechaHora,

	'XAXX010101000' rfcReceptor, 'P01' usoCfdi, 'MXN' moneda
	--isnull(gr2.txrgnnum, '') CUSTNMBR, isnull(gr2.custname, '') nombreCliente, isnull(gr2.txrgnnum, '') idImpuestoCliente, 
from (
	select estadoContabilizado, TRXSORCE, cast(doctype+15 as smallint) soptype, doctype, docnumbr, dex_row_ts, docdate
	from dbo.vwIvTransaccionesTHDet
	where doctype = 3
	group by estadoContabilizado, TRXSORCE, doctype, docnumbr, dex_row_ts, docdate
	) tv
	--left join tblGREM001 gr
	--	on gr.GREMReferenciaNumb = tv.docnumbr
	--	and gr.GREMReferenciaTipo = tv.doctype
	--	and gr.GREMGuiaIndicador = 2 --trf iv
	--left join tblGREM002 gr2
	--	on gr2.GREMGuiaIndicador = gr.GREMGuiaIndicador
	--	and gr2.DOCID = gr.DOCID
	--	and gr2.DOCNUMBR = gr.DOCNUMBR
go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwCfdiTrasladosInventario'
ELSE PRINT 'Error en la creación de la vista: vwCfdiTrasladosInventario'
GO

-----------------------------------------------------------------------------------------
