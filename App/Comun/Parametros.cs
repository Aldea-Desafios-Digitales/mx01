using System;
using System.Collections.Generic;
using System.Text;
using System.Xml;

namespace Comun
{
    public struct PrmtrsReporte
    {
        private string _nombre;
        private string _tipo;

        public PrmtrsReporte(string nombre, string tipo)
        {
            this._nombre = nombre;
            this._tipo = tipo;
        }

        public string nombre { get { return _nombre; } }
        public string tipo { get { return _tipo; } }
    }

    public struct DireccionesEmail
    {
        private string _mailTo;
        private string _mailCC;
        private string _mailCCO;

        public DireccionesEmail(string mailTo, string mailCC, string mailCCO)
        {
            this._mailTo = mailTo;
            this._mailCC = mailCC;
            this._mailCCO = mailCCO;
        }

        public string mailTo { get { return _mailTo; } set { _mailTo = value; } }
        public string mailCC { get { return _mailCC; } set { _mailCC = value; } }
        public string mailCCO { get { return _mailCCO; } set { _mailCCO = value; } }
    }

    //public struct EstadosPermitidos
    //{
    //    private bool _emite;
    //    private bool _anula;
    //    private bool _imprime;
    //    private bool _publica;
    //    private bool _envia;
    //    public EstadosPermitidos(string emite, string anula, string imprime, string publica, string envia)
    //    {

    //    }
    //}

    public class Parametros
    {
        public string ultimoMensaje = "";
        private string _URLArchivoXSD = "";
        private string _testQR;
        private string _URLArchivoPagosXSD = String.Empty;
        private string _URLArchivoComExtXSD;
        private string _URLArchivoXSLT = "";
        private string _URLConsulta = "";
        private string _URLwebServPAC = "";
        private string _reporteador = "";
        private string _extFactura;
        private string _extCobro;
        private string _extTraslado;
        private string _extDefaultTab="";
        private string _extensionDefault = string.Empty;
        private string _prefijoDefaultFactura = string.Empty;
        private string _rutaReporteCrystal = string.Empty;
        private string _bottomMargin = "0";
        private string _topMargin = "0";
        private string _leftMargin = "0";
        private string _rightMargin = "0";
        private string _rutaReporteSSRS = "";
        private string _SSRSServer = "";
        private List<PrmtrsReporte> _ListaParametrosReporte = new List<PrmtrsReporte>();
        private List<PrmtrsReporte> _ListaParametrosRepSSRS = new List<PrmtrsReporte>();
        private string _servidor = "";
        private string _seguridadIntegrada = "0";
        private string _usuarioSql = "";
        private string _passwordSql = "";
        private string _emite = "0";
        private string _anula = "0";
        private string _imprime = "0";
        private string _publica = "0";
        private string _envia = "0";
        private string _zip = "0";              //default no comprime
        private string _emailSmtp = string.Empty;
        private string _emailPort = string.Empty;
        private string _emailAccount = string.Empty;
        private string _emailUser = string.Empty;
        private string _emailPwd = string.Empty;
        private string _emailSsl = string.Empty;
        private string _replyto = string.Empty;
        private string _emailCarta = string.Empty;
        private string _emailAdjEmite = "na";   //default no aplica
        private string _emailAdjImprm = "na";   //default no aplica
        private string _imprimeEnImpresora = "0";
        private string _nombreImpresora = string.Empty;
        private string _extFacturaExporta = string.Empty;
        private string _prefijoFacturaExporta = string.Empty;
        private Int16 _posicionPrefijoFactura = 3;

        public Parametros()
        {
            try
            {
                XmlDocument listaParametros = new XmlDocument();
                listaParametros.Load(new XmlTextReader("ParametrosCfdi.xml"));
                XmlNodeList listaElementos = listaParametros.DocumentElement.ChildNodes;
                
                foreach (XmlNode n in listaElementos)
                {
                    if (n.Name.Equals("servidor"))
                        this._servidor = n.InnerXml;
                    if (n.Name.Equals("seguridadIntegrada"))
                        this._seguridadIntegrada = n.InnerXml;
                    if (n.Name.Equals("usuariosql"))
                        this._usuarioSql = n.InnerXml;
                    if (n.Name.Equals("passwordsql"))
                        this._passwordSql = n.InnerXml;
                }
            }
            catch (Exception eprm)
            {
                ultimoMensaje = "Contacte al administrador. No se pudo obtener la configuración general. [Parametros()]" + eprm.Message;
            }
        }

        public Parametros(string IdCompannia)
        {
            try
            {
                XmlDocument listaParametros = new XmlDocument();
                listaParametros.Load(new XmlTextReader("ParametrosCfdi.xml"));
                XmlNode elemento = listaParametros.DocumentElement;

                try
                {
                    _URLArchivoXSD = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/URLArchivoXSD/text()").Value;
                    _testQR = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/testQR/text()").Value;
                    _URLArchivoXSLT = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/URLArchivoXSLT/text()").Value;
                    _URLArchivoPagosXSD = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/URLArchivoPagosXSD/text()").Value;
                    _URLConsulta = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/URLConsulta/text()").Value;
                    _URLwebServPAC = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/PAC/urlWebService/text()").Value;
                }
                catch (Exception)
                {
                    ultimoMensaje = "No se pudo obtener alguno de los parámetros: URLArchivoXSD, URLArchivoXSLT, URLArchivoPagosXSD, URLConsulta o PAC/urlWebService en " + IdCompannia + ". [Parametros(Compañía)] ";
                    throw new ArgumentException(ultimoMensaje);
                }

                try
                {
                    _URLArchivoComExtXSD = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/URLArchivoComExtXSD/text()").Value;
                }
                catch (Exception)
                {
                    _URLArchivoComExtXSD = "na";
                    //_URLArchivoComExtXSLT= "na";
                }

                try
                {
                    _emite = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emite/text()").Value;
                    _anula = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/anula/text()").Value;
                    _imprime = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/imprime/text()").Value;
                    _publica = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/publica/text()").Value;
                    _envia = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/envia/text()").Value;
                    _zip = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/zip/text()").Value;
                    _reporteador = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/reporteador/text()").Value;

                }
                catch (Exception)
                {
                    ultimoMensaje = "No se pudo obtener alguno de los parámetros: emite, anula, imprime, publica, envia, zip o reporteador en " + IdCompannia + ". [Parametros(Compañía)] ";
                    throw new ArgumentException(ultimoMensaje);
                }

                try
                {
                    _extFactura = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/reporteExtensiones/Factura/text()").Value;
                    _prefijoFacturaExporta = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/reporteExtensiones/PrefijoFacturaExporta/text()").Value;
                    _extFacturaExporta = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/reporteExtensiones/FacturaExporta/text()").Value;
                    _extCobro = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/reporteExtensiones/Cobro/text()").Value;
                    _extTraslado = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/reporteExtensiones/Traslado/text()").Value;

                }
                catch (Exception)
                {
                    ultimoMensaje = "No se pudo obtener alguno de los parámetros del tag reporteExtensiones: Factura, PrefijoFacturaExporta, FacturaExporta, Cobro o Traslado en " + IdCompannia + ". [Parametros(Compañía)] ";
                    throw new ArgumentException(ultimoMensaje);
                }
                try
                {
                    if (_reporteador.Contains("CRYSTAL"))
                    {
                        _rutaReporteCrystal = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/rutaReporteCrystal[@tipo='default']/Ruta/text()").Value;
                        _bottomMargin = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/rutaReporteCrystal[@tipo='default']/Margenes/bottomMargin/text()").Value;
                        _topMargin = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/rutaReporteCrystal[@tipo='default']/Margenes/topMargin/text()").Value;
                        _leftMargin = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/rutaReporteCrystal[@tipo='default']/Margenes/leftMargin/text()").Value;
                        _rightMargin = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/rutaReporteCrystal[@tipo='default']/Margenes/rightMargin/text()").Value;
                        _imprimeEnImpresora = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/rutaReporteCrystal[@tipo='default']/imprime/text()").Value;
                        _nombreImpresora = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/rutaReporteCrystal[@tipo='default']/nombreImpresora/text()").Value;

                        XmlNodeList listaElementos = listaParametros.DocumentElement.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/rutaReporteCrystal[@tipo='default']").ChildNodes;
                        foreach (XmlNode n in listaElementos)
                        {
                            if (n.Name.Equals("Parametro"))
                            {
                                this._ListaParametrosReporte.Add(new PrmtrsReporte(n.SelectSingleNode("Nombre/text()").Value,
                                                                                    n.SelectSingleNode("Tipo/text()").Value));
                            }
                        }

                    }
                }
                catch (Exception)
                {
                    ultimoMensaje = "No se pudo obtener alguno de los parámetros del tag rutaReporteCrystal: Ruta, Margenes/bottomMargin, Margenes/topMargin, Margenes/leftMargin, Margenes/rightMargin, imprime, nombreImpresora o Parametro<Nombre, Tipo> en " + IdCompannia + ". [Parametros(Compañía)] ";
                    throw new ArgumentException(ultimoMensaje);
                }

                try
                {
                    if (_reporteador.Contains("SSRS"))
                    {
                        _rutaReporteSSRS = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/ReporteSSRS[@tipo='default']/Ruta/text()").Value;
                        _SSRSServer = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/ReporteSSRS[@tipo='default']/SSRSServer/text()").Value;

                        XmlNodeList listaElementos = listaParametros.DocumentElement.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/ReporteSSRS[@tipo='default']").ChildNodes;
                        foreach (XmlNode n in listaElementos)
                        {
                            if (n.Name.Equals("Parametro"))
                            {
                                this._ListaParametrosRepSSRS.Add(new PrmtrsReporte(n.SelectSingleNode("Nombre/text()").Value,
                                                                                    n.SelectSingleNode("Tipo/text()").Value));
                            }
                        }
                    }
                }
                catch (Exception)
                {
                    ultimoMensaje = "No se pudo obtener alguno de los parámetros del tag ReporteSSRS: Ruta, SSRSServero Parametro<Nombre, Tipo> en " + IdCompannia + ". [Parametros(Compañía)] ";
                    throw new ArgumentException(ultimoMensaje);
                }
                try
                {
                    _emailSmtp = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/smtp/text()").Value;
                    _emailPort = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/puerto/text()").Value;
                    _emailAccount = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/cuenta/text()").Value;
                    _emailUser = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/usuario/text()").Value;
                    _emailPwd = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/clave/text()").Value;
                    _emailSsl = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/ssl/text()").Value;
                    _replyto = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/replyto/text()").Value;
                    _emailCarta = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/carta/text()").Value;
                    _emailAdjEmite = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/adjuntoEmite/text()").Value;
                    _emailAdjImprm = elemento.SelectSingleNode("//compannia[@bd='" + IdCompannia + "']/emailSetup/adjuntoImprime/text()").Value;
                }
                catch (Exception)
                {
                    _emailPwd = string.Empty;
                }


            }
            catch (Exception eprm)
            {
                ultimoMensaje = "Contacte al administrador. Error en el archivo de configuración de la compañía " + IdCompannia + ". [Parametros(Compañía)] " + eprm.Message;
            }
        }

        public string servidor
        {
            get { return _servidor; }
            set { _servidor = value; }
        }

        public bool seguridadIntegrada
        {
            get 
            { 
                return _seguridadIntegrada.Equals("1"); 
            }
            set 
            { 
                if (value)
                    _seguridadIntegrada = "1"; 
                else
                    _seguridadIntegrada = "0"; 
            }
        }

        public string usuarioSql
        {
            get { return _usuarioSql; }
            set{ _usuarioSql = value;}
        }

        public string passwordSql
        {
            get { return _passwordSql; }
            set {_passwordSql=value;}
        }

        public string URLArchivoXSD
        {
            get { return _URLArchivoXSD; }
            set { _URLArchivoXSD = value; }
        }

        public string URLArchivoPagosXSD
        {
            get
            {
                return _URLArchivoPagosXSD;
            }

            set
            {
                _URLArchivoPagosXSD = value;
            }
        }

        public string URLArchivoComExtXSD
        {
            get
            {
                return _URLArchivoComExtXSD;
            }

            set
            {
                _URLArchivoComExtXSD = value;
            }
        }

        public string URLArchivoXSLT
        {
            get { return _URLArchivoXSLT; }
            set { _URLArchivoXSLT = value; }
        }

        //public string URLArchivoPagosXSLT
        //{
        //    get
        //    {
        //        return _URLArchivoPagosXSLT;
        //    }

        //    set
        //    {
        //        _URLArchivoPagosXSLT = value;
        //    }
        //}

        //public string URLArchivoComExtXSLT
        //{
        //    get
        //    {
        //        return _URLArchivoComExtXSLT;
        //    }

        //    set
        //    {
        //        _URLArchivoComExtXSLT = value;
        //    }
        //}

        public string URLConsulta
        {
            get
            {
                return _URLConsulta;
            }

            set
            {
                _URLConsulta = value;
            }
        }

        public string URLwebServPAC
        {
            get { return _URLwebServPAC; }
            set { _URLwebServPAC = value; }
        }

        public string reporteador
        {
            get { return _reporteador; }
            set { _reporteador = value; }
        }

        public string ExtDefault
        {
            get
            {
                return _extDefaultTab;
            }

            set
            {
                string _ext = String.Empty;
                switch (value)
                {
                    case "tabFacturas":
                        _ext = _extFactura == null ? String.Empty : _extFactura;
                        break;
                    case "tabCobros":
                        _ext = _extCobro == null ? String.Empty : _extCobro;
                        break;
                    case "tabTraslados":
                        _ext = _extTraslado == null ? String.Empty : _extTraslado;
                        break;
                    default:
                        _ext = String.Empty;
                        break;
                }
                _extensionDefault = _ext;
                _extDefaultTab = value;
            }
        }

        public string ExtFactura
        {
            get
            {
                return _extFactura;
            }

            set
            {
                _extFactura = value;
            }
        }

        public string ExtCobro
        {
            get
            {
                return _extCobro;
            }

            set
            {
                _extCobro = value;
            }
        }

        public string ExtTraslado
        {
            get
            {
                return _extTraslado;
            }

            set
            {
                _extTraslado = value;
            }
        }

        public string rutaReporteCrystal
        {
            get {
                return _rutaReporteCrystal + _extensionDefault;
            }
            set { _rutaReporteCrystal = value; }

        }

        public int bottomMargin
        {
            get
            {
               return Convert.ToInt32(_bottomMargin); 
            }
        }

        public int topMargin
        {
            get
            {
               return Convert.ToInt32(_topMargin);
            }
        }

        public int leftMargin
        {
            get { 
                return Convert.ToInt32(_leftMargin); 
            }
        }

        public int rightMargin
        {
            get { 
                return Convert.ToInt32(_rightMargin); 
            }
        }

        public bool ImprimeEnImpresora
        {
            get
            {
                return _imprimeEnImpresora.Equals("1");
            }

            set
            {
                if (value)
                    _imprimeEnImpresora = "1";
                else
                    _imprimeEnImpresora = "0";
            }
        }

        public string NombreImpresora
        {
            get
            {
                return _nombreImpresora;
            }

            set
            {
                _nombreImpresora = value;
            }
        }
        
        public string rutaReporteSSRS
        {
            get
            {
                return _rutaReporteSSRS + _extensionDefault;
            }
            set { _rutaReporteSSRS = value; }
        }

        public string SSRSServer
        {
            get { return _SSRSServer; }
            set { _SSRSServer = value; }
        }

        public List<PrmtrsReporte> ListaParametrosReporte
        {
            get { return _ListaParametrosReporte; }
        }

        public List<PrmtrsReporte> ListaParametrosRepSSRS
        {
            get { return _ListaParametrosRepSSRS; }
        }

        public int intEstadosPermitidos
        {
            get
            {
                return
                        Convert.ToInt32(_emite) +
                    2 * Convert.ToInt32(_anula) +
                    4 * Convert.ToInt32(_imprime) +
                    8 * Convert.ToInt32(_publica) +
                    16 * Convert.ToInt32(_envia);
            }
        }

        public int intEstadoCompletado
        {
            get
            {
                return
                        Convert.ToInt32(_emite) +
                    2 * 0 +
                    4 * Convert.ToInt32(_imprime) +
                    8 * Convert.ToInt32(_publica) +
                    16 * Convert.ToInt32(_envia);
            }
        }
        public bool emite
        {
            get { return _emite.Equals("1"); }
        }

        public bool anula
        {
            get { return _anula.Equals("1"); }
        }

        public bool imprime
        {
            get { return _imprime.Equals("1"); }
        }

        public bool publica
        {
            get { return _publica.Equals("1"); }
        }

        public bool envia
        {
            get { return _envia.Equals("1"); }
        }

        public bool zip
        {
            get { return _zip.Equals("1"); }
        }

        public string tipoDoc
        {
            get { return "FACTURA"; }
        }

        public string emailSmtp
        {
            get { return _emailSmtp; }
        }

        public int emailPort
        {
            get { return Convert.ToInt32( _emailPort); }
        }

        public string emailUser
        {
            get { return _emailUser; }
        }

        public string emailPwd
        {
            get { return _emailPwd; }
        }

        public string emailCarta
        {
            get { return _emailCarta; }
        }

        public string emailAccount
        {
            get { return _emailAccount; }
        }

        public bool emailSsl
        {
            get { return _emailSsl.ToLower().Equals("true"); }
        }

        public string replyto
        {
            get { return _replyto; }
        }

        public string emailAdjEmite
        {
            get { return _emailAdjEmite; }
        }

        public string emailAdjImprm
        {
            get { return _emailAdjImprm; }
        }

        public string PrefijoDefaultFactura
        {
            get
            {
                return _prefijoDefaultFactura;
            }

            set
            {
                if (_extDefaultTab.Equals("tabFacturas"))
                {
                    _extensionDefault = value == _prefijoFacturaExporta ? _extFacturaExporta : _extFactura;
                }
                _prefijoDefaultFactura = value;
            }
        }

        public string PrefijoFacturaExporta
        {
            get
            {
                return _prefijoFacturaExporta;
            }

            set
            {
                _prefijoFacturaExporta = value;
            }
        }

        public short PosicionPrefijoFactura
        {
            get
            {
                return _posicionPrefijoFactura;
            }

            set
            {
                _posicionPrefijoFactura = value;
            }
        }

        public string TestQR { get => _testQR; set => _testQR = value; }
    }
}
