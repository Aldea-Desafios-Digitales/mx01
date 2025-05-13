--Reporte de impresión de factura, cobros y traslados
grant select on dbo.TII_SOPINVOICE to rol_cfdigital, dyngrp;
grant select on dbo.vwRmImprimeCobros to  rol_cfdigital, dyngrp;
grant select on dbo.vwCfdiTrasladoParaReporte to  rol_cfdigital, dyngrp;
go

--vista de factura de gp express
IF (OBJECT_ID ('dbo.GXPR_FC_ELECTRONICA', 'V') IS not NULL)
	grant select on GXPR_FC_ELECTRONICA to rol_cfdigital;
go
