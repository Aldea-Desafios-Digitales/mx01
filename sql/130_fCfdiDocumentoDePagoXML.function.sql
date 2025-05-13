IF OBJECT_ID ('dbo.fCfdiDocumentoDePagoXML') IS NOT NULL
   DROP FUNCTION dbo.[fCfdiDocumentoDePagoXML]
GO

create function [dbo].[fCfdiDocumentoDePagoXML] (@RMDTYPAL smallint, @DOCNUMBR varchar(21))
returns xml 
as
--Propósito. DEVOLVER UN XML PARA UN COBRO TOTALMENTE APLICADO Y CONTABILIZADO, DE OTRO MODO DEVOLVER NULL
--Requisitos. EL COBRO DEBE ESTAR TOTALMENTE APLICADO Y CONTABILIZADO
--24/10/17 LT Creación cfdi
--10/11/17 jcf Correcciones varias
--24/01/18 jcf Usa montoActualOriginal para validar que los pagos estén totalmente pagados 
--02/12/19 jcf Agrega pagos relacionados
--11/12/19 jcf Modifica importe = 0 y valorUnitario = 0
--
begin
	declare @cfd xml;
	WITH XMLNAMESPACES
	(
				'http://www.w3.org/2001/XMLSchema-instance' as "xsi",
				'http://www.sat.gob.mx/cfd/3' as "cfdi",
				'http://www.sat.gob.mx/Pagos' as "pago10"
	)
	select @cfd = 
	(select 
		'http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd http://www.sat.gob.mx/Pagos http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos10.xsd'	
															'@xsi:schemaLocation',
		rtrim(pa.param1)									'@Version',
		'CBR'												'@Serie',
		rtrim(tv.DOCNUMBR)									'@Folio',
		
		convert(varchar(19), 
				dateadd(hh,
						-case when isnumeric(pa.param2) = 1 then convert(int, pa.param2) else 0 end, 
						getdate()), 
				126)										'@Fecha',
		''													'@Sello', 
		''													'@NoCertificado', 
		''													'@Certificado', 
		0													'@SubTotal',
		'XXX'												'@Moneda',
		0													'@Total',
		'P'													'@TipoDeComprobante',
		emi.codigoPostal									'@LugarExpedicion',	
		dbo.fCfdiPagosRelacionadosXML(tv.RMDTYPAL, tv.DOCNUMBR),
		emi.rfc												'cfdi:Emisor/@Rfc',
		emi.nombre											'cfdi:Emisor/@Nombre',
		emi.regimen											'cfdi:Emisor/@RegimenFiscal',
		rtrim(tv.txrgnnum)									'cfdi:Receptor/@Rfc',
		dbo.fCfdReemplazaSecuenciaDeEspacios(ltrim(rtrim(
			dbo.fCfdReemplazaCaracteresNI(tv.CUSTNAME))), 10) 'cfdi:Receptor/@Nombre',
		'P01'												'cfdi:Receptor/@UsoCFDI',
		case when tv.TXRGNNUM='XEXX010101000' then 
			case when tv.CCode = '' then null else rtrim(tv.CCode) end
			else null 
		end													'cfdi:Receptor/@ResidenciaFiscal',
		case when tv.TXRGNNUM='XEXX010101000' then 
			case when tv.taxexmt1= '' then null else rtrim(tv.taxexmt1) end
			else null 
		end													'cfdi:Receptor/@NumRegIdTrib',
		pa.param3											'cfdi:Conceptos/cfdi:Concepto/@ClaveProdServ',
		pa.param4											'cfdi:Conceptos/cfdi:Concepto/@ClaveUnidad',
		1													'cfdi:Conceptos/cfdi:Concepto/@Cantidad',
		'Pago'												'cfdi:Conceptos/cfdi:Concepto/@Descripcion',
		0													'cfdi:Conceptos/cfdi:Concepto/@ValorUnitario',
		0													'cfdi:Conceptos/cfdi:Concepto/@Importe',

		dbo.fCfdiDocumentoDePagoXMLPagos(tv.rmdtypal,tv.docnumbr) 'cfdi:Complemento'
															
	from dbo.vwRmTransaccionesTodas tv
		left join dynamics.dbo.MC40200 c on c.CURNCYID = tv.CURNCYID
		outer apply dbo.fCfdEmisor() emi
		outer apply dbo.fcfdiparametros('VERSION','CFDIDIFHORA','CLPRODSERV','CLUNIDAD','NA','NA','PREDETERMINADO') pa
	where tv.docnumbr =	@DOCNUMBR		
	and tv.RMDTYPAL = @RMDTYPAL
	and tv.montoActualOriginal = 0
	FOR XML path('cfdi:Comprobante'), type
	)
	return @cfd;
end
go
---------------------------------------------------------------------

IF (@@Error = 0) PRINT 'Creación exitosa de: [fCfdiDocumentoDePagoXML]()'
ELSE PRINT 'Error en la creación de: [fCfdiDocumentoDePagoXML]()'
GO
