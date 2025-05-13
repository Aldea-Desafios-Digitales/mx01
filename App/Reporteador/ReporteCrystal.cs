using System;
using System.Collections.Generic;
using System.Text;
using CrystalDecisions.CrystalReports.Engine;
using CrystalDecisions.Shared;
using System.IO;
using Comun;

namespace Reporteador
{
    public class ReporteCrystal
    {
        public string ultimoMensaje = "";
        public int numError = 0;
        private string _SrvrName = "";
        private string _DbName = "";
        private string _IdUsuario = "";
        private string _Password = "";
        private bool _IntegratedSecurity = false;
        private Parametros _param;

        public ReporteCrystal(ConexionAFuenteDatos Conexion, Parametros Param)
        {
            _SrvrName = Conexion.ServerAddress;
            _DbName = Conexion.Intercompany;
            _IdUsuario = Conexion.Usuario;
            _Password = Conexion.Password;
            _IntegratedSecurity = Conexion.IntegratedSecurity;
            _param = Param;
        }

        /// <summary>
        /// Guarda el archivo pdf usando Crystal reports.
        /// Deprecated.
        /// </summary>
        /// <param name="Param"></param>
        /// <param name="FolioDesde"></param>
        /// <param name="FolioHasta"></param>
        /// <param name="Tabla"></param>
        /// <param name="Comprobante"></param>
        /// <param name="RutaPDF">Ruta que incluye el nombre del archivo.</param>
        /// <returns></returns>
        public bool GuardaDocumentoEnPDF(string FolioDesde, string FolioHasta, string Tabla, int Comprobante, string RutaPDF)
        {
            ultimoMensaje = "";
            numError = 0;
            try
            {
                ReportDocument cryRpt = new ReportDocument();
                TableLogOnInfos crtableLogoninfos = new TableLogOnInfos();
                TableLogOnInfo crtableLogoninfo = new TableLogOnInfo();
                ConnectionInfo crConnectionInfo = new ConnectionInfo();
                Tables CrTables;
                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                cryRpt.Load(_param.rutaReporteCrystal);

                //Conecta la base de datos
                crConnectionInfo.IntegratedSecurity = _IntegratedSecurity;
                crConnectionInfo.ServerName = _SrvrName;
                crConnectionInfo.DatabaseName = _DbName;
                if (!_IntegratedSecurity)
                {
                    crConnectionInfo.UserID = _IdUsuario;
                    crConnectionInfo.Password = _Password;
                }
                CrTables = cryRpt.Database.Tables;
                foreach (CrystalDecisions.CrystalReports.Engine.Table CrTable in CrTables)
                {
                    crtableLogoninfo = CrTable.LogOnInfo;
                    crtableLogoninfo.ConnectionInfo = crConnectionInfo;
                    CrTable.ApplyLogOnInfo(crtableLogoninfo);
                }

                //Envía parámetros al reporte
                crParameterDiscreteValue.Value = FolioDesde;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["Desde Numero"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;
                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                crParameterDiscreteValue.Value = FolioHasta;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["Hasta Numero"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;
                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                crParameterDiscreteValue.Value = Tabla;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["sTabla"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;
                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                crParameterDiscreteValue.Value = Comprobante;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["Comprobante"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;
                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);
                
                //crystalReportViewer1.ReportSource = cryRpt;
                //crystalReportViewer1.Refresh();

                //Convierte a pdf
                ExportOptions CrExportOptions;
                DiskFileDestinationOptions CrDiskFileDestinationOptions = new DiskFileDestinationOptions();
                PdfRtfWordFormatOptions CrFormatTypeOptions = new PdfRtfWordFormatOptions();
                CrDiskFileDestinationOptions.DiskFileName = RutaPDF;
                CrExportOptions = cryRpt.ExportOptions;
                {
                    CrExportOptions.ExportDestinationType = ExportDestinationType.DiskFile;
                    CrExportOptions.ExportFormatType = ExportFormatType.PortableDocFormat;
                    CrExportOptions.DestinationOptions = CrDiskFileDestinationOptions;
                    CrExportOptions.FormatOptions = CrFormatTypeOptions;
                }
                cryRpt.Export();
                return true;
            }
            catch (DirectoryNotFoundException)
            {
                ultimoMensaje = "Verifique la existencia de la ruta indicada en la configuración de Ruta de archivos Xml. [GuardaDocumentoEnPDF] La ruta no pudo ser encontrada: " + RutaPDF;
                numError++;
                return false;
            }
            catch (IOException)
            {
                ultimoMensaje = "Verifique permisos de escritura en: " + RutaPDF + ". No se pudo guardar el archivo xml ni registrar el documento en la bitácora. [GuardaDocumentoEnPDF]";
                numError++;
                return false;
            }
            catch (Exception exPdf)
            {
                if (exPdf.Message.Contains("denied"))
                    ultimoMensaje = "Elimine el archivo antes de volver a generar uno nuevo. Luego vuelva a intentar. [GuardaDocumentoEnPDF] " + exPdf.Message;
                else
                    ultimoMensaje = "Advertencia, no se guardó el reporte PDF. [GuardaDocumentoEnPDF] " + exPdf.Message;
                numError++;
                return false;
            }
        }

        /// <summary>
        /// Guarda el archivo pdf usando Crystal reports.
        /// </summary>
        /// <param name="Param"></param>
        /// <param name="ValoresParametros">Datos del comprobante que son los parámetros del reporte. El orden es importante.</param>
        /// <param name="RutaPDF">Ruta donde se guarda el pdf. Incluye el nombre del archivo.</param>
        /// <returns></returns>
        public bool GuardaDocumentoEnPDF(List<string> ValoresParametros, string RutaPDF)
        {
            ultimoMensaje = "";
            numError = 0;
            try
            {
                ReportDocument cryRpt = new ReportDocument();
                TableLogOnInfos crtableLogoninfos = new TableLogOnInfos();
                TableLogOnInfo crtableLogoninfo = new TableLogOnInfo();
                ConnectionInfo crConnectionInfo = new ConnectionInfo();
                Tables CrTables;
                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();
                PageMargins margins;

                cryRpt.Load(_param.rutaReporteCrystal);

                //Conecta la base de datos
                crConnectionInfo.IntegratedSecurity = _IntegratedSecurity;
                crConnectionInfo.ServerName = _SrvrName;
                crConnectionInfo.DatabaseName = _DbName;
                if (!_IntegratedSecurity)
                {
                    crConnectionInfo.UserID = _IdUsuario;
                    crConnectionInfo.Password = _Password;
                }
                CrTables = cryRpt.Database.Tables;
                foreach (CrystalDecisions.CrystalReports.Engine.Table CrTable in CrTables)
                {
                    crtableLogoninfo = CrTable.LogOnInfo;
                    crtableLogoninfo.ConnectionInfo = crConnectionInfo;
                    CrTable.ApplyLogOnInfo(crtableLogoninfo);
                }
                int i = 0;
                foreach (PrmtrsReporte pr in _param.ListaParametrosReporte)
                {
                    //Envía parámetros al reporte
                    crParameterDiscreteValue.Value = ValoresParametros[i];                      //valor
                    crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                    crParameterFieldDefinition = crParameterFieldDefinitions[pr.nombre.Trim()]; //nombre parámetro
                    crParameterValues = crParameterFieldDefinition.CurrentValues;
                    crParameterValues.Clear();
                    crParameterValues.Add(crParameterDiscreteValue);
                    crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);
                    i++;
                }

                //Define márgenes si existen parámetros
                if (_param.bottomMargin >= 0 && _param.topMargin >= 0 && _param.leftMargin >= 0 && _param.rightMargin >= 0)
                {
                    margins = cryRpt.PrintOptions.PageMargins;
                    margins.bottomMargin = _param.bottomMargin;
                    margins.topMargin = _param.topMargin;
                    margins.leftMargin = _param.leftMargin;
                    margins.rightMargin = _param.rightMargin;
                    cryRpt.PrintOptions.ApplyPageMargins(margins);
                }

                //Convierte a pdf
                ExportOptions CrExportOptions;
                DiskFileDestinationOptions CrDiskFileDestinationOptions = new DiskFileDestinationOptions();
                PdfRtfWordFormatOptions CrFormatTypeOptions = new PdfRtfWordFormatOptions();
                CrDiskFileDestinationOptions.DiskFileName = RutaPDF;
                CrExportOptions = cryRpt.ExportOptions;
                {
                    CrExportOptions.ExportDestinationType = ExportDestinationType.DiskFile;
                    CrExportOptions.ExportFormatType = ExportFormatType.PortableDocFormat;
                    CrExportOptions.DestinationOptions = CrDiskFileDestinationOptions;
                    CrExportOptions.FormatOptions = CrFormatTypeOptions;
                }
                cryRpt.Export();
                return true;
            }
            catch (DirectoryNotFoundException)
            {
                ultimoMensaje = "Verifique la existencia de la ruta indicada en la configuración de Ruta de archivos Xml. [GuardaDocumentoEnPDF] La ruta no pudo ser encontrada: " + RutaPDF;
                numError++;
                return false;
            }
            catch (IOException)
            {
                ultimoMensaje = "Verifique permisos de escritura en: " + RutaPDF + ". No se pudo guardar el archivo xml ni registrar el documento en la bitácora. [GuardaDocumentoEnPDF]";
                numError++;
                return false;
            }
            catch (Exception exPdf)
            {
                if (exPdf.Message.Contains("denied"))
                    ultimoMensaje = "Elimine el archivo antes de volver a generar uno nuevo. Luego vuelva a intentar. [GuardaDocumentoEnPDF] " + exPdf.Message;
                else
                    ultimoMensaje = "Advertencia, no se guardó el reporte PDF. [GuardaDocumentoEnPDF] " + exPdf.Message;
                numError++;
                return false;
            }
        }

        public ReportDocument MuestraEnVisor(string FolioDesde, string FolioHasta, string Tabla, int Comprobante)
        {
            ultimoMensaje = "";
            numError = 0;
            //Obtiene ruta del reporte crystal
            //Parametros Param = new Parametros(_DbName);
            //if (!_param.ultimoMensaje.Equals(string.Empty))
            //{
            //    ultimoMensaje = _param.ultimoMensaje;
            //    return null;
            //}

            try
            {
                ReportDocument cryRpt = new ReportDocument();
                TableLogOnInfos crtableLogoninfos = new TableLogOnInfos();
                TableLogOnInfo crtableLogoninfo = new TableLogOnInfo();
                ConnectionInfo crConnectionInfo = new ConnectionInfo();
                Tables CrTables;
                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                cryRpt.Load(_param.rutaReporteCrystal);

                //Conecta la base de datos
                crConnectionInfo.IntegratedSecurity = _IntegratedSecurity;
                crConnectionInfo.ServerName = _SrvrName;
                crConnectionInfo.DatabaseName = _DbName;
                if (!_IntegratedSecurity)
                {
                    crConnectionInfo.UserID = _IdUsuario;
                    crConnectionInfo.Password = _Password;
                }
                CrTables = cryRpt.Database.Tables;
                foreach (CrystalDecisions.CrystalReports.Engine.Table CrTable in CrTables)
                {
                    crtableLogoninfo = CrTable.LogOnInfo;
                    crtableLogoninfo.ConnectionInfo = crConnectionInfo;
                    CrTable.ApplyLogOnInfo(crtableLogoninfo);
                }

                //Envía parámetros al reporte
                crParameterDiscreteValue.Value = FolioDesde;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["Desde Numero"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;
                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                crParameterDiscreteValue.Value = FolioHasta;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["Hasta Numero"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;
                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                crParameterDiscreteValue.Value = Tabla;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["sTabla"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;
                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                crParameterDiscreteValue.Value = Comprobante;
                crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                crParameterFieldDefinition = crParameterFieldDefinitions["Comprobante"];
                crParameterValues = crParameterFieldDefinition.CurrentValues;
                crParameterValues.Clear();
                crParameterValues.Add(crParameterDiscreteValue);
                crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);

                //crViewerCfd.ReportSource = cryRpt;
                //crViewerCfd.Refresh();

                return cryRpt;
            }
            catch (Exception exVis)
            {
                ultimoMensaje = "No se puede mostrar el reporte. [MuestraEnVisor] " + exVis.Message;
                numError++;
                return null;
            }
        }
        
        public ReportDocument MuestraEnVisorTestSP(List<string> ValoresParametros)
        {
            ultimoMensaje = "";
            numError = 0;
            try
            {
                ReportDocument cryRpt = new ReportDocument();
                TableLogOnInfos crtableLogoninfos = new TableLogOnInfos();
                TableLogOnInfo crtableLogoninfo = new TableLogOnInfo();
                ConnectionInfo crConnectionInfo = new ConnectionInfo();
                //Tables CrTables;
                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();

                cryRpt.Load(_param.rutaReporteCrystal);

                //Conecta la base de datos
                crConnectionInfo.IntegratedSecurity = _IntegratedSecurity;
                crConnectionInfo.ServerName = _SrvrName;
                crConnectionInfo.DatabaseName = _DbName;
                if (!_IntegratedSecurity)
                {
                    crConnectionInfo.UserID = _IdUsuario;
                    crConnectionInfo.Password = _Password;
                }

                //CrTables = cryRpt.Database.Tables;
                //foreach (CrystalDecisions.CrystalReports.Engine.Table CrTable in CrTables)
                //{
                //    crtableLogoninfo = CrTable.LogOnInfo;
                //    crtableLogoninfo.ConnectionInfo = crConnectionInfo;
                //    CrTable.ApplyLogOnInfo(crtableLogoninfo);
                //}

                int i = 0;
                foreach (PrmtrsReporte pr in _param.ListaParametrosReporte)
                {
                    //Envía parámetros al reporte
                    crParameterDiscreteValue.Value = ValoresParametros[i];                      //valor
                    crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                    crParameterFieldDefinition = crParameterFieldDefinitions[pr.nombre.Trim()]; //nombre parámetro
                    crParameterValues = crParameterFieldDefinition.CurrentValues;
                    crParameterValues.Clear();
                    crParameterValues.Add(crParameterDiscreteValue);
                    crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);
                    i++;
                }

                cryRpt.SetDatabaseLogon(_IdUsuario, _Password, _SrvrName, _DbName, false);

                return cryRpt;
            }
            catch (Exception exVis)
            {
                ultimoMensaje = "No se puede mostrar el reporte. [MuestraEnVisor] " + exVis.Message;
                numError++;
                return null;
            }
    }
        
        public ReportDocument MuestraEnVisor(List<string> ValoresParametros )
        {
            ultimoMensaje = "";
            numError = 0;
            try
            {
                ReportDocument cryRpt = new ReportDocument();
                TableLogOnInfos crtableLogoninfos = new TableLogOnInfos();
                TableLogOnInfo crtableLogoninfo = new TableLogOnInfo();
                ConnectionInfo crConnectionInfo = new ConnectionInfo();
                Tables CrTables;
                ParameterFieldDefinitions crParameterFieldDefinitions;
                ParameterFieldDefinition crParameterFieldDefinition;
                ParameterValues crParameterValues = new ParameterValues();
                ParameterDiscreteValue crParameterDiscreteValue = new ParameterDiscreteValue();
                PageMargins margins;

                cryRpt.Load(_param.rutaReporteCrystal);
                //Conecta la base de datos
                crConnectionInfo.IntegratedSecurity = _IntegratedSecurity;
                crConnectionInfo.ServerName = _SrvrName;
                crConnectionInfo.DatabaseName = _DbName;
                if (!_IntegratedSecurity)
                {
                    crConnectionInfo.UserID = _IdUsuario;
                    crConnectionInfo.Password = _Password;
                }

                CrTables = cryRpt.Database.Tables;
                foreach (CrystalDecisions.CrystalReports.Engine.Table CrTable in CrTables)
                {
                    crtableLogoninfo = CrTable.LogOnInfo;
                    crtableLogoninfo.ConnectionInfo = crConnectionInfo;
                    CrTable.ApplyLogOnInfo(crtableLogoninfo);

                }

                int i = 0;
                foreach (PrmtrsReporte pr in _param.ListaParametrosReporte)
                {
                    //Envía parámetros al reporte
                    crParameterDiscreteValue.Value = ValoresParametros[i];                      //valor
                    crParameterFieldDefinitions = cryRpt.DataDefinition.ParameterFields;
                    crParameterFieldDefinition = crParameterFieldDefinitions[pr.nombre.Trim()]; //nombre parámetro
                    crParameterValues = crParameterFieldDefinition.CurrentValues;
                    crParameterValues.Clear();
                    crParameterValues.Add(crParameterDiscreteValue);
                    crParameterFieldDefinition.ApplyCurrentValues(crParameterValues);
                    i++;
                }

                //Define márgenes si existen parámetros
                if (_param.bottomMargin >= 0 && _param.topMargin >= 0 && _param.leftMargin >= 0 && _param.rightMargin >= 0)
                {
                    margins = cryRpt.PrintOptions.PageMargins;
                    margins.bottomMargin = _param.bottomMargin;
                    margins.topMargin = _param.topMargin;
                    margins.leftMargin = _param.leftMargin;
                    margins.rightMargin = _param.rightMargin;
                    cryRpt.PrintOptions.ApplyPageMargins(margins);
                }

                if (_param.ImprimeEnImpresora)
                {
                    cryRpt.PrintOptions.PrinterName = _param.NombreImpresora;
                    cryRpt.PrintToPrinter(1, false, 0, 0);
                }
                return cryRpt;
            }
            catch (Exception exVis)
            {
                ultimoMensaje = "No se puede mostrar el reporte. [MuestraEnVisor] " + exVis.Message;
                numError++;
                return null;
            }
        }

    }
}
