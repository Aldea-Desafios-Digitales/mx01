using System;
using System.Collections.Generic;
using System.Text;
using Comun;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;


namespace Encriptador
{
    public class TecnicaDeEncriptacion
    {
        // Create a new instance of the RSACryptoServiceProvider class and automatically create a new key-pair.
        private RSACryptoServiceProvider RSAalg = new RSACryptoServiceProvider();
        private RSAParameters Key;
        private String ultimoMensaje = String.Empty;

        private X509Certificate2 certificado = null;
        public string noCertificado = "";
        public string certificadoFormatoPem = "";

        public TecnicaDeEncriptacion()
        {
        }

        /// <summary>
        /// Constructor. Inicializa los datos públicos y privados del certificado.
        /// El archivo de llave privada debe estar en formato DER con extensión key
        /// El archivo del certificado debe estar en formato DER con extensión cer
        /// También se debe tener el certificado en formato PEM con extensión pem
        /// En caso de tener un archivo pfx, convertirlo y dividirlo en dos archivos: cerficiado.cer y llave.key
        /// </summary>
        /// <param name="rutaLlavePrivada">Ruta y nombre del archivo de llave privada en formato DER</param>
        /// <param name="claveLlavePrivada">Password de la llave privada</param>
        /// <param name="rutaCertificado">Ruta y nombre del archivo del certificado en formato DER</param>
        /// <param name="rutaCertificadoPem">Ruta y nombre del archivo del certificado en formato PEM</param>
        /// <returns></returns>
        public TecnicaDeEncriptacion(string rutaLlavePrivada, string claveLlavePrivada, string rutaCertificado, string rutaCertificadoPem)
        {
            try
            {
                opensslkey utilOpensslkey = new opensslkey();

                // Cargar la llave privada RSA a partir de un archivo y una clave
                //if (rutaLlavePrivada.Contains(".pfx"))
                //{
                //    X509Certificate2 certificadoPfx = new X509Certificate2(rutaLlavePrivada, claveLlavePrivada);
                //    RSAalg = (RSACryptoServiceProvider)certificadoPfx.PrivateKey;
                //}
                //if (rutaLlavePrivada.Contains(".key"))
                //{
                //}

                RSAalg = utilOpensslkey.obtieneLlavePrivadaRSA(rutaLlavePrivada, claveLlavePrivada);
                ultimoMensaje += utilOpensslkey.ultimoMensaje;

                // Export the key information to an RSAParameters object.
                // You must pass true to export the private key for signing.
                Key = RSAalg.ExportParameters(true);

                certificado = utilOpensslkey.certificadox509(rutaCertificado);
                ultimoMensaje += utilOpensslkey.ultimoMensaje;

                noCertificado = utilOpensslkey.HexString2Ascii(certificado.SerialNumber);
                ultimoMensaje += utilOpensslkey.ultimoMensaje;

                certificadoFormatoPem = utilOpensslkey.leeCertificadoPEM(rutaCertificadoPem);
                ultimoMensaje += utilOpensslkey.ultimoMensaje;

                if (!ultimoMensaje.Equals(String.Empty))
                    throw new CryptographicException(ultimoMensaje);
            }
            catch (Exception eRsa)
            {
                ultimoMensaje += "Excepción al obtener datos del certificado. Verifique la existencia de los siguientes archivos: " + Environment.NewLine +
                            rutaLlavePrivada + Environment.NewLine + 
                            rutaCertificado + Environment.NewLine +
                            rutaCertificadoPem + Environment.NewLine;
                throw new ArgumentException(ultimoMensaje, eRsa);
            }
        }

        /// <summary>
        /// Digiere una cadena y la Firma con una llave privada RSA.
        /// </summary>
        /// <param name="cadenaADigerir">Datos para digerir y firmar</param>
        /// <returns>string</returns>
        public String obtieneSello(String cadenaADigerir)
        {
            ultimoMensaje = "";
            try
            {
                String strBase64;

                // Create byte arrays to hold original, encrypted, and decrypted data.
                byte[] originalData = Encoding.UTF8.GetBytes(cadenaADigerir);
                byte[] signedData;

                // Hash and sign the data.
                //signedData = SHA1HashAndSignBytes(originalData, Key);
                signedData = RSAalg.SignData(originalData, "SHA256");

                // Convert to base64 and output result
                strBase64 = System.Convert.ToBase64String(signedData);

                // Verify the data and display the result to the console.
                //if (!SHA1VerifySignedHash(originalData, signedData, Key))
                if(!RSAalg.VerifyData(originalData, "SHA256", signedData))
                {
                    strBase64 = "FAILED";
                    ultimoMensaje += "Excepción al validar el sello. El sello no corresponde a la firma de: " + cadenaADigerir + Environment.NewLine;
                    throw new ArgumentException(ultimoMensaje);
                }
                return strBase64;

            }
            catch (ArgumentNullException an)
            {
                throw new ArgumentNullException("La cadena original está vacía.", an);
            }
            catch
            {
                throw;
            }
        }

        /// <summary>
        /// Digestión MD5 Hash. Deprecated en el SAT
        /// </summary>
        /// <param name="input"></param>
        /// <param name=""></param>
        /// <returns></returns>
        public string GetMD5Hash(string input)
        {
            MD5CryptoServiceProvider md5 = new MD5CryptoServiceProvider();
            byte[] mensajeDigerido = Encoding.UTF8.GetBytes(input);
            mensajeDigerido = md5.ComputeHash(mensajeDigerido);
            StringBuilder s = new StringBuilder();
            foreach (byte b in mensajeDigerido)
            {
                s.Append(b.ToString("x2"));
            }
            return s.ToString().ToUpper();
        }

        /// <summary>
        /// Digestión MD5 Hash y firma con llave privada. Deprecated en el SAT
        /// </summary>
        /// <param name="DataToSign"></param>
        /// <param name=""></param>
        /// <returns></returns>
        public byte[] MD5HashAndSignBytes(byte[] DataToSign, RSAParameters Key)
        {
            ultimoMensaje = "";
            try
            {
                // Create a new instance of RSACryptoServiceProvider using the 
                // key from RSAParameters.  
                RSACryptoServiceProvider RSAalg = new RSACryptoServiceProvider();

                RSAalg.ImportParameters(Key);

                // Hash and sign the data. Pass a new instance of SHA1CryptoServiceProvider to specify the use of MD5 for hashing.
                return RSAalg.SignData(DataToSign, new MD5CryptoServiceProvider());
            }
            catch (CryptographicException e)
            {
                ultimoMensaje += " [MD5HashAndSignBytes] Error al firmar la cadena original. " + e.Message;
                return null;
            }
        }

        /// <summary>
        /// Verificación de de la integridad del comprobante
        /// </summary>
        /// <param name="cadenaOriginal"></param>
        /// <param name="firmaCodificadaEnBase64"></param>
        /// <param name="pemCertificate"></param>
        /// <returns></returns>
        public bool VerificaIntegridadDeDatosSellados(String cadenaOriginal, String firmaCodificadaEnBase64, String pemCertificate)
        {
            bool verificado = false;

                byte[] DataToVerify = Encoding.UTF8.GetBytes(cadenaOriginal);

                byte[] SignedData = System.Convert.FromBase64String(firmaCodificadaEnBase64);
                byte[] rawCertificate = System.Convert.FromBase64String(pemCertificate);

                X509Certificate2 certificate = new X509Certificate2(rawCertificate);
                RSACryptoServiceProvider rsaprovider = (RSACryptoServiceProvider)certificate.PublicKey.Key;
                
                if (rsaprovider.VerifyData(DataToVerify, "SHA256", SignedData))
                {
                    verificado = true;
                }
            return verificado;
        }

        /// <summary>
        /// Verificación de cadena firmada y digerida MD5 Hash. Deprecated en el SAT
        /// </summary>
        /// <param name="DataToVerify"></param>
        /// <param name=""></param>
        /// <returns></returns>
        public bool MD5VerifySignedHash(byte[] DataToVerify, byte[] SignedData, RSAParameters Key)
        {
            ultimoMensaje = "";
            try
            {
                // Create a new instance of RSACryptoServiceProvider using the key from RSAParameters.
                RSACryptoServiceProvider RSAalg = new RSACryptoServiceProvider();
                RSAalg.ImportParameters(Key);

                // Verify the data using the signature.  Pass a new instance of SHA1CryptoServiceProvider to specify the use of SHA1 for hashing.
                return RSAalg.VerifyData(DataToVerify, new MD5CryptoServiceProvider(), SignedData);
            }
            catch (CryptographicException e)
            {
                ultimoMensaje += " [MD5VerifySignedHash] Error al verificar la cadena original firmada." + e.Message;
                return false;
            }
        }

        /// <summary>
        /// Digestión SHA1 y firma de datos.
        /// </summary>
        /// <param name="DataToSign">Datos para firmar</param>
        /// <param name="Key">Llave privada RSA</param>
        /// <returns></returns>
        public byte[] SHA1HashAndSignBytes(byte[] DataToSign, RSAParameters Key)
        {
            ultimoMensaje = "";
            try
            {
                // Create a new instance of RSACryptoServiceProvider using the key from RSAParameters.  

//                RSACryptoServiceProvider RSAalg = new RSACryptoServiceProvider();
//                RSAalg.ImportParameters(Key);

                // Hash and sign the data. Pass a new instance of SHA1CryptoServiceProvider to specify the use of MD5 for hashing.
                return RSAalg.SignData(DataToSign, new SHA1CryptoServiceProvider());
            }
            catch (CryptographicException e)
            {
                ultimoMensaje += " [SHA1HashAndSignBytes] Error al firmar la cadena original. " + e.Message;
                return null;
            }
        }

        /// <summary>
        /// Verifica datos firmados y digeridos SHA1.
        /// </summary>
        /// <param name="DataToVerify">Datos para verificar</param>
        /// <param name="SignedData">Datos firmados</param>
        /// <param name="Key">Llave privada RSA</param>
        /// <returns></returns>
        public bool SHA1VerifySignedHash(byte[] DataToVerify, byte[] SignedData, RSAParameters Key)
        {
            ultimoMensaje = "";
            try
            {
                // Create a new instance of RSACryptoServiceProvider using the key from RSAParameters.

//                RSACryptoServiceProvider RSAalg = new RSACryptoServiceProvider();
//                RSAalg.ImportParameters(Key);

                // Verify the data using the signature.  Pass a new instance of SHA1CryptoServiceProvider to specify the use of SHA1 for hashing.
                return RSAalg.VerifyData(DataToVerify, new SHA1CryptoServiceProvider(), SignedData);

            }
            catch (CryptographicException e)
            {
                ultimoMensaje += " [SHA1VerifySignedHash] Error al verificar la cadena original firmada." + e.Message;
                return false;
            }
        }

    }
}
