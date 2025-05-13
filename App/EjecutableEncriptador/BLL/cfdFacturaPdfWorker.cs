using System;
using System.Collections.Generic;
using System.Text;
using System.ComponentModel;

using Comun;
using EjecutableEncriptador;
using MaquinaDeEstados;

namespace cfd.FacturaElectronica
{
    class cfdFacturaPdfWorker : BackgroundWorker
    {
        private Parametros _Param;
        private ConexionAFuenteDatos _Conex;
        //private string msj;

        public cfdFacturaPdfWorker(ConexionAFuenteDatos Conex, Parametros Param)
        {
            WorkerReportsProgress = true;
            WorkerSupportsCancellation = true;
            _Param = Param;
            _Conex = Conex;
        }

        /// <summary>
        /// Ejecuta la generación de pdfs en un thread independiente
        /// </summary>
        /// <param name="e">trxVentas</param>
        protected override void OnDoWork(DoWorkEventArgs e)
        {
            string msj = "";
            try
            {
                ReportProgress(0, "Iniciando proceso...\r\n");
                object[] args = e.Argument as object[];
                vwCfdTransaccionesDeVenta trxVenta = (vwCfdTransaccionesDeVenta)args[0];
                int i = 1; int errores = 0;
                string eBinario = "";
                string eBase = "";
                cfdReglasFacturaXml DocumentoEmitido = null;
                ReglasME maquina = new ReglasME(_Param);

                trxVenta.Rewind();                   //move to first record
                do
                {
                    _Param.PrefijoDefaultFactura = trxVenta.Sopnumbe.Substring(_Param.PosicionPrefijoFactura, 1);
                    DocumentoEmitido = new cfdReglasFacturaXml(_Conex, _Param);     //log de facturas xml emitidas y anuladas
                    if (CancellationPending) { e.Cancel = true; return; }
                    msj = "";
                    if (maquina.ValidaTransicion(_Param.tipoDoc, "IMPRIME PDF", trxVenta.EstadoActual, "impreso"))
                        if (trxVenta.Voidstts == 0 && trxVenta.EstadoContabilizado.Equals("contabilizado"))  //no anulado y contabilizado
                        {
                            if (!_Param.emite && !maquina.impreso(trxVenta.EstadoActual))
                                eBase = "emitido";
                            else
                                eBase = "impreso";

                            //Si no emite y es primera impresión: guardar el archivo pdf y registrar el log: emitido
                            //sino: registrar el log impreso
                            if (DocumentoEmitido.AlmacenaEnRepositorio(trxVenta, eBase, maquina.eBinarioNuevo, maquina.EnLetras(maquina.eBinarioNuevo)))
                            {
                                eBinario = maquina.eBinarioNuevo;
                            }
                            else
                            {
                                eBinario = maquina.eBinActualConError;
                                errores++;
                            }

                            if (_Param.emite && !maquina.impreso(trxVenta.EstadoActual))
                                DocumentoEmitido.ActualizaFacturaEmitida(trxVenta.Soptype, trxVenta.Sopnumbe, _Conex.Usuario, "emitido", "emitido",
                                                                    eBinario, maquina.EnLetras(eBinario) + DocumentoEmitido.ultimoMensaje);

                        }
                        else
                            msj = "No se puede generar porque no está Contabilizado o está Anulado.";
                    ReportProgress(i * 100 / trxVenta.RowCount, "Doc:" + trxVenta.Sopnumbe + " " + DocumentoEmitido.ultimoMensaje + maquina.ultimoMensaje + msj + "\r\n");
                    i++;
                } while (trxVenta.MoveNext() && errores < 10);
                e.Result = "Generación de Pdfs finalizado! \r\n";
                ReportProgress(100, "");

            }
            catch (Exception xw)
            {
                string imsj = xw.InnerException == null ? "" : xw.InnerException.ToString();
                msj = xw.Message + " " + imsj + "\r\n" + xw.StackTrace;
            }
            finally
            {
                ReportProgress(100, msj);
            }
            e.Result = "Proceso finalizado! \r\n ";
            ReportProgress(100, "");
        }
    }
}
