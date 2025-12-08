# Anlegen vom Anonymous Relay:

New-ReceiveConnector -Name "Anonymous Relay" -TransportRole FrontendTransport -Custom -Bindings 0.0.0.0:25 -RemoteIpRanges 192.168.100.50, 192.168.100.51
Set-ReceiveConnector "Anonymous Relay" -PermissionGroups AnonymousUsers
Get-ReceiveConnector "Anonymous Relay" | Add-ADPermission -User "NT-Authority\Anonymous-Logon" -ExtendedRights "Ms-Exch-SMTP-Accept-Any-Recipient"

#oder in Englisch
Get-ReceiveConnector "Anonymous Relay" | Add-ADPermission -User "NT AUTHORITY\ANONYMOUS LOGON" -ExtendedRights "Ms-Exch-SMTP-Accept-Any-Recipient"

## Direkt vergeben
# 1. Den korrekten Namen für "Anonymous Logon" automatisch ermitteln
$ExchangeUser = (New-Object System.Security.Principal.SecurityIdentifier("S-1-5-7")).Translate([System.Security.Principal.NTAccount]).Value

# 2. Den Befehl mit der Variable ausführen
Get-ReceiveConnector "RELAYNAME" | Add-ADPermission -User $ExchangeUser -ExtendedRights "Ms-Exch-SMTP-Accept-Any-Recipient"

#Kopieren von einem Exchange Konnektor

(Get-ReceiveConnector -Identity "EXCHANGENAME\KONNEKTORNAME").RemoteIPRanges | Sort-Object | Format-Table

New-ReceiveConnector -Name "NEUERKONNEKTOR" -Server "SERVERNAME" -Usage Custom -TransportRole FrontEndTransport -PermissionGroups AnonymousUsers -Bindings 0.0.0.0:25 -RemoteIPRanges (Get-ReceiveConnector "SERVERNAME\ALTERKONNEKTOR").RemoteIPRanges

Get-ReceiveConnector "SERVERNAME\KONNEKTORNAME" | Add-ADPermission -User 'NT AUTHORITY\Anonymous Logon' -ExtendedRights MS-Exch-SMTP-Accept-Any-Recipient

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
>>> https://learn.microsoft.com/de-de/exchange/new-features/build-numbers-and-release-dates
-------------------------------------------------------------------------------------------------------------------------------------------------------------
#Patchstand

Get-Command Exsetup.exe | ForEach-Object {$_.FileVersionInfo}

>>> https://learn.microsoft.com/de-de/exchange/new-features/build-numbers-and-release-dates

-------------------------------------------------------------------------------------------------------------------------------------------------------------
#Cals auslesen nach Nummer

(Get-ExchangeServerAccessLicenseUser -LicenseName "Exchange Server 2016 Standard CAL").Count

(Get-ExchangeServerAccessLicenseUser -LicenseName "Exchange Server 2016 Enterprise CAL").Count

--------------------------------------------------------------------------------------------------------------------------------------------------------------
###Dienste verwalten

#Abfragen
Get-Service | Where-Object { $_.DisplayName -like "*Exchange*" -and $_.DisplayName -notlike "*Hyper-V*" } | Format-Table DisplayName, Name, Status

#Alle Neustarten
Get-Service *Exchange* | Where-Object {$_.DisplayName -notlike "*Hyper-V*"} | Restart-Service -Force

#Nur aktive
$services = Get-Service | Where-Object { $_.Name -like "MSExchange*" -and $_.Status -eq "Running" }

foreach ($service in $services) {
    Restart-Service $service.Name -Force
}

#Alle Disabled wieder auf automatic stellen

Get-Service | Where-Object { $_.DisplayName –like “Microsoft Exchange *” } | Set-Service –StartupType Automatic

#Die Dienste danach starten

Get-Service | Where-Object { $_.DisplayName –like “Microsoft Exchange *” } | Start-Service


---------------------------------------------------------------------------------------------------------------------------------------------------------------

