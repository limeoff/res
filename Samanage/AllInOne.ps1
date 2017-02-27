
# Version=0.7;Author=Ilya Feoktistov;TODO=check user existence in DomainUser class, add rest of services

###########################################
## DIFINING CUSTOMER INDEPENDEND CLASSES ##
###########################################

# In this part we defining non-customer specific classes, i.e. classes, which we can use in every customer environment with only minor (if any) changes.
# Inside class and class methods we could change logic and add diffrent features, but it is good to save initial output attributes in the same format.
# For example ticket.create() method returns hashtable with [string]ticket.create().IncidentID , [string]ticket.create().Status. It is good to safe this behaviour, so old programs can work with new versions application
# relies on https://www.samanage.com/api/

#Class for ticket management. Needs only one parameter - [PSCredential]Credentials with apropriate Samanage permissions.

class SamanageTicket{

#Only one global variable, which will be used in all methods
        [PSCredential]$Credentials

#Class constructor. We need this constructor to create new object of this class. Only one parameter - [PSCredential]Credentials.
        SamanageTicket([PSCredential]$Credentials){
            $this.Credentials=$Credentials
        }

<#
 Method CREATE - creates a ticket. 
 Parameters:
1) [String]$UserMail - user email, will be inserted in "Service request by" field
2) [String]$UserSite - user site (https://www.samanage.com/api/sites/). Will be inserted in Site field. Format: 
        <site>
            <name>Site name</name>
            <location>Location</location>
            <description>Description</description>
            <time-zone>Time zone</time-zone>
            <language>Language</language>
            <business-record-id>Business record ID</business-record-id>
        </site>
3) [String]$UserDepartment - user department (https://www.samanage.com/api/departments/). Will be inserted in Department field. Format:
    <department>
        <name>Site name</name>
        <description>Description</description>
    </department>
4) [string]$IncidentName -Incident name. Incident name field
5) [string]$IncidentDescription -Incident description. Incident description field
6) [string]$IncidentClassification - Classification field
7) [string]$IncidentCause - Cause field
 Output:
 HashTable with 3 string values @{Status="";Message="";IncidentID=""}
#>

        [hashtable]create([String]$UserMail,[String]$UserSite,[String]$UserDepartment,[string]$IncidentName,[string]$IncidentDescription,[string]$IncidentClassification,[string]$IncidentCause){

            [xml]$Body=""
            [Hashtable]$params=@{}
            [Hashtable]$output=@{Status="";Message="";IncidentID=""}

#Generating the request body

            $Body = [xml]@"
                <incident>
                    <name>$IncidentName</name>
                    <description>$IncidentDescription</description>
                    <state>New</state>
                    <priority>Medium</priority>
                    <requester>
                        <email>$UserMail</email>
                    </requester>
                    <assignee>
                        <id>1432556</id>
                        <name>My Itadmin</name>
                        <email>myitadmin@movenpick.com</email>
                    </assignee>        
                    $UserSite
                    $UserDepartment
                    <category>
                        <name>Service Request</name>
                    </category>
                    <subcategory>
                        <name>User</name>
                    </subcategory>
                    <custom_fields_values>
                        <custom_fields_value>
                        <custom_field_id>11114</custom_field_id>
                        <name>Classification</name>
                        <value>$IncidentClassification</value>
                        </custom_fields_value>
                        <custom_fields_value>
                        <custom_field_id>11250</custom_field_id>
                        <name>Cause Item</name>
                        <value>$IncidentCause</value>
                        </custom_fields_value>
                    </custom_fields_values>
                </incident>
"@

#Params for Invoke-RestMethod
            $params = @{
                Credential = $this.Credentials
                Headers = @{ "Accept" = "application/vnd.samanage.v1.1+xml" }
                uri = "https://api.samanage.com/incidents.xml"
                ContentType = "text/xml"
                Method = "POST"
                body = $Body
            }

#Performing request with generated parameters
        try {
            $incident = Invoke-RestMethod @params
            $output=@{
                Status = "OK"
                IncidentID = $incident.incident.id
            }
        }
        catch {
            $output=@{
                Status = "ERROR"
                Message = $_.Exception.Response.StatusCode
            }    
        }
        return $output
    }


<#
 Method RESOLVE - resolves the ticket.
 Parameters:
1) [string]$TicketNumber - to resolve the ticket we need only one parameter - ticket number
 Output:
 HashTable with 2 string values @{Status="";Message=""}
#>

    [hashtable]resolve([string]$TicketNumber)
    {
        [Hashtable]$output=@{Status="";Message=""}

#Generating the body and rest-method params:
        $body = [xml]@"
            <incident>
                <state>Resolved</state>
                <priority>Medium</priority>
            </incident>
"@

        $params = @{
            Credential = $this.Credentials
            Uri = "https://api.samanage.com/incidents/$TicketNumber.xml"
            Headers = @{ "Accept" = "application/vnd.samanage.v1.1+xml" }
            ContentType = "text/xml"
            Method = "Put"
            body = $body
        }

#Performing request:
        try {
            $incident = Invoke-RestMethod @params
            $output = @{
                Status = "OK"
                Message = $incident.incident.state
            }
        }
        catch {
            $output = @{
                Status = "ERROR"
                Message = $_.Exception.Response.StatusDescription
            }              
        }  
        return $output
    }

<#
 Method OnHold - puts the ticket OnHold. We need this state in case of performing manual tasks, or other tasks, which need some additional steps to execute.
 Parameters:
1) [string]$TicketNumber - to put the ticket OnHold we need only one parameter - ticket number
 Output:
 HashTable with 2 string values @{Status="";Message=""}
#>

    [hashtable]OnHold([string]$TicketNumber)
    {
        [Hashtable]$output=@{Status="";Message=""}

        $body = [xml]@"
            <incident>
                <state>On Hold</state>
                <priority>Medium</priority>
            </incident>
"@

        $params = @{
            Credential = $this.Credentials
            Uri = "https://api.samanage.com/incidents/$TicketNumber.xml"
            Headers = @{ "Accept" = "application/vnd.samanage.v1.1+xml" }
            ContentType = "text/xml"
            Method = "Put"
            body = $body
        }


        try {
            $incident = Invoke-RestMethod @params
            $output = @{
                Status = "OK"
                Message = $incident.incident.state
            }
        }
        catch {
            $output = @{
                Status = "OK"
                Message = $_.Exception.Response.StatusDescription
            } 
        }
        return $output  
    }

<#
 Method AddComment - adds a comment to the ticket. 
 Parameters:
1) [string]$TicketNumber - to put the ticket OnHold we need only one parameter - ticket number
2) [string]$Comment - comment
 Output:
 HashTable with 2 string values @{Status="";Message=""}
#>
    [hashtable]AddComment([string]$TicketNumber,[string]$Comment)
    {
        [Hashtable]$output=@{Status="";Message=""}

        $body = [xml]@"
            <comment>
                <body>$Comment</body>
                <is_private>true</is_private>
            </comment>
"@

        $params = @{
            Credential = $this.Credentials
            Uri = "https://api.samanage.com/incidents/$TicketNumber/comments.xml"
            Headers = @{ "Accept" = "application/vnd.samanage.v1.1+xml" }
            ContentType = "text/xml"
            Method = "POST"
            body = $body
        }

        try {
            $comment = Invoke-RestMethod @params
            $output = @{
                Status = "OK"
                Message = $comment.comment.state
            }
        }
        catch {
            $output = @{
                Status = "OK"
                Message = $_.Exception.Response.StatusDescription
            }     
        }
        return $output  
    } 
}


#Class for collecting Samanage user properties
#one global variable - Samange Credentials

class SamanageUser{

    [PSCredential]$Credentials

#Constructor
    SamanageUser([PSCredential]$Credentials){
        $this.Credentials=$Credentials
    }

<#
 Method GetUserSiteDetails - gets user site info (https://www.samanage.com/api/sites/)
 Parameters:
1) [string]$UserSite - user site. In Movenpick case we will get this parameter from AD extended attribute 3
 Output:
        <site>
            <name>Site name</name>
            <location>Location</location>
            <description>Description</description>
            <time-zone>Time zone</time-zone>
            <language>Language</language>
            <business-record-id>Business record ID</business-record-id>
        </site>
#>
    [string]GetUserSiteDetails([string]$UserSite){
        $ParamsSites = @{
            Credential = $this.Credentials
            Headers = @{ "Accept" = "application/vnd.samanage.v1.1+xml" }
            uri = "https://api.samanage.com/sites.xml"
            ContentType = "text/xml"
            Method = "GET"
        }
        if ($UserSite -eq "allsites"){
            $UserSiteDetailed = (Invoke-RestMethod @ParamsSites).sites.site.outerxml
        }
        else {
            $UserSiteDetailed = ((Invoke-RestMethod @ParamsSites).sites.site | Where-Object {$_.name -match $UserSite}).OuterXml
        }
        return $UserSiteDetailed
    }

<#
 Method GetUserDepartmentDetails - gets user department info (https://www.samanage.com/api/departments/)
 Parameters:
1) [string]$UserDepartment - user department. In Movenpick case we will get this parameter from AD extended attribute 8
 Output:
    <department>
        <name>Site name</name>
        <description>Description</description>
    </department>
#>


    [string]GetUserDepartmentDetails([string]$UserDepartment){
        $ParamsDepartments = @{
            Credential = $this.Credentials
            Headers = @{ "Accept" = "application/vnd.samanage.v1.1+xml" }
            uri = "https://api.samanage.com/departments.xml"
            ContentType = "text/xml"
            Method = "GET"
        }

        if ($UserDepartment -eq "alldepartments"){
            $UserDepartmentDetailed = (Invoke-RestMethod @ParamsDepartments).departments.department.outerxml
        }
        else {
            $UserDepartmentDetailed = ((Invoke-RestMethod @ParamsDepartments).departments.department | Where-Object {$_.name -match $UserDepartment -and $_.id -notmatch "31901"}).OuterXml
        }
        return $UserDepartmentDetailed
    }
}

#Class Domain user. With objects of this class we will query domain for user attributes.

class DomainUser{
    [String]$UserName
    [String]$DomainServer

    DomainUser([String]$UserName,[String]$DomainServer){
        $this.UserName=$UserName
        $this.DomainServer=$DomainServer
    }

    [hashtable]GetProperties(){
        $user = Get-ADUser -identity $this.UserName -Server $this.DomainServer -Properties *
        $properties=@{
            mail=$user.EmailAddress
            site=$user.extensionAttribute8
            department=$user.extensionAttribute3
        }
    return $properties
    }
}

#Class Credentials. Requires two parameters - UserName and Password. Password can be plane password or secured string

class Credentials{

    [String]$UserName
    [String]$Password

    Credentials([String]$UserName,[String]$Password){
        $this.Username=$UserName
        $this.Password=$Password
    }

#Method for generating from plane password.Less secure

    [PSCredential]GenerateFromPlanePass(){
        $Secstr = New-Object -TypeName System.Security.SecureString
        $this.Password.ToCharArray() | ForEach-Object { $secstr.AppendChar($_) }
        $cred=new-object -typename System.Management.Automation.PSCredential -argumentlist $this.username, $secstr
        return $cred
    }

# Method for generating credentials from secure string. More secure. First, we need to generate secure string from plane text password
# $Password | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -key $key
# We use predifined key to have ability to use this secure string on diffrent PC
# This key, as well as SecureString of password will be stored in Automation Varables [SecureKey] and [SecurePassword]
    [PSCredential]GenerateFromSecurePass($key){   
        $Secstr = ConvertTo-SecureString -String $this.password  -Key $key
        $cred=new-object -typename System.Management.Automation.PSCredential -argumentlist $this.username, $secstr
        return $cred
    }
}




############################################################################
### Customer-specific part. Here we will create objects and call methods ###
############################################################################

# Here will be placed all services. Direction of program executing will be determined by "SamanageService" parameter and "switch" operator below. 
# For example we are doing user onboarding. In workflow we add Invoke RunBook "user onboarding", which contains tak "manage Samanage ticket", and set it's attribute SamanageService to "UserOnboardingADTasks".
# It will create user in AD and create ticket, then it will put ticket in OnHold state, because we need to do some manual tasks.
# Then manual tasks will be done, in ServiceStore Workflow we will call RunBook "Manage Samanage ticket" with attribute SamanageService = "UserOnboardingProvideEquip" and it will add comment and resolve ticket.

#This part is common for all services, so we can put it before switch opeartor

#ServiceStore attribure "SamanageService"
$Service="$[SamanageService]"

#Samanage user with write permissions
$UserNameSamanage = "binosh.moothedan@movenpick.com"

#Generated (with ConvertTo-SecureString etc) password hash, stored in Automation variable, in our case "76492d1116743f0423413b16050a5345MgB8AHYASwA5AEwAUwBhAFYAdgA0AHIAcgB4AGIATQBvAFAAegBNAHQAYgAwAGcAPQA9AHwAOQA3ADcAMgBjAGIAOAA3ADkAZgBhADYAMgAwADIAMwA4AGMANwA5ADcAZAA5AGMAZQBiADEAYwAxAGUAMgBjADMAYgBhADkANgBjADgAZgA1ADMAZAAzADMAZgBjADMANAAyADgAZgA1AGUAZQAyADYANgAwADMAMgA1AGIAZAA="
$PasswordSamanage = "^[SecurePassword]"

#Secure encryption key, to have ability to use SecurePassword on all computers. Stored in Automation variable, in our case (3,4,2,3,56,34,254,222,1,1,2,23,42,54,33,233,1,34,2,7,6,5,35,43)
$SecureKey= ^[SecureKey]

#Generating cred from secure password
$cred=[Credentials]::new($UserNameSamanage,$PasswordSamanage).GenerateFromSecurePass($SecureKey)

#Creating an ticket object
$ticket=[SamanageTicket]::new($cred)



#Specific part, based on service and workflow
switch($service){

    #User onboarding tasks. After performing UserOnboardingADTasks we will save ticket number in SamanageOutput attribute, to use it for closing, adding comments etc in future.

    UserOnboardingADTasks{
    #UserName from ServiceStore attribute
        $user="$[SamanageRequesterName]"
        $ADServer="SC000968.mpintra.ch"

    #Creating a new user obnect and invoking method GetPropeties()
        $UserProperties=[DomainUser]::new("$user","$ADServer").GetProperties()

    #User site from AD
        $UserSite=$UserProperties.site
        if ($UserSite -like "Corporate Centre IT Dubai"){$UserSite="Corporate Center IT Dubai"}

    #User department from AD
        $UserDepartment=$UserProperties.department

    #User mail from AD
        $UserMail=$UserProperties.mail

    #Getting user department and site from Samanage
        $SamUser=[samanageuser]::new($cred)
        $SamanageUserSite=$SamUser.GetUserSiteDetails($UserSite)
        $SamanageUserDepartment=$samuser.getUserDepartmentDetails($UserDepartment)

    #Setting incident parameters
        $IncidentName="User $[SamanageUserName] onboarding"
        $IncidentDescription="User $[SamanageUserName] onboarding in $[SamanageUserDepartment] department"
        $IncidentClassification="$[IncidentClassification]"
        $IncidentCause="$[IncidentCause]"

    #Ticket creation,adding comments, putting it to OnHold
        $IncidentCreataion=$ticket.create($UserMail,$samanageusersite,$SamanageUserDepartment,$service,$IncidentName,$IncidentDescription,$IncidentClassification,$IncidentCause)
        if ($IncidentCreataion.Status -eq "OK"){
            $TicketNumber = $IncidentCreataion.IncidentID
            $comment1="User was created. Logon name is $[SamanageUserName]. Default password is $[SamanagePassword]. User has to change password on first logon. "
            $ticket.AddComment($TicketNumber,$comment) | Out-Null
            $comment2="$[SamanageTasks] are in process"
            $ticket.AddComment($TicketNumber,$comment2) | Out-Null
            $ticket.OnHold($TicketNumber) | Out-Null

    #And we will store output (TicketNumber) in ServiceStore attribute SamanageOutput
            $TicketNumber
        }
        else {
            write-host $IncidentCreataion.Message
        } 
    }

    #User onboarding after providing equipment.
    UserOnboardingProvideEquip{
        $ticket.resolve("$[SamanageOutput]")
        $comment="Equipment provided"
        $ticket.addcomment("$[SamanageOutput]",$comment)
    }

#### Here will be another services, like EditPersonalInformation, adding to LocalAdminGroup etc

}

