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


# Monitoring von MoveRequests:

# Fortschritt live anzeigen
Get-MoveRequest -BatchName "BATCHNAME" |
  Get-MoveRequestStatistics | ft DisplayName,Status,PercentComplete
  
#Alle
Get-MoveRequest | Get-MoveRequestStatistics

# Nur schon fertig gespulte Moves
Get-MoveRequest -BatchName "BATCHNAME" -MoveStatus Synced

#Datenbanken umbennenen und mit Logs verschieben

Get-MailboxDatabase -Server "SERVERNAME" | Set-MailboxDatabase -Name MDB01
Move-DatabasePath MDB01 -EdbFilePath E:\MDB01\MDB01.edb -LogFolderPath F:\MDB01

#Erstellen einer neuen Datenbank und Logfolderpath

New-MailboxDatabase -Name "MDB01" -Server "SERVERNAME" -EdbFilePath "E:\MDB01\MDB01.edb" -LogFolderPath "F:\MDB01"

#Virtuelle Verzeichnisse kopieren

$Exchange2019Server = "NEUERSERVER"
$Exchange2016Server = "ALTERSERVER"
#Get URLs from Exchange 2016 Server
$autodiscoverhostname = (Get-ClientAccessService $Exchange2016Server).AutoDiscoverServiceInternalUri
$owainturl = (Get-OwaVirtualDirectory -Server $Exchange2016Server).internalurl
$owaexturl = (Get-OwaVirtualDirectory -Server $Exchange2016Server).externalurl
$ecpinturl = (Get-EcpVirtualDirectory -server $Exchange2016Server).internalurl
$ecpexturl = (Get-EcpVirtualDirectory -server $Exchange2016Server).externalurl
$ewsinturl = (Get-WebServicesVirtualDirectory -Server $Exchange2016Server).internalurl
$ewsexturl = (Get-WebServicesVirtualDirectory -Server $Exchange2016Server).externalurl
$easinturl = (Get-ActiveSyncVirtualDirectory -Server $Exchange2016Server).internalurl
$easexturl = (Get-ActiveSyncVirtualDirectory -Server $Exchange2016Server).externalurl
$oabinturl = (Get-OabVirtualDirectory -server $Exchange2016Server).internalurl
$oabexturl = (Get-OabVirtualDirectory -server $Exchange2016Server).externalurl
$mapiinturl = (Get-MapiVirtualDirectory -server $Exchange2016Server).internalurl
$mapiexturl = (Get-MapiVirtualDirectory -server $Exchange2016Server).externalurl
$OutlAnyInt = (Get-OutlookAnywhere -Server $Exchange2016Server).internalhostname
$OutlAnyExt = (Get-OutlookAnywhere -Server $Exchange2016Server).externalhostname
#Configure Exchange 2019 Server
Get-OwaVirtualDirectory -Server $Exchange2019Server | Set-OwaVirtualDirectory -internalurl $owainturl -externalurl $owaexturl -Confirm:$false
Get-EcpVirtualDirectory -server $Exchange2019Server | Set-EcpVirtualDirectory -internalurl $ecpinturl -externalurl $ecpexturl -Confirm:$false
Get-WebServicesVirtualDirectory -server $Exchange2019Server | Set-WebServicesVirtualDirectory -internalurl $ewsinturl -externalurl $ewsexturl -Confirm:$false
Get-ActiveSyncVirtualDirectory -Server $Exchange2019Server | Set-ActiveSyncVirtualDirectory -internalurl $easinturl -externalurl $easexturl -Confirm:$false
Get-OabVirtualDirectory -Server $Exchange2019Server | Set-OabVirtualDirectory -internalurl $oabinturl -externalurl $oabexturl -Confirm:$false
Get-MapiVirtualDirectory -Server $Exchange2019Server | Set-MapiVirtualDirectory -externalurl $mapiexturl -internalurl $mapiinturl -Confirm:$false
Get-OutlookAnywhere -Server $Exchange2019Server | Set-OutlookAnywhere -externalhostname $OutlAnyExt -internalhostname $OutlAnyInt -ExternalClientsRequireSsl:$true -InternalClientsRequireSsl:$true -ExternalClientAuthenticationMethod 'Negotiate' -Confirm:$false
Get-ClientAccessService $Exchange2019Server | Set-ClientAccessService -AutoDiscoverServiceInternalUri $autodiscoverhostname -Confirm:$false
#Display setttings
Get-OwaVirtualDirectory | fl server,externalurl,internalurl
Get-EcpVirtualDirectory | fl server,externalurl,internalurl
Get-WebServicesVirtualDirectory | fl server,externalurl,internalurl
Get-ActiveSyncVirtualDirectory | fl server,externalurl,internalurl
Get-OabVirtualDirectory | fl server,externalurl,internalurl
Get-MapiVirtualDirectory | fl server,externalurl,internalurl
Get-OutlookAnywhere | fl servername,ExternalHostname,InternalHostname
Get-ClientAccessService | fl name,AutoDiscoverServiceInternalUri
