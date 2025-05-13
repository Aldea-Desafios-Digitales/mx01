IF OBJECT_ID ('dbo.fCfdiDocumentoDePago') IS NOT NULL
   DROP FUNCTION dbo.fCfdiDocumentoDePago
GO


create function [dbo].fCfdiDocumentoDePago (@RMDTYPAL smallint, @DOCNUMBR varchar(21))
returns table 
as
--Propósito. Devuelve datos de un cobro
--Requisitos. Obtiene la tc del pago que permita que el monto del pago sea siempre mayor en casos especiales. Ver fCfdiDocumentoDePagoRelacionado.
--			El catálogo del sat debe estar configurado en el tipo FRPGB para cada forma de pago bancarizada
--30/11/17 jcf Creación cfdi
--14/09/18 jcf Agrega flags para incluir o no incluir campos de acuerdo al catálogo del sat: c_formaPago
--21/11/19 jcf Agrega hora del pago
--
return
		(
		SELECT 
			RMDTYPAL, DOCNUMBR, 
			CONVERT(datetime, 
						replace(convert(varchar(20), hdr.DOCDATE, 102), '.', '-')+'T'
						+case when isnumeric(left(hdr.TRXDSCRN, 6)) = 1 then 
								case when cast(SUBSTRING(hdr.trxdscrn, 1, 2) as int) between 0 and 24
									and cast(SUBSTRING(hdr.trxdscrn, 3, 2) as int) <= 60 
									and cast(SUBSTRING(hdr.trxdscrn, 5, 2)as int) <= 60 then
									SUBSTRING(hdr.trxdscrn, 1, 2) +':'+SUBSTRING(hdr.trxdscrn, 3, 2)+':'+SUBSTRING(hdr.trxdscrn, 5, 2) + '.000'
								else '12:00:00.000'
								end
						else '12:00:00.000'
						end
						--substring(
						--	convert(varchar(30), 
						--	DATEADD(hh,
						--			case when isnumeric(pa.param1) = 1 then convert(int, pa.param1) else 0 end, 
						--			hdr.dex_row_ts
						--			)
						--	, 126)
						--, 12, 8)
					,126) 
			fechaHora,
			hdr.docdate, hdr.bchsourc, hdr.mscschid, hdr.CSHRCTYP, hdr.FRTSCHID, 
			CASE WHEN hdr.bchsourc like '%MCP%' then Rtrim(mcp.grupid) 
				else ch.FormaPago
			end											FormaDePagoP,
 			LTRIM(RTRIM(C.ISOCURRC))					MonedaP,
			pago.TipoCambioP,
			hdr.ororgtrx								Monto,

			case when substring(isnull(flagsPagos.descripcion, '00000000'), 2, 1) = '1' then rtrim(hdr.cheknmbr) else null 	end									NumOperacion,
			case when cp.param1 NOT like 'no existe tag%' and substring(isnull(flagsPagos.descripcion, '00000000'), 3, 1) = '1' then cp.param1 else null end	RfcEmisorCtaOrd,
			case when cp.param2 not like 'no existe tag%' and substring(isnull(flagsPagos.descripcion, '00000000'), 8, 1) = '1' then cp.param2 else null end	NomBancoOrdExt,
			case when cp.param3 not like 'no existe tag%' and substring(isnull(flagsPagos.descripcion, '00000000'), 4, 1) = '1' then cp.param3 else null end	CtaOrdenante,
			case when substring(isnull(flagsPagos.descripcion, '00000000'), 5, 1) = '1' then rtrim(tef.TXRGNNUM) else null end									RfcEmisorCtaBen,
			case when substring(isnull(flagsPagos.descripcion, '00000000'), 6, 1) = '1' then rtrim(tef.EFTBANKACCT) else null end								CtaBeneficiario

		FROM dbo.vwRmTransaccionesTodas hdr
 			left join dynamics.dbo.MC40200 c on c.CURNCYID = HDR.CURNCYID
			outer apply dbo.fCfdiMcpFormaPago(hdr.DOCNUMBR) mcp
			left join CM00101 tef 
				on tef.CHEKBKID = CASE WHEN hdr.bchsourc like '%MCP%' then mcp.tii_chekbkid else hdr.mscschid end
			outer apply dbo.fCfdiFormaPagoManual(hdr.mscschid, hdr.CSHRCTYP, hdr.FRTSCHID) ch
			outer apply dbo.fCfdiCatalogoGetDescripcion('FRPGB', CASE WHEN hdr.bchsourc like '%MCP%' then Rtrim(mcp.grupid) else ch.FormaPago end) flagsPagos
			outer apply dbo.fCfdiParametrosCliente(hdr.custnmbr, 'RfcEmisorCtaOrd', 'NomBancoOrdExt', 'CtaOrdenante', 'NA', 'NA', 'NA', 'PREDETERMINADO') cp
			outer apply (select max(TipoCambioP) TipoCambioP from dbo.fCfdiDocumentoDePagoRelacionado(hdr.RMDTYPAL, hdr.docnumbr)) pago
			outer apply dbo.fcfdiparametros('MEXTZONE','NA','NA','NA','NA','NA','PREDETERMINADO') pa
		where hdr.docnumbr = @DOCNUMBR	
		and hdr.RMDTYPAL = @RMDTYPAL
		)

go

IF (@@Error = 0) PRINT 'Creación exitosa de: [fCfdiDocumentoDePago]()'
ELSE PRINT 'Error en la creación de: [fCfdiDocumentoDePago]()'
GO
