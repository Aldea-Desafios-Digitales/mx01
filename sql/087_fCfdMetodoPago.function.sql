--------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('dbo.fCfdiMetodoYFormaPago') IS NOT NULL
   DROP FUNCTION dbo.fCfdiMetodoYFormaPago
GO

create function dbo.fCfdiMetodoYFormaPago(@soptype smallint, @orpmtrvd numeric(19,5), @total numeric(19,5), @metodoPagoUsr varchar(5), @FormaPagoRel varchar(2), @FormaPagoSimu varchar(2), @FormaPagoUsr varchar(2))
returns table
as
--Propósito. Devuelve el método de pago PUE, PPD; y la forma de pago. 
--		El usuario puede ingresar el método de pago PUE y la forma de pago al momento de ingresar la factura.
--		Independiente de lo que ingrese el usuario, si el pago es simultáneo el método es PUE
--Requisitos. -
--16/11/18 jcf Creación cfdi
--04/12/19 jcf Método de pago para NC debe ser PUE
--17/01/20 jcf Agrega forma de pago ingresado por el usuario en caso de nc
--
return
( 
	select	case when @soptype = 3 then
				case when @orpmtrvd = @total then	--pago simultáneo
					 'PUE'
				Else 
					case when isnull(@metodoPagoUsr, '') != '' then
						@metodoPagoUsr 
					else 'PPD'
					end
				END
			else 'PUE'
			end	metodoPago,
			
			case when @soptype = 3 then
				case when @orpmtrvd = @total then	--pago simultáneo
					@FormaPagoSimu
				else 
					case when isnull(@metodoPagoUsr, '') = 'PUE' and isnull(@FormaPagoUsr, '') != '' then
						@FormaPagoUsr 
					else '99'
					end
				end
			else 
				case when isnull(@FormaPagoUsr, '') = '' then 
					@FormaPagoRel
					else @FormaPagoUsr
				end
			end formaPago
)
go

IF (@@Error = 0) PRINT 'Creación exitosa de la función: fCfdiMetodoYFormaPago()'
ELSE PRINT 'Error en la creación de la función: fCfdiMetodoYFormaPago()'
GO
--------------------------------------------------------------------------------------------------------

