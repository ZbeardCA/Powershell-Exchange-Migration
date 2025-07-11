# Umzug normales Posfach MIT Archiv

New-MoveRequest `
    -Identity "POSTFACHNAME" `
    -TargetDatabase "ZIELDATENBANK" `
    -ArchiveTargetDatabase "ZIELARCHIVDATENBANK" `
    -BadItemLimit 50 `
    -SuspendWhenReadyToComplete `
    -BatchName "NAMEVOMBATCH"



# Umzug mehrere Postfächer MIT Archiv.

$users = 'NAME'
>> foreach ($u in $users) {
>> New-MoveRequest `
>>     -Identity $u `
>>     -TargetDatabase "DATENBANKNAME" `
>>     -ArchiveTargetDatabase "ArchivMDB01" `
>>     -BadItemLimit 50 `
>>     -SuspendWhenReadyToComplete `
>>     -BatchName "Admin"
>> }

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

# Nur schon fertig gespulte Moves
Get-MoveRequest -BatchName "BATCHNAME" -MoveStatus Synced


