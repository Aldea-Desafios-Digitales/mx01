
IF (OBJECT_ID ('dbo.vwRmTransaccionesTodas', 'V') IS NULL)
   exec('create view dbo.vwRmTransaccionesTodas as SELECT 1 as t');
go

--01/03/06 JCF Creación
--28/08/08 JCF Adición de id de lote (bachnumb)
--10/12/08 JCF Adición de duedate, curtrxam, country, city, custclas, address3
--27/02/09 JCF Adición de SLPRSNID
--19/05/09 PE Adición de TXRGNNUM
--16/07/09 JCF Agrega tabla de valores multimoneda mc020102
--10/08/09 jcf Agrega porcentaje de condición de pago: dscpctam (porcentaje), dscdlram (monto condición de pago). Corrige montos originales y funcionales.
--28/06/10 JCF Agrega noteindx
--19/10/11 jcf Agrega equivalente soptype, cheknmbr
--29/02/12 jcf Modifica orctrxam, ororgtrx. Devuelve moneda funcional si no existe en moneda original
--06/03/12 jcf Ajusta xchgrate. Devuelve 0 si no existe. Agrega TrxDscrn.
--26/04/12 jcf Agrega agngbukt y montoActualOriginal
--11/07/12 jcf Agrega slsamnt
--21/12/12 jcf Agrega MSCSCHID
--08/01/13 jcf Agrega taxschid, cashamnt
--03/03/13 jcf Agrega cshrctyp
--07/11/14 jcf Agrega cspornbr (customer po number)
--14/01/15 jcf Agrega cus.bnkbrnch, cus.prbtadcd
--25/02/15 jcf Agrega cus.bankname
--18/06/15 jcf Agrega cus.ADDRESS1, cus.ADDRESS2, city, state, zip, userdef1
--09/09/15 jcf Agrega postdate, trx.VOIDDATE
go

ALTER VIEW dbo.vwRmTransaccionesTodas
--Propósito. Detalle de transacciones de Receivables Management abiertas e históricas
--...
--05/05/17 jcf Agrega wrofamnt
--10/11/17 jcf Agrega cus.CCode, cus.taxexmt1, FRTSCHID, CBKIDCHK
--30/11/17 jcf Agrega dex_row_ts
--26/03/18 jcf Agrega taxexmt2 para ucfe
--
AS
       --Transacciones abiertas de Receivables Management
       SELECT 'A' rmTipoTrx, trx.DOCDATE, trx.postdate, trx.RMDTYPAL, 
            case trx.RMDTYPAL when 0 then '*Balance Forward' 
                                when 1 then 'Ventas/Facturas' 
                                when 2 then '*Scheduled Payments'
                                when 3 then 'Notas de Débito'
                                when 4 then 'Cargos Financieros'
                                when 5 then 'Devengamiento'
                                when 6 then 'Garantías'
                                when 7 then 'Notas de Crédito'
                                when 8 then 'Devoluciones'
                                when 9 then 'Pagos'
                               else 'Otros'
            end tipoDoc,
            case trx.RMDTYPAL when 1 then 3
								when 8 then 4
								else 0
			end soptype,	--equivalente soptype
            trx.DOCNUMBR, trx.bachnumb, trx.bchsourc, trx.trxsorce, trx.VOIDstts, trx.VOIDDATE, cus.custnmbr, cus.custname, cus.txrgnnum, cus.taxexmt1, cus.taxexmt2,
            case when trx.RMDTYPAL >=6 then -1 else 1 end * trx.taxAmnt TotalImpuesto, 
            case when trx.RMDTYPAL >=6 then -1 else 1 end * trx.orTrxAmt TotalDoc,
            case when trx.RMDTYPAL >=6 then -1 else 1 end * trx.curtrxam montoActual,
            case when trx.RMDTYPAL >=6 then -1 else 1 end * isnull(mx.orctrxam, trx.curtrxam) montoActualOriginal, 
            trx.dscpctam, trx.dscdlram, trx.duedate, datediff(day, trx.docdate, trx.duedate) diasVencimiento, 
			trx.pymtrmid, case when upper(trx.pymtrmid) like '%x1000%' then 1000 else 100 end xDecimales,
			cus.CCode, cus.COUNTRY, cus.CITY, cus.[STATE], cus.ZIP, cus.ADRSCODE, cus.userdef1,
			cus.ADDRESS1, cus.ADDRESS2, cus.ADDRESS3, 
			cus.CUSTCLAS, cus.taxschid, cus.bnkbrnch, cus.bankname, cus.prbtadcd, trx.SLPRSNID,
			trx.curncyid, trx.curtrxam, trx.ortrxamt, trx.slsamnt, trx.cashamnt, trx.wrofamnt,
			isnull(mx.orctrxam, trx.curtrxam) orctrxam, 
			isnull(mx.ororgtrx, trx.ortrxamt) ororgtrx, 
			isnull(mx.xchgrate, 0) xchgrate, mx.orddlrat, trx.noteindx, trx.cheknmbr, trx.TRXDSCRN, trx.agngbukt, trx.MSCSCHID, trx.cshrctyp, trx.cspornbr, 
			trx.FRTSCHID, trx.CBKIDCHK, trx.dex_row_ts
         from rm00101 cus			--rm_customer_mstr
			inner join rm20101 trx  --rm_open [CUSTNMBR, DOCNUMBR, RMDTYPAL]
			on cus.custnmbr = trx.custnmbr
			left join mc020102 mx	--mc_rm_transactions [rmdtypal, docnumbr]
			on mx.rmdtypal = trx.rmdtypal
			and mx.docnumbr = trx.docnumbr
			and mx.custnmbr = trx.custnmbr
        UNION all
       --Transacciones históricas de Receivables Management
       SELECT 'H' rmTipoTrx, trx.DOCDATE, trx.postdate, trx.RMDTYPAL, 
              case trx.RMDTYPAL when 0 then '*Balance Forward' 
                                when 1 then 'Ventas/Facturas' 
                                when 2 then '*Scheduled Payments'
                                when 3 then 'Notas de Débito'
                                when 4 then 'Cargos Financieros'
                                when 5 then 'Devengamiento'
                                when 6 then 'Garantías'
                                when 7 then 'Notas de Crédito'
                                when 8 then 'Devoluciones'
                                when 9 then 'Pagos'
                               else 'Otros'
               end tipoDoc,
            case trx.RMDTYPAL when 1 then 3
								when 8 then 4
								else 0
			end soptype,	--equivalente soptype
            trx.DOCNUMBR, trx.bachnumb, trx.bchsourc, trx.trxsorce, trx.VOIDstts, trx.VOIDDATE, cus.custnmbr, cus.custname, cus.txrgnnum, cus.taxexmt1, cus.taxexmt2,
            case when trx.RMDTYPAL >=6 then -1 else 1 end * trx.taxAmnt TotalImpuesto, 
            case when trx.RMDTYPAL >=6 then -1 else 1 end * trx.orTrxAmt TotalDoc,
            case when trx.RMDTYPAL >=6 then -1 else 1 end * trx.curtrxam montoActual,
            case when trx.RMDTYPAL >=6 then -1 else 1 end * isnull(mx.orctrxam, trx.curtrxam) montoActualOriginal, 
            trx.dscpctam, trx.dscdlram, trx.duedate, datediff(day, trx.docdate, trx.duedate) diasVencimiento, 
			trx.pymtrmid, case when upper(trx.pymtrmid) like '%x1000%' then 1000 else 100 end xDecimales,
			cus.CCode, cus.COUNTRY, cus.CITY, cus.[STATE], cus.ZIP, cus.ADRSCODE, cus.userdef1,
			cus.ADDRESS1, cus.ADDRESS2, cus.ADDRESS3, 
			cus.CUSTCLAS, cus.taxschid, cus.bnkbrnch, cus.bankname, cus.prbtadcd, trx.SLPRSNID,
			trx.curncyid, trx.curtrxam, trx.ortrxamt, trx.slsamnt, trx.cashamnt, trx.wrofamnt,
			isnull(mx.orctrxam, trx.curtrxam) orctrxam, 
			isnull(mx.ororgtrx, trx.ortrxamt) ororgtrx, 
			isnull(mx.xchgrate, 0) xchgrate, mx.orddlrat, trx.noteindx, trx.cheknmbr, trx.TRXDSCRN, 1, trx.MSCSCHID, trx.cshrctyp, trx.cspornbr, 
			trx.FRTSCHID, '' CBKIDCHK, trx.dex_row_ts
         from rm00101 cus			--rm_customer_mstr
			inner join rm30101 trx  --rm_history [CUSTNMBR, DOCNUMBR, RMDTYPAL]
			on cus.custnmbr = trx.custnmbr
			left join mc020102 mx	--mc_rm_transactions [rmdtypal, docnumbr]
			on mx.rmdtypal = trx.rmdtypal
			and mx.docnumbr = trx.docnumbr
			and mx.custnmbr = trx.custnmbr
go
IF (@@Error = 0) PRINT 'Creación exitosa de: vwRmTransaccionesTodas'
ELSE PRINT 'Error en la creación de: vwRmTransaccionesTodas'
GO

grant select on vwRmTransaccionesTodas to dyngrp;
--------------------------------------------------------------------------------------------------
