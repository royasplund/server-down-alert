$ipAddress = "192.168.1.1"                                                         #IP Of the remote host that you will be testing is up
$port = 80                                                                         #Port of remote host that you will be testing is up
$maxAttempts = 5
$emailTo = "recipient@example.com"
$emailFrom = "sender@example.com"
$emailSubject = "Connection to $ipAddress:$port failed"
$emailBody = "All attempts to connect to $ipAddress:$port have failed."
$credentialFile = "smtp-creds.txt"
$smtpServer = "smtp.example.com"
$smtpPort = 587
$smtpSecure = "tls"

# If the credential file exists, read the credentials from the file.
if (Test-Path $credentialFile) {
    $encryptedCredential = Get-Content $credentialFile | ConvertTo-SecureString
    $smtpCredential = New-Object System.Management.Automation.PSCredential $encryptedCredential
}
# If the credential file doesn't exist, prompt the user for credentials and save them to the file.
else {
    $smtpCredential = Get-Credential
    $encryptedCredential = $smtpCredential.Password | ConvertFrom-SecureString
    $encryptedCredential | Set-Content $credentialFile
}

$attempts = 0
$connected = $false

while ($attempts -lt $maxAttempts -and !$connected) {
    $attempts++
    try {
        $client = New-Object System.Net.Sockets.TcpClient($ipAddress, $port)
        $connected = $true
        Write-Host "Connected to $ipAddress:$port"
    } catch {
        Write-Host "Attempt $attempts failed to connect to $ipAddress:$port"
        Start-Sleep -Seconds 5
    }
}

if (!$connected) {
    Write-Host "All attempts to connect to $ipAddress:$port have failed. Sending email alert."
    $smtpUser = $smtpCredential.UserName
    $smtpPassword = $smtpCredential.Password
    $email = New-Object System.Net.Mail.MailMessage($emailFrom, $emailTo, $emailSubject, $emailBody)
    $smtp = New-Object System.Net.Mail.SmtpClient($smtpServer, $smtpPort)
    $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpUser, $smtpPassword)
    $smtp.EnableSsl = ($smtpSecure -eq "ssl")
    $smtp.Send($email)
}

