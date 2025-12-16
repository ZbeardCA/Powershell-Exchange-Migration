# Installation Server

Download neuste SE Version

##Vorbereitung:

Install-WindowsFeature Server-Media-Foundation, NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation, RSAT-ADDS

##Visual Studio 2012 und 2013
https://www.microsoft.com/download/details.aspx?id=30679
https://www.microsoft.com/de-de/download/details.aspx?id=40784

##UCM 4.0 Runtime
https://www.microsoft.com/de-de/download/details.aspx?id=34992

## IIS URL Rewrite Module
https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi

# Umzug normales Posfach MIT Archiv

New-MoveRequest `
    -Identity "POSTFACHNAME" `
    -TargetDatabase "ZIELDATENBANK" `
    -ArchiveTargetDatabase "ZIELARCHIVDATENBANK" `
    -BadItemLimit 50 `
    -SuspendWhenReadyToComplete `
    -BatchName "NAMEVOMBATCH"

# Umzug finalisieren

Get-MoveRequest -MoveStatus AutoSuspended | Resume-MoveRequest

# Umzug mehrere Postfächer MIT Archiv.


$Users = @("NAME@KUNDE.de", "NAME@KUNDE.de", "NAME@KUNDE.de")
$TargetDatabase = "MDB01"

foreach ($User in $Users) {
    New-MoveRequest -Identity $User -TargetDatabase $TargetDatabase -SuspendWhenReadyToComplete -BatchName "BatchMove_$(Get-Date -Format 'yyyyMMdd')"
}


#Auslesen Postfachdaten inklusive Archive:


param(
    [switch]$GridView   # Aufruf mit -GridView für interaktive Ansicht
)

Write-Host "Sammle Postfach- und Archivstatistiken …"

$report = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox,SharedMailbox |
    ForEach-Object {
        # Primär-Mailbox
        $prim = Get-MailboxStatistics -Identity $_.Identity

        # Archiv-Mailbox (falls vorhanden, sonst Fehler abfangen)
        $arch = $null
        try {
            $arch = Get-MailboxStatistics -Identity $_.Identity -Archive -ErrorAction Stop  # -Archive-Switch :contentReference[oaicite:0]{index=0}
        } catch { }

        [pscustomobject]@{
            DisplayName       = $_.DisplayName
            UPN               = $_.PrimarySmtpAddress
            Database          = $prim.Database
            ItemCount         = $prim.ItemCount
            PrimarySizeMB     = [math]::Round($prim.TotalItemSize.Value.ToMB(),2)            # .ToMB()-Methode :contentReference[oaicite:1]{index=1}
            ArchiveSizeMB     = if ($arch) {[math]::Round($arch.TotalItemSize.Value.ToMB(),2)} else {0}
            ArchiveItemCount  = if ($arch) {$arch.ItemCount} else {0}
            LastLogon         = $prim.LastLogonTime
        }
    } |
    Sort-Object PrimarySizeMB -Descending

if ($GridView) {
    $report | Out-GridView -Title "Mailbox + Archive Size Report (Exchange 2016)"
} else {
    $report | Format-Table -AutoSize
}


## Systempostfächer umziehen
get-mailbox -Arbitration | New-MoveRequest -TargetDatabase DATENBANKNAME

# Monitoring von MoveRequests:

# Fortschritt live anzeigen
Get-MoveRequest -BatchName "BATCHNAME" |
  Get-MoveRequestStatistics | ft DisplayName,Status,PercentComplete
  
#Alle
Get-MoveRequest | Get-MoveRequestStatistics

#Löschen der Moverequests
Get-MoveRequest | Remove-MoveRequest

# Nur schon fertig gespulte Moves
Get-MoveRequest -BatchName "BATCHNAME" -MoveStatus Synced

#Datenbanken umbennenen und mit Logs verschieben

Get-MailboxDatabase -Server "SERVERNAME" | Set-MailboxDatabase -Name MDB01
Move-DatabasePath MDB01 -EdbFilePath E:\MDB01\MDB01.edb -LogFolderPath F:\MDB01

#Erstellen einer neuen Datenbank und Logfolderpath

New-MailboxDatabase -Name "MDB01" -Server "SERVERNAME" -EdbFilePath "E:\MDB01\MDB01.edb" -LogFolderPath "F:\MDB01"

#Virtuelle Verzeichnisse kopieren

$NeuerExchange = "NEUERSERVER"
$AlterExchange = "ALTERSERVER"
#Get URLs from Exchange 2016 Server
$autodiscoverhostname = (Get-ClientAccessService $AlterExchange).AutoDiscoverServiceInternalUri
$owainturl = (Get-OwaVirtualDirectory -Server $AlterExchange).internalurl
$owaexturl = (Get-OwaVirtualDirectory -Server $AlterExchange).externalurl
$ecpinturl = (Get-EcpVirtualDirectory -server $AlterExchange).internalurl
$ecpexturl = (Get-EcpVirtualDirectory -server $AlterExchange).externalurl
$ewsinturl = (Get-WebServicesVirtualDirectory -Server $AlterExchange).internalurl
$ewsexturl = (Get-WebServicesVirtualDirectory -Server $AlterExchange).externalurl
$easinturl = (Get-ActiveSyncVirtualDirectory -Server $AlterExchange).internalurl
$easexturl = (Get-ActiveSyncVirtualDirectory -Server $AlterExchange).externalurl
$oabinturl = (Get-OabVirtualDirectory -server $AlterExchange).internalurl
$oabexturl = (Get-OabVirtualDirectory -server $AlterExchange).externalurl
$mapiinturl = (Get-MapiVirtualDirectory -server $AlterExchange).internalurl
$mapiexturl = (Get-MapiVirtualDirectory -server $AlterExchange).externalurl
$OutlAnyInt = (Get-OutlookAnywhere -Server $AlterExchange).internalhostname
$OutlAnyExt = (Get-OutlookAnywhere -Server $AlterExchange).externalhostname
#Configure Exchange 2019 Server
Get-OwaVirtualDirectory -Server $NeuerExchange | Set-OwaVirtualDirectory -internalurl $owainturl -externalurl $owaexturl -Confirm:$false
Get-EcpVirtualDirectory -server $NeuerExchange | Set-EcpVirtualDirectory -internalurl $ecpinturl -externalurl $ecpexturl -Confirm:$false
Get-WebServicesVirtualDirectory -server $NeuerExchange | Set-WebServicesVirtualDirectory -internalurl $ewsinturl -externalurl $ewsexturl -Confirm:$false
Get-ActiveSyncVirtualDirectory -Server $NeuerExchange | Set-ActiveSyncVirtualDirectory -internalurl $easinturl -externalurl $easexturl -Confirm:$false
Get-OabVirtualDirectory -Server $NeuerExchange | Set-OabVirtualDirectory -internalurl $oabinturl -externalurl $oabexturl -Confirm:$false
Get-MapiVirtualDirectory -Server $NeuerExchange | Set-MapiVirtualDirectory -externalurl $mapiexturl -internalurl $mapiinturl -Confirm:$false
Get-OutlookAnywhere -Server $NeuerExchange | Set-OutlookAnywhere -externalhostname $OutlAnyExt -internalhostname $OutlAnyInt -ExternalClientsRequireSsl:$true -InternalClientsRequireSsl:$true -ExternalClientAuthenticationMethod 'Negotiate' -Confirm:$false
Get-ClientAccessService $NeuerExchange | Set-ClientAccessService -AutoDiscoverServiceInternalUri $autodiscoverhostname -Confirm:$false
#Display setttings
Get-OwaVirtualDirectory | fl server,externalurl,internalurl
Get-EcpVirtualDirectory | fl server,externalurl,internalurl
Get-WebServicesVirtualDirectory | fl server,externalurl,internalurl
Get-ActiveSyncVirtualDirectory | fl server,externalurl,internalurl
Get-OabVirtualDirectory | fl server,externalurl,internalurl
Get-MapiVirtualDirectory | fl server,externalurl,internalurl
Get-OutlookAnywhere | fl servername,ExternalHostname,InternalHostname
Get-ClientAccessService | fl name,AutoDiscoverServiceInternalUri
