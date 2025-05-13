
use arg10
go
--Reporte de impresión de factura
grant select on dbo.IMPRIME_COMPROBANTE_ELECTRONICO to rol_cfdigital, dyngrp;


use dynamics
go
grant execute on fncNUMLET to rol_cfdigital, dyngrp;

grant select on SY01500 to rol_cfdigital, dyngrp;
