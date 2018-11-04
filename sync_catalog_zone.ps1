#----------------------------------------------------------------------------------------
# 2018 Daniel Heule (daniel.heule at gmail.com)
#
# This file is part of dns_catalog_helper.
#
#    dns_catalog_helper is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Foobar is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
#
#----------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------
# parameters 
#----------------------------------------------------------------------------------------
param(
  [string]$catalog = "",
  [switch]$dszones = $false,
  [switch]$dryrun = $false,
  [switch]$wait = $false
);

#----------------------------------------------------------------------------------------
# helper functions: 
#----------------------------------------------------------------------------------------


#http://jongurgul.com/blog/get-stringhash-get-filehash/ 
Function Get-StringHash([String] $String,$HashName = "MD5") 
{ 
$StringBuilder = New-Object System.Text.StringBuilder 
	[System.Security.Cryptography.HashAlgorithm]::Create($HashName).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($String))|%{ 
		[Void]$StringBuilder.Append($_.ToString("x2")) 
	} 
	$StringBuilder.ToString() 
}

#----------------------------------------------------------------------------------------
Function Get-NfzString([String] $dnsname)
#
#  Description:
#    This function will calculate the sha1 hash of the dns name in wire format.
#
#----------------------------------------------------------------------------------------
{
	$StringBuilder = New-Object System.Text.StringBuilder
	$arr = $dnsname -split '\.'
	Foreach($e in $arr) {
		[Void]$StringBuilder.Append([char]$e.length)
		[Void]$StringBuilder.Append($e)
	}
	[Void]$StringBuilder.Append([char]0)
	Get-StringHash $StringBuilder.ToString() SHA1
}


#----------------------------------------------------------------------------------------
function Show-Usage()
#
#  Description:
#    This function will print the script usage information.
#
#----------------------------------------------------------------------------------------
{
  Write-Host @"
Usage: sync_catalog_zone.ps1 Arguments
       Argument    - Description
       -----------   -----------
       catalog       - The DNS Name of the Catalog Zone
       dszones       - Use DsIntegrated Zones (switch)
       dryrun        - Only print what to do, not update the catalog zone (switch)
	   wait          - Wait for an enter at the end of the script to show the output
"@;
}

#----------------------------------------------------------------------------------------
# Main script ;-)
#----------------------------------------------------------------------------------------

if ( $catalog.Length -eq 0) {
  Show-Usage;
  Exit 1
}


$zonelistdns = Get-DnsServerZone | Where-Object { $_.ZoneType -eq "Primary" -and 
                                                  -not $_.IsAutoCreated -and 
                                                  $_.IsDsIntegrated -eq $dszones -and
                                                  $_.ZoneName -notin ($catalog,"TrustAnchors")}
#$zonelistdns

$zonelistcatalog = (Get-DnsServerResourceRecord -ZoneName $catalog -RRType Ptr | where HostName -Like *.zones)
#$zonelistcatalog 

# Find the zones to delete in the catalog
ForEach($z in $zonelistcatalog){
    $myzn = $z.RecordData.PtrDomainName -replace ".$"
    $zf = $zonelistdns | Where-Object { $_.ZoneName -eq $myzn }
    if ( $zf -eq $null ) {
        Write-Host "Removing $myzn with name $($z.HostName) from catalog"
        if ( -not $dryrun ) {
            $z | Remove-DnsServerResourceRecord -ZoneName $catalog -Force
        }
    }

}


# Find the zones to add to the catalog
ForEach($z in $zonelistdns){
    $cz = $zonelistcatalog | Where-Object { $x = $_.RecordData.PtrDomainName -replace ".$"; $x -eq $z.ZoneName }
    if ( $cz -eq $null ) {
        $mynfz = Get-NfzString $z.ZoneName
        Write-Host "Adding zone $($z.ZoneName) with hash $mynfz"
        if ( -not $dryrun ) {
            Add-DnsServerResourceRecord -Name "$($mynfz).zones" -Ptr -ZoneName $catalog -PtrDomainName $z.ZoneName
        }
    }
    
}

if ( $wait -eq $true ) {
	$e = Read-Host "Hit enter to close this window"
}