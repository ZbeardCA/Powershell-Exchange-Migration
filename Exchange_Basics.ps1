# Anlegen vom Relay
New-ReceiveConnector -Name "Anonymous Relay" -TransportRole FrontendTransport -Custom -Bindings 0.0.0.0:25 -RemoteIpRanges 192.168.100.50, 192.168.100.51
Set-ReceiveConnector "Anonymous Relay" -PermissionGroups AnonymousUsers
Get-ReceiveConnector "Anonymous Relay" | Add-ADPermission -User "NT-Authority\Anonymous-Logon" -ExtendedRights "Ms-Exch-SMTP-Accept-Any-Recipient"

