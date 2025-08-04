#TTL im Windows DNS anpassen
Get-DnsServerResourceRecord -zonename "ZONENNAME"

Set-DnsServerResourceRecord -ZoneName "autodiscover.ekl-ag.de" -RRType "A" -Name "(same as parent folder)" -NewTimeToLive 00:05:00
