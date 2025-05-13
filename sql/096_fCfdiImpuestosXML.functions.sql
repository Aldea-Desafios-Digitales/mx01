
-------------------------------------------------------------------------------------------------------
IF (OBJECT_ID ('dbo.vwCfdiImpuestosYRetencionesDetalle', 'V') IS NULL)
   exec('create view dbo.vwCfdiImpuestosYRetencionesDetalle as SELECT 1 as t');
go

alter view dbo.vwCfdiImpuestosYRetencionesDetalle as
--Propósito. Obtiene la suma de los impuestos y retenciones
--18/12/19 JCF Creación
--
			select
				cast(imp.ortxsls as numeric(19,2)) Base,
				rtrim(tx.NAME) CodImpuesto,
				case when tx.TXDTLPCT=0 then 'Exento' else 'Tasa' end TipoFactor, 
				case when tx.TXDTLPCT=0 then null else cast(abs(tx.TXDTLPCT)/100 as numeric(19,6)) end TasaOCuota,
				case when tx.TXDTLPCT=0 then null else cast(abs(imp.orslstax) as numeric(19,2)) end Importe,
                tx.TXDTLPCT, imp.SOPTYPE, imp.SOPNUMBE, imp.LNITMSEQ
			from sop10105 imp	--sop_tax_work_hist
			inner join tx00201 tx
				on tx.taxdtlid = imp.taxdtlid
go	

IF (@@Error = 0) PRINT 'Creación exitosa de: vwCfdiImpuestosYRetencionesDetalle'
ELSE PRINT 'Error en la creación de: vwCfdiImpuestosYRetencionesDetalle'
GO


--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiImpuestosRetenidosXML') IS NOT NULL
begin
   DROP FUNCTION dbo.fCfdiImpuestosRetenidosXML
   print 'función fCfdiImpuestosRetenidosXML eliminada'
end
GO

create function dbo.fCfdiImpuestosRetenidosXML(@p_soptype smallint, @p_sopnumbe varchar(21), @p_LNITMSEQ int, @p_esdetalle smallint)
returns xml 
--Propósito. Obtiene las retenciones, nodo Retenciones/retencion
--18/12/19 jcf Creación
--
as
begin
	declare @impu xml;
	select @impu = null;

		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
		select @impu = (
			select
				case when @p_esdetalle = 1 then 
					imp.Base 
					else null
				end Base,
				imp.CodImpuesto Impuesto,
				case when @p_esdetalle = 1 then 
					imp.TipoFactor
					else null
				end TipoFactor, 
				case when @p_esdetalle = 1 then 
					imp.TasaOCuota
					else null
				end TasaOCuota, 
				imp.Importe
			from dbo.vwCfdiImpuestosYRetencionesDetalle imp
 			where imp.SOPNUMBE = @p_sopnumbe
			  and imp.LNITMSEQ = @p_LNITMSEQ
              and imp.SOPTYPE = @p_soptype
			  and imp.TXDTLPCT < 0
			FOR XML raw('cfdi:Retencion'), type, root('cfdi:Retenciones')
			)

	return @impu
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiImpuestosRetenidosXML()'
ELSE PRINT 'Error en la creación de la función: fCfdiImpuestosRetenidosXML()'
GO

--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiImpuestosTrasladadosXML') IS NOT NULL
begin
   DROP FUNCTION dbo.fCfdiImpuestosTrasladadosXML
   print 'función fCfdiImpuestosTrasladadosXML eliminada'
end
GO

create function dbo.fCfdiImpuestosTrasladadosXML(@p_soptype smallint, @p_sopnumbe varchar(21), @p_LNITMSEQ int, @p_esdetalle smallint)
returns xml 
--Propósito. Obtiene los impuestos trasladados, nodo Traslados/traslado
--05/01/17 jcf Si el comprobante sólo tiene conceptos exentos, el nodo Traslados a nivel de comprobante no debe existir. GuíaAnexo20.pdf Pag. 32 
--30/05/18 jcf Si el comprobante sólo tiene conceptos exentos, el nodo Traslados a nivel de detalle no debe existir. (m chavez Getty Mex)
--18/12/19 jcf Sustituye las tablas por la vista vwCfdiImpuestosYRetencionesDetalle
--
as
begin
	declare @impu xml, @existeImpuestos numeric(19,6);
	select @impu = null;
	select @existeImpuestos = 1;

	select @existeImpuestos = sum(imp.TXDTLPCT)
    from dbo.vwCfdiImpuestosYRetencionesDetalle imp
	where imp.SOPNUMBE = @p_sopnumbe
    and imp.SOPTYPE = @p_soptype
	and imp.TXDTLPCT >= 0;

    if (isnull(@existeImpuestos, 0) > 0)
	begin
		WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
		select @impu = (
			select
				case when @p_esdetalle = 1 then imp.Base 
					else null
				end Base,
				imp.CodImpuesto Impuesto,
				imp.TipoFactor, 
				imp.TasaOCuota,
				imp.Importe
			from dbo.vwCfdiImpuestosYRetencionesDetalle imp
 			where imp.SOPNUMBE = @p_sopnumbe
			  and imp.LNITMSEQ = @p_LNITMSEQ
			  and imp.SOPTYPE = @p_soptype
			  and imp.TXDTLPCT >= 0
			FOR XML raw('cfdi:Traslado'), type, root('cfdi:Traslados')
			)
	end

	return @impu
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiImpuestosTrasladadosXML()'
ELSE PRINT 'Error en la creación de la función: fCfdiImpuestosTrasladadosXML()'
GO

--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiImpuestosYRetencionesTotales') IS NOT NULL
   DROP FUNCTION dbo.fCfdiImpuestosYRetencionesTotales
GO

create function dbo.fCfdiImpuestosYRetencionesTotales(@p_soptype smallint, @p_sopnumbe varchar(21), @p_LNITMSEQ int, @p_esdetalle smallint)
returns table 
return(

    -- select sum(case when txdtlpct<0 then Importe else 0 end) SumaRetenciones,
    --     sum(case when txdtlpct>=0 then Importe else 0 end) SumaImpuestos
    -- from dbo.vwCfdiImpuestosYRetencionesDetalle
    -- where sopnumbe = @p_sopnumbe
    -- and soptype = @p_soptype
    -- and lnitmseq != 0
	-- and @p_esdetalle = 0

	-- union ALL

    -- select sum(case when txdtlpct<0 then Importe else 0 end) SumaRetenciones,
    --     sum(case when txdtlpct>=0 then Importe else 0 end) SumaImpuestos
    -- from dbo.vwCfdiImpuestosYRetencionesDetalle
    -- where sopnumbe = @p_sopnumbe
    -- and soptype = @p_soptype
    -- and lnitmseq = @p_LNITMSEQ
	-- and @p_esdetalle = 1

    select 
		sum(case when @p_esdetalle = 1 
				then 
					case when txdtlpct<0 and lnitmseq = @p_LNITMSEQ 
						then Importe 
						else 0 
					end
			    else
					case when txdtlpct<0 and lnitmseq != 0
						then Importe
						else 0
					end
			end ) SumaRetenciones,
        sum(case when @p_esdetalle = 1 
				then 
					case when txdtlpct>=0 and lnitmseq = @p_LNITMSEQ 
						then Importe 
						else 0
					end	
				else
					case when txdtlpct>=0 and lnitmseq != 0
						then Importe 
						else 0 
					end
			end) SumaImpuestos
    from dbo.vwCfdiImpuestosYRetencionesDetalle
    where sopnumbe = @p_sopnumbe
    and soptype = @p_soptype

)
GO

IF (@@Error = 0) PRINT 'Creación exitosa de: fCfdiImpuestosYRetencionesTotales()'
ELSE PRINT 'Error en la creación de: fCfdiImpuestosYRetencionesTotales()'
GO

--------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fCfdiNodoImpuestosXML') IS NOT NULL
begin
   DROP FUNCTION dbo.fCfdiNodoImpuestosXML
   print 'función fCfdiNodoImpuestosXML eliminada'
end
GO

create function dbo.fCfdiNodoImpuestosXML(@p_soptype smallint, @p_sopnumbe varchar(21), @p_LNITMSEQ int, @p_esdetalle smallint)
returns xml 
--Propósito. Obtiene los impuestos trasladados y retenidos
--18/12/19 jcf Creación. El orden de los nodos es importante a nivel de detalle y cabecera
--
as
begin

	declare @impu xml;
	select @impu = null;	
	WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/3' as "cfdi")
	select @impu = (
		select 
            case when isnull(totales.SumaImpuestos, 0) = 0 or @p_esdetalle = 1 then null else totales.SumaImpuestos end       'TotalImpuestosTrasladados',
            case when isnull(totales.SumaRetenciones, 0) = 0 or @p_esdetalle = 1 then null else totales.SumaRetenciones end   'TotalImpuestosRetenidos',
			case when @p_esdetalle = 1 then 
	            dbo.fCfdiImpuestosTrasladadosXML(@p_soptype, @p_sopnumbe, @p_LNITMSEQ, @p_esdetalle)
				else
				dbo.fCfdiImpuestosRetenidosXML(@p_soptype, @p_sopnumbe, @p_LNITMSEQ, @p_esdetalle)
			end,
			case when @p_esdetalle = 1 then 
				dbo.fCfdiImpuestosRetenidosXML(@p_soptype, @p_sopnumbe, @p_LNITMSEQ, @p_esdetalle)
				else
	            dbo.fCfdiImpuestosTrasladadosXML(@p_soptype, @p_sopnumbe, @p_LNITMSEQ, @p_esdetalle)
			end
        from dbo.fCfdiImpuestosYRetencionesTotales(@p_soptype, @p_sopnumbe, @p_LNITMSEQ, @p_esdetalle) totales
        where isnull(totales.SumaImpuestos, 0) != 0
        or isnull(totales.SumaRetenciones, 0) != 0
		FOR XML raw('cfdi:Impuestos'), TYPE
	)

	return  @impu

end
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiNodoImpuestosXML()'
ELSE PRINT 'Error en la creación de la función: fCfdiNodoImpuestosXML()'
GO

