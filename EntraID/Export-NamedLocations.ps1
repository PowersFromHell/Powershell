#region - Variables and Azure AD token connection.

# - Define variables used in the script. Update values to match your environment.
$TenantDomainName = "DOMAIN.ONMICROSOFT.COM"
$ClientID = "YOUR APP REGISTRATION CLIENT ID"
$ClientSecret = "YOUR APP REGISTRATION CLIENT SECRET"
$ExportPath = "C:\Temp\output" #if path does not exist, the script will create it.

# - Set the token body as a hash table with the necessary parameters to obtain an access token.
$TokenBody = @{
    'grant_type'    = 'client_credentials'
    'Scope'         = "https://graph.microsoft.com/.default"
    'client_id'     = $ClientId
    'client_secret' = $ClientSecret
}

# - Use the Invoke-RestMethod cmdlet to send a POST request to the Azure AD token endpoint to obtain an access token
$TokenConnect = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$($TenantDomainName)/oauth2/v2.0/token" -Body $TokenBody
$AccessToken = $TokenConnect.access_token
#endregion

$NamedLocationsURI = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations"
$NamedLocations = Invoke-RestMethod -Headers @{Authorization = "Bearer $($AccessToken)" } -Uri $NamedLocationsURI -Method Get

# - Create a report on the named locations.
$NamedLocationsReport = foreach ($NamedLocation in $NamedLocations.value) {
    [PSCustomObject]@{
        DisplayName                       = $NamedLocation.displayName
        IsTrusted                         = $NamedLocation.IsTrusted
        IPranges                          = ($NamedLocation.ipranges.cidraddress -join ',')
        CountriesAndRegions               = ($NamedLocation.countriesAndRegions -join ',')
        includeUnknownCountriesAndRegions = $NamedLocation.includeUnknownCountriesAndRegions
        CreatedDate                       = $NamedLocation.createdDateTime
        modifiedDateTime                  = $NamedLocation.modifiedDateTime
    }
}
# Check if the path exists, and create it if it does not exist.
If (!(Test-Path -Path $ExportPath)) { New-Item -ItemType Directory -Path $ExportPath }
# Export the report to a CSV file using UTF8 encoding and ';' delimiter.
$NamedLocationsReport | Export-Csv -Path "$($ExportPath)\NamedLocations_Report.csv" -Encoding UTF8 -NoTypeInformation -Delimiter ';'