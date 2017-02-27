function Ignore-SelfSignedCerts
{
    try
    {
        Add-Type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy
        {
             public bool CheckValidationResult(
             ServicePoint srvPoint, X509Certificate certificate,
             WebRequest request, int certificateProblem)
             {
                 return true;
            }
        }
"@

      }
    catch
    {
    }

    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

Ignore-SelfSignedCerts


#Create a credential object 
$UserName = "name"
$SecurePassword = ConvertTo-SecureString "pass" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential $UserName, $SecurePassword

#Set the pool name and API URI
$PoolName = "$[poolname]"
$URI = "https://192.168.0.1/mgmt/tm/ltm/pool"

#Construct request
$JSONBody = @{name=$PoolName;partition='Common';members=@()}

#Create array of member objects
$Members = @()
$Members += @{name="$[server1_name]:80";address="$[server1_ip]";description="$[server1_description]"}
$Members += @{name="$[server2_name]:80";address="$[server2_ip]";description="$[server2_description]"}

#Add members to request
$JSONBody.members = $Members

#Convert request to JSON
$JSONBody = $JSONBody | ConvertTo-Json

#Make the request
Invoke-RestMethod -Method POST -Uri "$URI" -Credential $Credential -Body $JSONBody -Headers @{"Content-Type"="application/json"}
