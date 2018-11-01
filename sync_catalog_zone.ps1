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
  [string]$catalog = ""
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
"@;
}

#----------------------------------------------------------------------------------------
# Main script ;-)
#----------------------------------------------------------------------------------------

if ( ($catalog.Length -eq 0) {
  Show-Usage;
}