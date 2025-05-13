IF OBJECT_ID ('dbo.fCfdParametrosAddenda') IS NOT NULL
   DROP FUNCTION dbo.fCfdParametrosAddenda
GO

create function dbo.fCfdParametrosAddenda(@p_custnmbr char(15), @tag1 varchar(15), @tag2 varchar(15), @tag3 varchar(15))
returns table
as
--Propósito. Devuelve los parámetros de la Addenda por cliente
--Requisitos. Los @tagx deben configurarse en la ventana Información de internet del id de dirección ADDENDA de cada cliente
--7/11/12 jcf Creación 
--
return
(
	select rtrim(lm.ADRCNTCT) ADRCNTCT, rtrim(ia.inet1) cmp_inet1, rtrim(nt.inet1) cus_inet1, 
		case when charindex(@tag1+'=', nt.inetinfo) > 0 and charindex(char(13), nt.inetinfo) > 0 then
			substring(nt.inetinfo, charindex(@tag1+'=', nt.inetinfo) +len(@tag1)+1, charindex(char(13), nt.inetinfo, charindex(@tag1+'=', nt.inetinfo)) - charindex(@tag1+'=', nt.inetinfo) - len(@tag1)-1) 
		else 'no existe tag: '+@tag1 end param1,
		CASE when charindex(@tag2+'=', nt.inetinfo) > 0 and  charindex(char(13), nt.inetinfo) > 0 then
			substring(nt.inetinfo, charindex(@tag2+'=', nt.inetinfo)+ len(@tag2)+1, charindex(char(13), nt.inetinfo, charindex(@tag2+'=', nt.inetinfo)) - charindex(@tag2+'=', nt.inetinfo) - len(@tag2)-1) 
		else 'no existe tag: '+@tag2 end param2,
		CASE when charindex(@tag3+'=', nt.inetinfo) > 0 and  charindex(char(13), nt.inetinfo) > 0 then
			substring(nt.inetinfo, charindex(@tag3+'=', nt.inetinfo)+ len(@tag3)+1, charindex(char(13), nt.inetinfo, charindex(@tag3+'=', nt.inetinfo)) - charindex(@tag3+'=', nt.inetinfo) - len(@tag3)-1)
		else 'no existe tag: '+@tag3 end param3
	from SY01200 ia						--coInetAddress Dirección addenda de la compañía
		CROSS join SY01200 nt			--coInetAddress Dirección addenda del cliente
		CROSS join DYNAMICS..SY01500 ci	--sy_company_mstr 
		inner join sy00600 lm			--sy_location_mstr
		on ci.INTERID = DB_NAME()
		and ci.CMPANYID = lm.CMPANYID
		and lm.LOCATNID = 'ADDENDA'
	where ia.Master_Type = 'CMP'
	and ia.Master_ID = DB_NAME()
	and ia.ADRSCODE = 'ADDENDA'
	and nt.Master_Type = 'CUS'
	and nt.Master_ID = @p_custnmbr
	and nt.ADRSCODE = 'ADDENDA'
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdParametrosAddenda()'
ELSE PRINT 'Error en la creación de la función: fCfdParametrosAddenda()'
GO
------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdAddendaSopTrack') IS NOT NULL
   DROP FUNCTION dbo.fCfdAddendaSopTrack
GO

create function dbo.fCfdAddendaSopTrack(@p_soptype smallint, @p_sopnumbe varchar(21))
returns table
as
--Propósito. Primer número de seguimiento de una factura
--21/2/14 jcf Creación
--
return (
	select top 1 Tracking_Number
	from SOP10107
	where sopnumbe = @p_sopnumbe
	and SOPTYPE = @p_soptype
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdAddendaSopTrack()'
ELSE PRINT 'Error en la creación de: fCfdAddendaSopTrack()'
GO

--------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdAddendaImpuestos') IS NOT NULL
begin
   DROP FUNCTION dbo.fCfdAddendaImpuestos
   print 'función fCfdAddendaImpuestos eliminada'
end
GO

create function dbo.fCfdAddendaImpuestos(@p_soptype smallint, @p_sopnumbe varchar(21), @p_impuestos varchar(150))
returns xml 
as
--Propósito. Impuestos de una factura para addenda de Mabe
--21/2/14 jcf Creación
--
begin
	declare @impu xml;
	select @impu = (
		select 	
		 	'VAT'															'@type',
		 	dbo.fCfdObtienePorcentajeImpuesto (imp.taxdtlid)				'taxPercentage',
			imp.orslstax													'taxAmount',
		 	'TRANSFERIDO'													'taxCategory'
		from sop10105 imp					--sop_tax_work_hist
 		where imp.SOPTYPE = @p_soptype
		  and imp.SOPNUMBE = @p_sopnumbe
		  and imp.LNITMSEQ = 0
		  and charindex(RTRIM(imp.taxdtlid), @p_impuestos) > 0
		FOR XML path('tax')
		)
	return @impu
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdAddendaImpuestos()'
ELSE PRINT 'Error en la creación de la función: fCfdAddendaImpuestos()'
GO

----------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdAddendaDetalleImpuestos') IS NOT NULL
begin
   DROP FUNCTION dbo.fCfdAddendaDetalleImpuestos
   print 'función fCfdAddendaDetalleImpuestos eliminada'
end
GO

create function dbo.fCfdAddendaDetalleImpuestos(@p_soptype smallint, @p_sopnumbe varchar(21), @p_impuestos varchar(150))
returns xml 
as
--Propósito. Impuestos del detalle de una factura para addenda de Mabe
--21/2/14 jcf Creación
--
begin
	declare @impu xml;
	select @impu = (
		select 	
		 	'VAT'															'taxTypeDescription',
		 	dbo.fCfdObtienePorcentajeImpuesto (imp.taxdtlid)				'tradeItemTaxAmount/taxPercentage',
			imp.orslstax													'tradeItemTaxAmount/taxAmount',
		 	'TRANSFERIDO'													'taxCategory'
		from sop10105 imp					--sop_tax_work_hist
 		where imp.SOPTYPE = @p_soptype
		  and imp.SOPNUMBE = @p_sopnumbe
		  and imp.LNITMSEQ = 0
		  and charindex(RTRIM(imp.taxdtlid), @p_impuestos) > 0
		FOR XML path('tradeItemTaxInformation')
		)
	return @impu
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdAddendaDetalleImpuestos()'
ELSE PRINT 'Error en la creación de la función: fCfdAddendaDetalleImpuestos()'
GO

------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdAddendaDetalle') IS NOT NULL
   DROP FUNCTION dbo.fCfdAddendaDetalle
GO

create function dbo.fCfdAddendaDetalle(@p_soptype smallint, @p_sopnumbe varchar(21), @p_impuestos varchar(150))
returns xml 
as
--Propósito. Detalle de una factura para addenda de Mabe
--21/02/14 jcf Creación
--06/12/17 JCF Modifica campo oxtndprc, quantity
--
begin
	declare @cncp xml;
	select @cncp = (
		select 
			ROW_NUMBER() OVER(PARTITION BY Concepto.sopnumbe ORDER BY Concepto.lnitmseq)	'@number',
			'SimpleInvoiceLineItemType'									'@type',
			'SUPPLIER_ASSIGNED'											'alternateTradeItemIdentification/@type',
			rtrim(Concepto.ITEMNMBR)									'alternateTradeItemIdentification',
			dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(dbo.fCfdReemplazaCaracteresNI(Concepto.ITEMDESC))), 10)	'tradeItemDescriptionInformation/longText',
			'PZA'														'invoicedQuantity/@unitOfMeasure',
			Concepto.QUANTITY											'invoicedQuantity',
			Concepto.ORUNTPRC											'grossPrice/Amount',
			Concepto.ORUNTPRC											'netPrice/Amount',
			dbo.fCfdAddendaDetalleImpuestos(Concepto.soptype, Concepto.sopnumbe, @p_impuestos),
			Concepto.OXTNDPRC											'totalLineAmount/grossAmount/Amount',
			Concepto.OXTNDPRC											'totalLineAmount/netAmount/Amount'
		from SOP30300 Concepto
		where Concepto.CMPNTSEQ = 0					--a nivel kit
		and Concepto.soptype = @p_soptype
		and Concepto.sopnumbe = @p_sopnumbe
		FOR XML path('lineItem')
	)
	return @cncp
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdAddendaDetalle()'
ELSE PRINT 'Error en la creación de: fCfdAddendaDetalle()'
GO

-----------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdAddendaXML') IS NOT NULL
   DROP FUNCTION dbo.fCfdAddendaXML
GO

create function dbo.fCfdAddendaXML(	@p_custnmbr char(15), @p_soptype smallint, @p_sopnumbe char(21), 
									@p_docid char(15), @p_CSTPONBR char(21), @p_moneda char(15), @p_docdate datetime, @p_xchgrate numeric(21,7), @p_subtotal numeric(21,5), @p_total numeric(19,6),
									@incluyeAddendaDflt varchar(2)='NO')

returns xml 
as
--Propósito. Obtiene la sección addenda en formato xml. 
--09/10/12 jcf Creación. Crea la addenda para cliente ADO. 
--07/11/12 jcf Agrega addenda para cliente Deloitte.
--21/11/12 jcf Agrega name space a nodo addenda para Deloitte
--26/11/12 jcf Modifica addenda de cliente ADO. El tipo está configurado en el cliente.
--03/09/13 jcf Agrega cfdi namespace
--24/02/14 jcf Agrega addenda de cliente Mabe
--14/09/17 jcf Agrega parámetros incluyeAddendaDflt para addenda predeterminada para todos los clientes. Utilizado en MTP
--19/01/18 jcf Agrega addenda de cliente pemex de Achilles
--
begin
	declare @cncp xml, @numDigitos int, @posicion int --, @satNameSpace varchar(100);
	select @numDigitos = len(@p_CSTPONBR),
		@posicion = 3
	if @incluyeAddendaDflt= 'SI'
	begin
		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as cfdi)
		select @cncp = (
			select LTRIM(rtrim(@p_CSTPONBR)) addPedidoCliente,
				(select dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(RTRIM(substring(cmmttext, 1, 350))), 10) addLeyenda
				from sop10106
				where sopnumbe = @p_sopnumbe
				and soptype = @p_soptype
				and comment_1 != ''
				) addLeyenda
			FOR XML PATH(''), type, root('cfdi:Addenda'), elements
		)
	end
	--Cliente ADO requiere un número de referencia que está en CSTPONBR. Ref. Addenda Grupo ADO_REF.doc
	else if rtrim(@p_custnmbr) = '000011658' and @numDigitos >= @posicion
	begin
		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as cfdi)
		select @cncp = (
			SELECT pa.param1 'proveedor/@tipoAddenda',
				LTRIM(rtrim(@p_CSTPONBR)) 'addenda/@valor'
			from dbo.fCfdParametrosAddenda(@p_custnmbr, 'tipoAddenda', '-', '-') pa
			FOR XML PATH(''), type, root('cfdi:Addenda')
		)
	end
	--Cliente Deloitte
	else if rtrim(@p_custnmbr) = '005599063' 
	begin	
		--declare @cncp xml, @p_CSTPONBR char(21), @p_moneda char(15);
		--select @p_moneda = 'MXN', @p_CSTPONBR= '654897897';
		WITH XMLNAMESPACES ( 'http://www.deloitte.com/CFD/Addenda/Receptor' as del)
		select @cncp = (
			select rtrim(@p_CSTPONBR) 'noPedido',
				case when rtrim(@p_moneda) = 'MXN' then 'MXP' 
					when rtrim(@p_moneda) = 'U$S' then 'USD' 
					else rtrim(@p_moneda) 
				end 'moneda',
				pa.cus_inet1 'mailContactoDeloitte',
				pa.param1 'oficina',
				pa.param2 'origenFactura',
				pa.param3 'numeroProveedor',
				pa.cmp_inet1 'mailProveedor',
				pa.adrcntct 'nombreContactoProveedor'
			from dbo.fCfdParametrosAddenda(@p_custnmbr, 'oficina', 'origenFactura', 'numeroProveedor') pa
			FOR XML RAW ('del:AddendaDeloitte')
		);

		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as cfdi)
		select @cncp = ( 
				select @cncp
				for xml path(''), root('cfdi:Addenda')
				)
	end
	--Cliente Mabe
	else if (rtrim(@p_custnmbr) = '005562749' and @p_soptype = 3)
	begin	
		select @cncp = (
			SELECT 
				replace(convert(varchar(20), @p_docdate , 102), '.', '-')		'@DeliveryDate',
				'1.3.1'															'@contentVersion',
				'ORIGINAL'														'@documentStatus',
				'AMC7.1'														'@documentStructureVersion',
				'SimpleInvoiceType'												'@type',
				'INVOICE'														'requestForPaymentIdentification/entityType',
				rtrim(@p_docid) + rtrim(@p_sopnumbe)							'requestForPaymentIdentification/uniqueCreatorIdentification',
				'ON'															'orderIdentification/referenceIdentification/@type',
				rtrim(@p_CSTPONBR)												'orderIdentification/referenceIdentification',
				'DQ'															'AdditionalInformation/referenceIdentification/@type',
				rtrim(tr.Tracking_Number)										'AdditionalInformation/referenceIdentification',
				'7504003434006'													'buyer/gln',
				rtrim(rm.CNTCPRSN)												'buyer/contactInformation/personOrDepartmentName/text',
				'SELLER_ASSIGNED_IDENTIFIER_FOR_A_PARTY'						'seller/alternatePartyIdentification/@type',
				pa.param1														'seller/alternatePartyIdentification',
				rtrim(rm.ADDRESS1)												'shipTo/gln',
				rtrim(rm.ADDRESS2)												'shipTo/nameAndAddress/name',
				rtrim(rm.ADDRESS3)												'shipTo/nameAndAddress/streetAddressOne',
			 	rtrim(rm.CITY)													'shipTo/nameAndAddress/city',
			 	rtrim(rm.ZIP)													'shipTo/nameAndAddress/postalCode',
			 	case when rtrim(@p_moneda) = 'U$S' then 'USD'
			 		when  rtrim(@p_moneda) = 'EURO' then 'XEU'
			 		else rtrim(@p_moneda)
			 	end																'currency/@currencyISOCode',
			 	'BILLING_CURRENCY'												'currency/currencyFunction',
			 	case when @p_xchgrate <= 0 then 1 else @p_xchgrate end			'currency/rateOfChange',
			 	dbo.fCfdAddendaDetalle(@p_soptype, @p_sopnumbe, emi.impuestos),
			 	@p_subtotal														'totalAmount/Amount',
			 	@p_subtotal														'baseAmount/Amount',
			 	dbo.fCfdAddendaImpuestos(@p_soptype, @p_sopnumbe, emi.impuestos),
			 	@p_total														'payableAmount/Amount'
			FROM RM00102 rm
			outer apply dbo.fCfdAddendaSopTrack(@p_soptype, @p_sopnumbe) tr
			outer apply dbo.fCfdParametrosAddenda(@p_custnmbr, 'SELLER', '-', '-') pa
			cross join dbo.fCfdEmisor() emi
			where rm.custnmbr = @p_custnmbr
			and rm.adrscode = 'ADDENDA'
			FOR XML path ('requestForPayment')
		);

		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as cfdi)
		select @cncp = ( 
				select @cncp
				for xml path(''), root('cfdi:Addenda')
				)
	end
	--Achilles. Cliente PEMEX
	else if exists(select custnmbr from rm00101 where custnmbr = rtrim(@p_custnmbr) and  TXRGNNUM = 'PME380607P35')
	begin	
		select @cncp = convert(xml, 
					'<pm:Addenda_Pemex xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:pm="http://pemex.com/facturaelectronica/addenda/v2" xsi:schemaLocation="http://pemex.com/facturaelectronica/addenda/v2 https://pemex.reachcore.com/schemas/addenda-pemex-v2.xsd">' +
					dbo.fCfdReemplazaSecuenciaDeEspacios(dbo.fCfdReemplazaCaracteresNI(cmmttext), 10) +
					'</pm:Addenda_Pemex>')
		from sop10106
		where sopnumbe = @p_sopnumbe
		and soptype = @p_soptype
		and comment_1 != '';

		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as cfdi)
		select @cncp = ( 
				select @cncp
				for xml path(''), root('cfdi:Addenda')
				)
		--select @cncpXml;
	end

	return @cncp
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdAddendaXML()'
ELSE PRINT 'Error en la creación de: fCfdAddendaXML()'
GO
--------------------------------------------------------------------------------------------------------

--create function dbo.fCfdAddendaXML(	@p_custnmbr char(15), @p_soptype smallint, @p_sopnumbe char(21), 
--									@p_docid char(15), @p_CSTPONBR char(21), @p_moneda char(15), @p_docdate datetime, @p_xchgrate numeric(21,7), @p_subtotal numeric(21,5), @p_total numeric(19,6))

--returns xml 
--as
----Propósito. Obtiene la sección addenda en formato xml. En Maclean no es necesario.
----12/5/15 jcf Creación
----
--begin
--	return null
--end
--go
--------------------------------------------------------------------------------------------------------
--SELECT dbo.fCfdAddendaXML(	'005562749', 3, '0007305', 'FVE', '888999', 'MXN', '2/27/14', 1, 3600.1, 4176.12, 'SI')
--select * from dbo.fCfdEmisor()
--select dbo.fCfdAddendaDetalle(3, '0007303', 'V-IVA 16%')


--sp_statistics mc40200
--sp_columns sop30200

