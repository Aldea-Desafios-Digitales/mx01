use LA103;

IF OBJECT_ID ('dbo.fnCfdiPolarisTenantReference') IS NOT NULL
   DROP FUNCTION dbo.fnCfdiPolarisTenantReference
GO

create function dbo.fnCfdiPolarisTenantReference(@LeaseNo char(21))
returns table
as
--Propósito. Obtiene tenant reference
--Requisitos. La bd Polaris contiene datos del tenant
--Utilizado por. Reporte de impresión de factura para GTP (LA103, LA124)
--2/9/13 jcf Creación
return (
	select bt.LeaseNo, tl.TenantRefAccountingID
	from polaris.dbo.TenantLeases tl
	inner join polaris.dbo.BaseTenantLeases bt
		   on bt.BaseTenantLeaseGuid = tl.BaseTenantLeaseGuid
		   AND bt.CopyOfGuid IS NULL AND tl.CopyOfGuid IS NULL 
	where bt.LeaseNo = case when isnumeric(@LeaseNo)=1 then  convert(int, @LeaseNo) else 0 end 
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fnCfdiPolarisTenantReference()'
ELSE PRINT 'Error en la creación de la función: fnCfdiPolarisTenantReference()'
GO

grant select on fnCfdiPolarisTenantReference to dyngrp, rol_cfdigital
go

-------------------------------------------------------------------------------------------
--*****************************************************************************************
use LA124;

IF OBJECT_ID ('dbo.fnCfdiPolarisTenantReference') IS NOT NULL
   DROP FUNCTION dbo.fnCfdiPolarisTenantReference
GO

create function dbo.fnCfdiPolarisTenantReference(@LeaseNo char(21))
returns table
as
--Propósito. Obtiene tenant reference
--Requisitos. La bd Polaris contiene datos del tenant
--Utilizado por. Reporte de impresión de factura para GTP (LA103, LA124)
--2/9/13 jcf Creación
return (
	select bt.LeaseNo, tl.TenantRefAccountingID
	from polaris.dbo.TenantLeases tl
	inner join polaris.dbo.BaseTenantLeases bt
		   on bt.BaseTenantLeaseGuid = tl.BaseTenantLeaseGuid
		   AND bt.CopyOfGuid IS NULL AND tl.CopyOfGuid IS NULL 
	where bt.LeaseNo = case when isnumeric(@LeaseNo)=1 then  convert(int, @LeaseNo) else 0 end 
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fnCfdiPolarisTenantReference()'
ELSE PRINT 'Error en la creación de la función: fnCfdiPolarisTenantReference()'
GO

grant select on fnCfdiPolarisTenantReference to dyngrp, rol_cfdigital
go
