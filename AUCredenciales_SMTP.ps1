# Define las credenciales
$email = "test@test.es" #poner aquí nuestro correo (da igual dominio)
$password = "pass" # poner aquí la contraseña del correo

# Define el servidor SMTP y el puerto para Outlook
$smtpServer = "smtp.outlook.com" # !!!IMPORTANTE!! CAMBIAR TIPO DE SERVIDOR (outlook.com) (gmail.com) 
$smtpPort = 587

# Función para autenticar las credenciales sin enviar un correo
function Test-EmailCredential {
    param (
        [string]$smtpServer,
        [int]$smtpPort,
        [string]$email,
        [string]$password
    )

    try {
        # Crear el cliente TCP y establecer una conexión con el servidor SMTP
        $tcpClient = New-Object System.Net.Sockets.TcpClient($smtpServer, $smtpPort)
        $networkStream = $tcpClient.GetStream()

        # Leer la respuesta inicial del servidor SMTP
        $reader = [System.IO.StreamReader]::new($networkStream)
        $writer = [System.IO.StreamWriter]::new($networkStream)
        $writer.AutoFlush = $true

        $response = $reader.ReadLine()
        if ($response -notlike "220*") { throw "Error al conectar con el servidor SMTP: $response" }

        # Enviar el comando EHLO
        $writer.WriteLine("EHLO $smtpServer")
        $response = $reader.ReadLine()
        while ($reader.Peek() -ne -1) { $response += "`n" + $reader.ReadLine() }
        if ($response -notlike "250*") { throw "Error en el comando EHLO: $response" }

        # Enviar el comando STARTTLS
        $writer.WriteLine("STARTTLS")
        $response = $reader.ReadLine()
        if ($response -notlike "220*") { throw "Error en el comando STARTTLS: $response" }

        # Establecer una conexión SSL
        $sslStream = New-Object System.Net.Security.SslStream($networkStream, $false, { $true })
        $sslStream.AuthenticateAsClient($smtpServer)
        $reader = [System.IO.StreamReader]::new($sslStream)
        $writer = [System.IO.StreamWriter]::new($sslStream)
        $writer.AutoFlush = $true

        # Enviar el comando EHLO nuevamente después de STARTTLS
        $writer.WriteLine("EHLO $smtpServer")
        $response = $reader.ReadLine()
        while ($reader.Peek() -ne -1) { $response += "`n" + $reader.ReadLine() }
        if ($response -notlike "250*") { throw "Error en el comando EHLO después de STARTTLS: $response" }

        # Autenticar usando AUTH LOGIN
        $writer.WriteLine("AUTH LOGIN")
        $response = $reader.ReadLine()
        if ($response -notlike "334*") { throw "Error en el comando AUTH LOGIN: $response" }

        # Enviar el correo codificado en Base64
        $writer.WriteLine([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($email)))
        $response = $reader.ReadLine()
        if ($response -notlike "334*") { throw "Error al enviar el usuario: $response" }

        # Enviar la contraseña codificada en Base64
        $writer.WriteLine([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($password)))
        $response = $reader.ReadLine()

        if ($response -like "235*") {
            Write-Output "Autenticacion exitosa: Las credenciales son correctas."
        } else {
            Write-Output "Error de autenticacion: Las credenciales son incorrectas."
        }

        # Cerrar las conexiones
        $writer.Close()
        $reader.Close()
        $sslStream.Close()
        $tcpClient.Close()
    }
    catch {
        Write-Output "Error de autenticación: Las credenciales son incorrectas."
    }
}

# Probar las credenciales
Test-EmailCredential -smtpServer $smtpServer -smtpPort $smtpPort -email $email -password $password

# Espera a que el usuario presione una tecla antes de cerrar para que no se cierre instantaneamente.
Write-Output "Presiona cualquier tecla para cerrar el programa..."
[System.Console]::ReadKey($true)
