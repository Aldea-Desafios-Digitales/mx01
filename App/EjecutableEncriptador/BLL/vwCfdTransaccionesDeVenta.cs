using System;
using System.Collections.Generic;
using System.Text;

namespace EjecutableEncriptador
{
    class vwCfdTransaccionesDeVenta : vwCfdiTransaccionesDeVenta
    {

        public vwCfdTransaccionesDeVenta(string connstr, string nombreVista)
        {
            this.ConnectionString = connstr;
            this.QuerySource = nombreVista;
            this.MappingName = nombreVista;

            //this.QuerySource = "vwCfdiTransaccionesDeVenta";
            //this.MappingName = "vwCfdiTransaccionesDeVenta";
        }

    }
}
