--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiRelacionados') IS NOT NULL
   DROP FUNCTION dbo.fCfdiRelacionados
GO

create function dbo.fCfdiRelacionados(@soptype smallint, @p_sopnumbe varchar(21), @p_docid char(15))
returns table
as
--Propósito. Obtiene la relación con otros documentos. 
--		04 sustituye un doc anulado. Puede ser nc, dev, nd, factura
--		02 nd aplica a factura
--		01, 03 NC y DEV aplican a facturas o nd
--
--Requisito. Se asume que sustituye un solo documento del mismo tipo
--		Se asume que una nc o devolución aplica una o mós facturas. Hasta 100 facturas.
--		Un documento debe tener un solo tipo de relación.
--24/10/17 jcf Creación
--16/01/18 jcf Agrega sustitución de factura anulada con NC
--02/02/18 jcf Cuando se anula una factura con nc es posible que quede un saldo en centósimas. Se acepta un rango de 0.05.
--14/02/18 jcf Relacionar el mismo tipo de documento sólo cuando es factura. No incluye el caso excepcóonal de nc que aplica a nc. Para esto se necesita un caso de uso.
--12/06/19 jcf Agrega caso de NC que aplica a factura no emitida por nosotros. El uuid debe estar en el campo nota de la factura AR.
--02/07/19 jcf Agrega caso de NC que aplica a factura no emitida por nosotros. El uuid debe estar en el campo nota de la factura SOP.
--12/09/19 jcf Parametriza validación de tipo de relación (param4)
--
return(
			--relaciona a su mismo tipo de documento. Tipo de relación 02 y 04
			select top(1) 1 orden,	
				--case when left(da.tracking_number, 1) = 'T' then '06'		--factura generada por traslado previo
				case when isnull(u.voidstts, -1) = 1 or														--sustitución de factura anulada
						(isnull(apli.APFRDCTY, -1) = 8 and (abs(u.montoActualOriginal) < 0.05)) then '04'	--sustitución de factura anulada con NC
					when isnull(u.voidstts, -1) = 0 then
						case when rtrim(@p_docid) = p.param2 and da.soptype = 3 
							then '02'										--nd que relaciona a factura
							else p.param4									--'doc no anulado'
						end
					else 'no existe uuid'
				end TipoRelacion,
				da.soptype doctype, da.tracking_number docnumbr, 
				isnull(u.UUID, 'no existe uuid') UUID, 
				u.voidstts, 
				u.FormaPago
			from sop10107 da	--
				outer apply dbo.fCfdiObtieneUUID(da.soptype, da.tracking_number) u
				outer apply dbo.fCfdiParametros('TIPORELACION01', 'TIPORELACION02', 'TIPORELACION03', 'VALIDATIPOREL', 'NA', 'NA', 'PREDETERMINADO') p
				outer apply (
							select ap.APFRDCTY
							from dbo.vwRmTrxAplicadas  ap
							where ap.aptodcnm = da.tracking_number
							and ap.aptodcty = case da.soptype when 3 then 1 else 8 end
							GROUP BY ap.APFRDCTY
							having COUNT(*) = 1
							) apli
			where da.sopnumbe = @p_sopnumbe
			and da.soptype = @soptype
			and da.soptype = 3	--facturas
			
			union all

			--NC o devolución que relaciona a factura o nd
			SELECT orden, TipoRelacion, aptodcty, aptodcnm, UUID, voidstts, FormaPago
			from (
				SELECT top(100) 2 orden,
					case when rtrim(@p_docid) = p.param1 then '01'	--nc
						when rtrim(@p_docid) = p.param3 then '03'	--devolución
						else 'no hay param'
					end TipoRelacion,
					ap.aptodcty, ap.aptodcnm, 
					isnull(isnull(isnull(u.UUID, rtrim(nt.uuid)), rtrim(usop.uuid)), 'No existe uuid') UUID, 
					isnull(u.voidstts, nt.voidstts) voidstts, 
					case when isnull(u.FormaPago, '') = '' then '99' else u.FormaPago end FormaPago
				from dbo.vwRmTrxAplicadas  ap
					outer apply dbo.fCfdiObtieneUUID(ap.aptodcty+2, ap.aptodcnm) u	
					outer apply dbo.fCfdiObtieneUUIDDeAR(ap.aptodcty, ap.aptodcnm, ap.custnmbr) nt	--tipo factura es 1 en AR
					outer apply dbo.fCfdiObtieneUUIDDeSOP(ap.aptodcty+2, ap.aptodcnm) usop			--tipo factura es 1 en AR
					outer apply dbo.fCfdiParametros('TIPORELACION01', 'TIPORELACION02', 'TIPORELACION03', 'NA', 'NA', 'NA', 'PREDETERMINADO') p
				where ap.APFRDCTY = @soptype+4										--tipo nc es 8 en AR
				AND ap.apfrdcnm = @p_sopnumbe
				and @soptype = 4
				order by ap.oraptoam desc
			) nc
)	
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiRelacionados()'
ELSE PRINT 'Error en la creación de: fCfdiRelacionados()'
GO

--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiDatosDeUnaRelacion') IS NOT NULL
   DROP FUNCTION dbo.fCfdiDatosDeUnaRelacion
GO

create function dbo.fCfdiDatosDeUnaRelacion(@soptype smallint, @p_sopnumbe varchar(21), @p_docid char(15))
returns table
as
--Propósito. Obtiene la primera relación. La sustitución tiene precedencia sobre el resto.
--Requisito. -
--24/10/17 jcf Creación
--
return(
				select top (1) TipoRelacion, FormaPago
				from dbo.fCfdiRelacionados(@soptype, @p_sopnumbe, @p_docid)
				--order by orden

)	
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiDatosDeUnaRelacion()'
ELSE PRINT 'Error en la creación de: fCfdiDatosDeUnaRelacion()'
GO

--------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiRelacionadosXML') IS NOT NULL
   DROP FUNCTION dbo.fCfdiRelacionadosXML
GO

create function dbo.fCfdiRelacionadosXML(@soptype smallint, @p_sopnumbe varchar(21), @p_docid char(15), @p_TipoRelacion varchar(15))
returns xml 
as
--Propósito. Obtiene la relación con otros documentos en formato XML. 
--		04 sustituye un doc anulado. Puede ser nc, dev, nd, factura
--		02 nd aplica a factura
--		01, 03 NC y DEV aplican a facturas o nd
--24/01/14 jcf Creación
--
begin

	declare @cncp xml;
		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
		select @cncp = (
			select 	rf.UUID '@UUID'
			from dbo.fCfdiRelacionados(@soptype, @p_sopnumbe, @p_docid) rf
			where rf.TipoRelacion = @p_TipoRelacion 
			FOR XML path('cfdi:CfdiRelacionado'), type
		)
	
	return @cncp
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiRelacionadosXML()'
ELSE PRINT 'Error en la creación de: fCfdiRelacionadosXML()'
GO

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

