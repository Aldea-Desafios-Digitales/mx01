using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Xsl;

using Comun;
using EjecutableEncriptador;
using Encriptador;
using MaquinaDeEstados;
using BarCodeInterface;

namespace cfd.FacturaElectronica
{
    public class CfdiUUID
    {
        String sopnumbe;
        String uuid;
        String sello;

        public string Sopnumbe
        {
            get
            {
                return sopnumbe;
            }

            set
            {
                sopnumbe = value;
            }
        }

        public string Uuid
        {
            get
            {
                return uuid;
            }

            set
            {
                uuid = value;
            }
        }

        public string Sello
        {
            get
            {
                return sello;
            }

            set
            {
                sello = value;
            }
        }
    }
    public class test
    {
        private Parametros _Param;
        private ConexionAFuenteDatos _Conex;
        public string ultimoMensaje = "";
        vwCfdTransaccionesDeVenta trxVenta;

        internal vwCfdTransaccionesDeVenta TrxVenta
        {
            get
            {
                return trxVenta;
            }

            set
            {
                trxVenta = value;
            }
        }

        public test(ConexionAFuenteDatos Conex, Parametros Param)
        {
            _Param = Param;
            _Conex = Conex;
        }

        /// <summary>
        /// Ejecuta la generación de archivos xml y pdf en un thread independiente
        /// </summary>
        /// <param name="e">trxVentas</param>
        public void GeneraQRCode()
        {
            //try
            //{
                String msj = String.Empty;
                trxVenta.Rewind();                                                          //move to first record

                int errores = 0; int i = 1;

                //List<CfdiUUID> cfdi = new List<CfdiUUID>();
                //cfdi.Add(new CfdiUUID() { Sopnumbe = "00000052", Uuid = "0A0661F7-BC1A-4DA7-94C2-0A153E2C65B0", Sello = "X1oRzUkOtEOFDu7XB9aslUTj1Xz5OO0bmodYEiSBGw/AXPTqCqks65gOtYTswMS9bpsLrYG8iqM0khfTrsHnlLETQ7/UfJ+et1926HxxzkgJl8YkOksljYzkvP2E1XQaRmm3+EvlGvsDY68G1OD0RC93F+z5ki6DLwEi47sT+NvVftWPmbINckyBYzOzux0P4msILsI+K/6PZIoRfZqBC3LWdDi4zKSBvMycNm+UisL/M6pNVB8R2QPKTV/zw7cZJh6Bw5oOalrJXOrmxrsKM0G7WS9eORb/h6a7pXKz2qQrQz7y78zg91sh2tRiNSsN6XZ6gNpyRlD7gsXwqhCveg==" });

                do
                {
                    msj = String.Empty;
                    string nomArchivo = Utiles.FormatoNombreArchivo(trxVenta.Docid + trxVenta.Sopnumbe + "_" + trxVenta.s_CUSTNMBR, trxVenta.s_NombreCliente, 20);
                    try
                    {
                            string nomArchivoJpg = nomArchivo + ".jpg";
                            string nomArchivoXml = nomArchivo + ".xml";

                            //var comp = cfdi.Where(x => x.Sopnumbe == trxVenta.Sopnumbe).First();

                            //string strXml = System.IO.Path.Combine( trxVenta.Mensaje.Remove(0 ,14), ".xml");
                            string strXml =  System.IO.Path.Combine(TrxVenta.RutaXml, nomArchivoXml);
                            XmlDocument docXml = new XmlDocument();
                            docXml.Load(strXml);
                            XmlNamespaceManager nsmgr = new XmlNamespaceManager(docXml.NameTable);
                            nsmgr.AddNamespace("tfd", "http://www.sat.gob.mx/TimbreFiscalDigital");
                            nsmgr.AddNamespace("cfdi", "http://www.sat.gob.mx/cfd/3");

                            string sello = docXml.SelectSingleNode("/cfdi:Comprobante/@Sello", nsmgr).Value;
                            string uuid = docXml.SelectSingleNode("/cfdi:Comprobante/cfdi:Complemento/tfd:TimbreFiscalDigital/@UUID", nsmgr).Value;

                            ICodigoDeBarras cbb = new CodigoDeBarras();
                            cbb.GeneraCodigoDeBarras(string.Empty, 
                                                    _Param.URLConsulta + "?&id="+uuid+"&re=" + trxVenta.Rfc + "&rr=" + trxVenta.IdImpuestoCliente.Trim() + "&tt=" + trxVenta.Total.ToString() + "&fe="+ Utiles.Derecha(sello, 8)
                                                    , trxVenta.RutaXml + "cbb\\"+ nomArchivoJpg);
                        }
                    catch (Exception lo)
                    {
                        throw new ArgumentNullException("No se puede procesar el archivo: " + nomArchivo + " Verifique la ruta: " + trxVenta.RutaXml);
                        //string imsj = lo.InnerException == null ? "" : lo.InnerException.ToString();
                        //msj = lo.Message + " " + imsj + Environment.NewLine;
                        //errores++;
                    }
                //finally
                //{
                //    ReportProgress(i * 100 / trxVenta.RowCount, "Doc:" + trxVenta.Sopnumbe + " " + msj.Trim() + Environment.NewLine);
                //    i++;
                //}
            } while (trxVenta.MoveNext() && errores < 10);
            //}
            //catch (Exception xw)
            //{
            //    string imsj = xw.InnerException == null ? "" : xw.InnerException.ToString();
            //    this.ultimoMensaje = xw.Message + " " + imsj + "\r\n" + xw.StackTrace;
            //}
            //finally
            //{
            //    //ReportProgress(100, ultimoMensaje);
            //}
        }


    }
}
