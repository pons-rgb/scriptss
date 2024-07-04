# Definir el correo y la contraseña
$correo = "usuario@hotmail.es" # Cambiar correo
$contraseña = "pass" # Cambiar contraseña 

# Configuración del servidor SMTP (ajusta esto según tu proveedor de correo)
$smtpServidor = "smtp.outlook.com"  # Este scripts solo es para outlook, por los mensajes de error.
$smtpPuerto = 587  # Puerto SMTP común, cambia si es necesario
$enableSsl = $true  # Cambia esto según sea necesario (false si no necesitas SSL)

# Función para probar la autenticación SMTP sin enviar un mensaje
function Test-AutenticacionSMTP {
    param (
        [string]$smtpServidor,
        [int]$smtpPuerto,
        [bool]$enableSsl,
        [string]$correo,
        [string]$contraseña
    )

    try {
        # Crear un cliente SMTP
        $smtpClient = New-Object Net.Mail.SmtpClient($smtpServidor, $smtpPuerto)
        $smtpClient.EnableSsl = $enableSsl

        # Establecer las credenciales
        $smtpClient.Credentials = New-Object System.Net.NetworkCredential($correo, $contraseña)

        # Enviar el comando EHLO
        $smtpClient.ServicePoint.MaxIdleTime = 1
        $smtpClient.ServicePoint.SetTcpKeepAlive($true, 10000, 1000)

        # Intenta enviar un comando vacío para verificar la autenticación
        $smtpClient.Send("test@gmail.com", $correo, "Test", "Este es un mensaje de prueba.") # este correo no existe por eso da el error, pero aún así da error por permiso denegado y no por autenticación.
        
        Write-Host "Credenciales correctas"
        return $true
    } catch {
        if ($_.Exception.Message -match "5\.7\.57") {
            Write-Host "Credenciales incorrectas"
            return $false
        } elseif ($_.Exception.Message -match "5\.2\.252") {
            Write-Host "Credenciales correctas"
            return $false
        }
    }
}

# Probar las credenciales
Test-AutenticacionSMTP -smtpServidor $smtpServidor -smtpPuerto $smtpPuerto -enableSsl $enableSsl -correo $correo -contraseña $contraseña
