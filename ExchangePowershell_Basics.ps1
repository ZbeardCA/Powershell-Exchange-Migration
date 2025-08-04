# Anlegen vom Anonymous Relay:

New-ReceiveConnector -Name "Anonymous Relay" -TransportRole FrontendTransport -Custom -Bindings 0.0.0.0:25 -RemoteIpRanges 192.168.100.50, 192.168.100.51
Set-ReceiveConnector "Anonymous Relay" -PermissionGroups AnonymousUsers
Get-ReceiveConnector "Anonymous Relay" | Add-ADPermission -User "NT-Authority\Anonymous-Logon" -ExtendedRights "Ms-Exch-SMTP-Accept-Any-Recipient"

#oder in Englisch
Get-ReceiveConnector "Anonymous Relay" | Add-ADPermission -User "NT AUTHORITY\ANONYMOUS LOGON" -ExtendedRights "Ms-Exch-SMTP-Accept-Any-Recipient"
------------------------------------------------------------------------------------------------------------------------------------------------------------
#Testmail
Send-MailMessage -SmtpServer  -From relay@domain.de -To recicpient@domain.de -Subject "TEST RELAY"

Test-Mailflow -TargetEmailAddress POSTFACHNAME@DOMAIN.DE
------------------------------------------------------------------------------------------------------------------------------------------------------------
#Autodiscover-Cache & Outlook-Einträge bereinigen

##Client-Side

###Windows
ipconfig /flushdns

####Outlook
outlook.exe /cleanserverrules

###Server-Side

Set-ClientAccessService EXCHANGESERVERNAME -ClearAlternateServiceAccountCredentials
-------------------------------------------------------------------------------------------------------------------------------------------------------------
#Buildnummer eines Exchange
Get-Command Exsetup.exe | ForEach-Object {$_.FileVersionInfo}

#URL
https://learn.microsoft.com/de-de/exchange/new-features/build-numbers-and-release-dates
-------------------------------------------------------------------------------------------------------------------------------------------------------------
#
