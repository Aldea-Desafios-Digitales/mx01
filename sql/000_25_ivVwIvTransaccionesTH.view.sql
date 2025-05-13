
--Propósito. Obtiene trx de inventario en trabajo e históricas
           --Las recepciones no tienen cabecera en iv30200. Utilizar IVRecepciones...
           --Las ventas no tienen cabecera en iv30200. Utilizar IVFVentas...
--Utilizado por. Cfdi 33 México
--19/12/17 Creación
-----------------------------------------------------------------

IF (OBJECT_ID ('dbo.vwIvTransaccionesTHDet', 'V') IS NULL)
   exec('create view dbo.vwIvTransaccionesTHDet as SELECT 1 as t');
go
--drop view dbo.vwIvTransaccionesTH
alter view dbo.vwIvTransaccionesTHDet as
--TRANSACCIONES DE INVENTARIO EN TRABAJO 
select 'en lote' estadoContabilizado, lin.ivdoctyp doctype,
	   case when lin.ivdoctyp=1 and lin.trxqty<0 then 'Consumo' 
            when lin.ivdoctyp=1 and lin.trxqty>0 then 'Ingreso' 
            when lin.ivdoctyp=3 then 'Transf.' 
            when lin.ivdoctyp=2 then 'Variac.' 
            else 'Otro' 
       end tipoDoc, 
       cab.ivdocnbr docnumbr, cab.docdate, cab.noteindx, 
       lin.lnseqnbr, lin.itemnmbr, item.itemdesc, item.ivivindx, item.uscatvls_6, item.UOMSCHDL, 
       lin.trxqty, lin.uofm, lin.unitcost, lin.unitcost*lin.trxqty importe, 
	   lin.trxloctn, lin.trnstloc, lin.lnseqnbr numLine, cab.BCHSOURC TRXSORCE, cab.dex_row_ts
  from iv10001 lin				--iv_trx_work_line
       inner join iv10000 cab	--iv_trx_work_hdr
	      --cabecera y detalle de la transacción
			on cab.ivdocnbr = lin.ivdocnbr
		   and cab.ivdoctyp = lin.ivdoctyp
		inner join iv00101 item --iv_item_mstr
			on item.itemnmbr = lin.itemnmbr
union all

--TRANSACCIONES DE INVENTARIO HISTORICAS 
--No incluye recepciones de compra ni ventas!
select 'contabilizado' estadoContabilizado, lin.doctype,
	case when lin.doctype=1 and lin.trxqty<0 then 'Consumo' 
            when lin.doctype=1 and lin.trxqty>0 then 'Ingreso' 
            when lin.doctype=3 then 'Transf.' 
            when lin.doctype=2 then 'Variac.' 
            else 'Otro' 
       end tipoDoc, 
       cab.docnumbr, cab.docdate, cab.noteindx, 
       lin.lnseqnbr, lin.itemnmbr, item.itemdesc, item.ivivindx, item.uscatvls_6, item.UOMSCHDL, 
       lin.trxqty, lin.uofm, lin.unitcost, lin.unitcost*lin.trxqty importe, 
       lin.trxloctn, lin.trnstloc, lin.lnseqnbr numLine, cab.TRXSORCE, cab.dex_row_ts
  from iv30300 lin				--iv_trx_hist_line Líneas de trx de ajuste, transf y recepciones
       inner join iv30200 cab	--iv_trx_hist_hdr Cabecera de trx de ajuste y transferencia
		on cab.ivdoctyp = lin.doctype
		and cab.docnumbr = lin.docnumbr
       inner join iv00101 item --iv_item_mstr
		on item.itemnmbr = lin.itemnmbr
go
-----------------------------------------------------------------------------------
