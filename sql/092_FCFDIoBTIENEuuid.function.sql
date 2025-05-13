IF OBJECT_ID ('dbo.fCfdiObtieneUUID') IS NOT NULL
   DROP FUNCTION dbo.fCfdiObtieneUUID
GO

create function dbo.fCfdiObtieneUUID(@soptype smallint, @sopnumbe varchar(21))
returns table
as
--Propósito. Devuelve el UUID de un cfdi
--Requisitos. 
--13/10/17 jcf Creación 
--16/01/18 jcf Agrega montoActualOriginal
--
return
(
	select tv.docid, dx.uuid, tv.voidstts, dx.FormaPago, tv.montoActualOriginal
	from dbo.vwCfdiSopTransaccionesVenta tv
		left join dbo.vwCfdiDatosDelXml dx
		on dx.soptype = tv.SOPTYPE
		and dx.sopnumbe = tv.sopnumbe
		and dx.estado = 'emitido'
	where tv.soptype = @soptype
	and tv.sopnumbe = @sopnumbe
)
go


IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiObtieneUUID()'
ELSE PRINT 'Error en la creación de la función: fCfdiObtieneUUID()'
GO

-------------------------------------------------------------------------------------------------------------
--select *
--from dbo.fCfdiObtieneUUID(3, '00000002')

