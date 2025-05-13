IF OBJECT_ID ('dbo.fCfdiObtieneUUIDDeSOP') IS NOT NULL
   DROP FUNCTION dbo.fCfdiObtieneUUIDDeSOP
GO

create function dbo.fCfdiObtieneUUIDDeSOP(@SOPTYPE smallint, @SOPNUMBE varchar(21))
returns table
as
--Propósito. Devuelve el UUID de una factura sop. Este dato debe estar en el campo nota.
--Requisitos. Se debería usar en caso que la factura fue emitida en gestiones anteriores por otro PAC
--02/07/19 jcf Creación 
--
return
(
	select substring(ni.txtfield, 1, 40) uuid, rmx.voidstts
		from dbo.sop30200 rmx
		inner join sy03900 ni
			on ni.noteindx = rmx.noteindx
	where rmx.soptype = 3
		and rmx.sopnumbe = @SOPNUMBE
)
go


IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiObtieneUUIDDeSOP()'
ELSE PRINT 'Error en la creación de la función: fCfdiObtieneUUIDDeSOP()'
GO

-------------------------------------------------------------------------------------------------------------
--select *
--from dbo.fCfdiObtieneUUIDDeSOP(3, '00000002')

