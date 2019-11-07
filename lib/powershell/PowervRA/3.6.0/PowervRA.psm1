<#
     _____                             _____            
    |  __ \                           |  __ \     /\    
    | |__) |____      _____ _ ____   _| |__) |   /  \   
    |  ___/ _ \ \ /\ / / _ \ '__\ \ / /  _  /   / /\ \  
    | |  | (_) \ V  V /  __/ |   \ V /| | \ \  / ____ \ 
    |_|   \___/ \_/\_/ \___|_|    \_/ |_|  \_\/_/    \_\

#>

# --- Clean up vRAConnection variable on module remove
$ExecutionContext.SessionState.Module.OnRemove = {

    Remove-Variable -Name vRAConnection -Force -ErrorAction SilentlyContinue

}
<#
    - Function: NewDynamicParam
#>

Function NewDynamicParam {
<#
    .SYNOPSIS
        Helper function to simplify creating dynamic parameters
    
    .DESCRIPTION
        Helper function to simplify creating dynamic parameters

        Example use cases:
            Include parameters only if your environment dictates it
            Include parameters depending on the value of a user-specified parameter
            Provide tab completion and intellisense for parameters, depending on the environment

        Please keep in mind that all dynamic parameters you create will not have corresponding variables created.
           One of the examples illustrates a generic method for populating appropriate variables from dynamic parameters
           Alternatively, manually reference $PSBoundParameters for the dynamic parameter value

    .NOTES
        Note: NewDynamicParam function from @PSCookieMonster https://github.com/RamblingCookieMonster/PowerShell/blob/master/New-DnamicParam.ps1
        
        Credit to http://jrich523.wordpress.com/2013/05/30/powershell-simple-way-to-add-dynamic-parameters-to-advanced-function/
            Added logic to make option set optional
            Added logic to add RuntimeDefinedParameter to existing DPDictionary
            Added a little comment based help

        Credit to BM for alias and type parameters and their handling

    .PARAMETER Name
        Name of the dynamic parameter

    .PARAMETER Type
        Type for the dynamic parameter.  Default is string

    .PARAMETER Alias
        If specified, one or more aliases to assign to the dynamic parameter

    .PARAMETER ValidateSet
        If specified, set the ValidateSet attribute of this dynamic parameter

    .PARAMETER Mandatory
        If specified, set the Mandatory attribute for this dynamic parameter

    .PARAMETER ParameterSetName
        If specified, set the ParameterSet attribute for this dynamic parameter

    .PARAMETER Position
        If specified, set the Position attribute for this dynamic parameter

    .PARAMETER ValueFromPipelineByPropertyName
        If specified, set the ValueFromPipelineByPropertyName attribute for this dynamic parameter

    .PARAMETER HelpMessage
        If specified, set the HelpMessage for this dynamic parameter
    
    .PARAMETER DPDictionary
        If specified, add resulting RuntimeDefinedParameter to an existing RuntimeDefinedParameterDictionary (appropriate for multiple dynamic parameters)
        If not specified, create and return a RuntimeDefinedParameterDictionary (appropriate for a single dynamic parameter)

        See final example for illustration

    .EXAMPLE
        
        function Show-Free
        {
            [CmdletBinding()]
            Param()
            DynamicParam {
                $options = @( gwmi win32_volume | %{$_.driveletter} | sort )
                NewDynamicParam -Name Drive -ValidateSet $options -Positin 0 -Mandatory
            }
            begin{
                #have to manually populate
                $drive = $PSBoundParameters.drive
            }
            process{
                $vol = gwmi win32_volume -Filter "driveletter='$drive'"
                "{0:N2}% free on {1}" -f ($vol.Capacity / $vol.FreeSpace),$drive
            }
        } #Show-Free

        Show-Free -Drive <tab>

    # This example illustrates the use of NewDynamicParam to create a single dyamic parameter
    # The Drive parameter ValidateSet populates with all available volumes on the computer for handy tab completion / intellisense

    .EXAMPLE

    # I found many cases where I needed to add more than one dynamic parameter
    # The DPDictionary parameter lets you specify an existing dictionary
    # The block of code in the Begin block loops through bound parameters and defines variables if they don't exist

        Function Test-DynPar{
            [cmdletbinding()]
            param(
                [string[]]$x = $Null
            )
            DynamicParam
            {
                #Create the RuntimeDefinedParameterDictionary
                $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
                NewDynamicParam -Name AlwaysParam -ValidateSet @( gwmi win32_volume | %{$_.driveletter} | sort ) -DPDictionry $Dictionary

                #Add dynamic parameters to $dictionary
                if($x -eq 1)
                {
                    NewDynamicParam -Name X1Param1 -ValidateSet 1,2 -mandatory -DPDictionry $Dictionary
                    NewDynamicParam -Name X1Param2 -DPDictionry $Dictionary
                    NewDynamicParam -Name X3Param3 -DPDictionary $Dictionary-Type DateTime
                }
                else
                {
                    NewDynamicParam -Name OtherParam1 -Mandatory -DPDictionry $Dictionary
                    NewDynamicParam -Name OtherParam2 -DPDictionry $Dictionary
                    NewDynamicParam -Name OtherParam3 -DPDictionary $Dictionary-Type DateTime
                }
        
                #return RuntimeDefinedParameterDictionary
                $Dictionary
            }
            Begin
            {
                #This standard block of code loops through bound parameters...
                #If no corresponding variable exists, one is created
                    #Get common parameters, pick out bound parameters not in that set
                    Function intTemp { [cmdletbinding()] param() }
                    $BoundKeys = $PSBoundParameters.keys | Where-Object { (get-command intTemp | select -ExpandProperty parameters).Keys -notcontains $_}
                    foreach($param in $BoundKeys)
                    {
                        if (-not ( Get-Variable -name $param -scope 0 -ErrorAction SilentlyContinue ) )
                        {
                            New-Variable -Name $Param -Value $PSBoundParameters.$param
                            Write-Verbose "Adding variable for dynamic parameter '$param' with value '$($PSBoundParameters.$param)'"
                        }
                    }

                #Appropriate variables should now be defined and accessible
                    Get-Variable -scope 0
            }
        }

    # This example illustrates the creation of many dynamic parameters using Nw-DynamicParam
        # You must create a RuntimeDefinedParameterDictionary object ($dictionary here)
        # To each NewDynamicParam call, add the -DPDictionary parameter pointing to this RuntimeDefinedParaeterDictionary
        # At the end of the DynamicParam block, return the RuntimeDefinedParameterDictionary
        # Initialize all bound parameters using the provided block or similar code

    .FUNCTIONALITY
        PowerShell Language

#>
param(
    
    [string]
    $Name,
    
    [System.Type]
    $Type = [string],

    [string[]]
    $Alias = @(),

    [string[]]
    $ValidateSet,
    
    [switch]
    $Mandatory,
    
    [string]
    $ParameterSetName="__AllParameterSets",
    
    [int]
    $Position,
    
    [switch]
    $ValueFromPipelineByPropertyName,
    
    [string]
    $HelpMessage,

    [validatescript({
        if(-not ( $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] -or -not $_) )
        {
            Throw "DPDictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object, or not exist"
        }
        $True
    })]
    $DPDictionary = $false
 
)
    #Create attribute object, add attributes, add to collection   
        $ParamAttr = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttr.ParameterSetName = $ParameterSetName
        if($mandatory)
        {
            $ParamAttr.Mandatory = $True
        }
        if($Position -ne $null)
        {
            $ParamAttr.Position=$Position
        }
        if($ValueFromPipelineByPropertyName)
        {
            $ParamAttr.ValueFromPipelineByPropertyName = $True
        }
        if($HelpMessage)
        {
            $ParamAttr.HelpMessage = $HelpMessage
        }
 
        $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
        $AttributeCollection.Add($ParamAttr)
    
    #param validation set if specified
        if($ValidateSet)
        {
            $ParamOptions = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet
            $AttributeCollection.Add($ParamOptions)
        }

    #Aliases if specified
        if($Alias.count -gt 0) {
            $ParamAlias = New-Object System.Management.Automation.AliasAttribute -ArgumentList $Alias
            $AttributeCollection.Add($ParamAlias)
        }

 
    #Create the dynamic parameter
        $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, $Type, $AttributeCollection)
    
    #Add the dynamic parameter to an existing dynamic parameter dictionary, or create the dictionary and add it
        if($DPDictionary)
        {
            $DPDictionary.Add($Name, $Parameter)
        }
        else
        {
            $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $Dictionary.Add($Name, $Parameter)
            $Dictionary
        }
}

<#
    - Function: xRequires
#>

function xRequires {
<#
    .SYNOPSIS
    Checks the required API Version for the current function

    .DESCRIPTION
    Checks the required API Version for the current function

    .PARAMETER Version
    The API Version that the function supports.

    The version number passed to this parameter must be in the following format.. it can't be a single character.

    - 6.2.4
    - 7.0
    - 7.0.1
    - 7.1
    - 7.2

    .INPUTS
    System.Int
    System.Management.Automation.PSObject.

    .OUTPUTS
    None

    .EXAMPLE

    function Get-Example {

        # This function does not support API versions lower than Version 7
        xRequires -Version "7.0"

    }

#>

[CmdletBinding()][Alias("FunctionRequires")]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [String]$Version
    )

    # --- Test for vRA API version
    if (-not $Global:vRAConnection){
        throw "vRA Connection variable does not exist. Please run Connect-vRAServer first to create it"
    }

    # --- Convert version strings to [version] objects
    $APIVersion = [version]$Global:vRAConnection.APIVersion
    $RequiredVersion = [version]$Version

    if ($APIVersion -lt $RequiredVersion) {
        $PSCallStack = Get-PSCallStack
        Write-Error -Message "$($PSCallStack[1].Command) is not supported with vRA API version $($Global:vRAConnection.APIVersion)"
        break
    }
}

<#
    - Function: Connect-vRAServer
#>

function Connect-vRAServer {
<#
    .SYNOPSIS
    Connect to a vRA Server

    .DESCRIPTION
    Connect to a vRA Server and generate a connection object with Servername, Token etc

    .PARAMETER Server
    vRA Server to connect to

    .PARAMETER Tenant
    Tenant to connect to

    .PARAMETER Username
    Username to connect with
    For domain accounts ensure to specify the Username in the format username@domain, not Domain\Username

    .PARAMETER Password
    Password to connect with

    .PARAMETER Credential
    Credential object to connect with
    For domain accounts ensure to specify the Username in the format username@domain, not Domain\Username

    .PARAMETER IgnoreCertRequirements
    Ignore requirements to use fully signed certificates

    .PARAMETER SslProtocol
    Alternative Ssl protocol to use from the default
    Requires vRA 7.x and above
    Windows PowerShell: Ssl3, Tls, Tls11, Tls12
    PowerShell Core: Tls, Tls11, Tls12

    .INPUTS
    System.String
    System.SecureString
    Management.Automation.PSCredential
    Switch

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    $cred = Get-Credential
    Connect-vRAServer -Server vraappliance01.domain.local -Tenant Tenant01 -Credential $cred

    .EXAMPLE
    $SecurePassword = ConvertTo-SecureString “P@ssword” -AsPlainText -Force
    Connect-vRAServer -Server vraappliance01.domain.local -Tenant Tenant01 -Username TenantAdmin01 -Password $SecurePassword -IgnoreCertRequirements
#>
[CmdletBinding(DefaultParametersetName="Username")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Server,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Tenant = "vsphere.local",

        [parameter(Mandatory=$true,ParameterSetName="Username")]
        [ValidateNotNullOrEmpty()]
        [String]$Username,

        [parameter(Mandatory=$true,ParameterSetName="Username")]
        [ValidateNotNullOrEmpty()]
        [SecureString]$Password,

        [Parameter(Mandatory=$true,ParameterSetName="Credential")]
        [ValidateNotNullOrEmpty()]
        [Management.Automation.PSCredential]$Credential,

        [parameter(Mandatory=$false)]
        [Switch]$IgnoreCertRequirements,

        [parameter(Mandatory=$false)]
        [ValidateSet('Ssl3', 'Tls', 'Tls11', 'Tls12')]
        [String]$SslProtocol
    )

    # --- Handle untrusted certificates if necessary
    $SignedCertificates = $true

    if ($PSBoundParameters.ContainsKey("IgnoreCertRequirements") ){

        if (!$IsCoreCLR) {

            if ( -not ("TrustAllCertsPolicy" -as [type])) {

                Add-Type @"
                using System.Net;
                using System.Security.Cryptography.X509Certificates;
                public class TrustAllCertsPolicy : ICertificatePolicy {
                    public bool CheckValidationResult(
                        ServicePoint srvPoint, X509Certificate certificate,
                        WebRequest request, int certificateProblem) {
                        return true;
                    }
                }
"@
            }
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

        }

        $SignedCertificates = $false

    }

    # --- Security Protocol
    $SslProtocolResult = 'Default'

    if ($PSBoundParameters.ContainsKey("SslProtocol") ){

        if (!$IsCoreCLR) {

            $CurrentProtocols = ([System.Net.ServicePointManager]::SecurityProtocol).toString() -split ', '
            if (!($SslProtocol -in $CurrentProtocols)){

                [System.Net.ServicePointManager]::SecurityProtocol += [System.Net.SecurityProtocolType]::$($SslProtocol)
            }
        }
        $SslProtocolResult = $SslProtocol
    }

    # --- Convert Secure Credentials to a format for sending in the JSON payload
    if ($PSBoundParameters.ContainsKey("Credential")){

        $Username = $Credential.UserName
        $JSONPassword = $Credential.GetNetworkCredential().Password
    }

    if ($PSBoundParameters.ContainsKey("Password")){

        $JSONPassword = (New-Object System.Management.Automation.PSCredential("username", $Password)).GetNetworkCredential().Password
    }

    # --- Test for a '\' in the username, e.g. DOMAIN\Username, not supported by the API
    if ($Username -match '\\'){

        throw "The Username format DOMAIN\Username is not supported by the vRA REST API. Please use username@domain instaed"
    }

    try {

        # --- Create Invoke-RestMethod Parameters
        $JSON = @{
            username = $Username
            password = $JSONPassword
            tenant = $Tenant
        } | ConvertTo-Json

        $Params = @{

            Method = "POST"
            URI = "https://$($Server)/identity/api/tokens"
            Headers = @{
                "Accept"="application/json";
                "Content-Type" = "application/json";
            }
            Body = $JSON

        }

        if ((!$SignedCertificate) -and ($IsCoreCLR)) {

            $Params.Add("SkipCertificateCheck", $true)

        }

        if (($SslProtocolResult -ne 'Default') -and ($IsCoreCLR)) {

            $Params.Add("SslProtocol", $SslProtocol)

        }

        $Response = Invoke-RestMethod @Params

        # --- Create Output Object
        $Global:vRAConnection = [PSCustomObject] @{

            Server = "https://$($Server)"
            Token = $Response.id
            Tenant = $Null
            Username = $Username
            APIVersion = $Null
            SignedCertificates = $SignedCertificates
            SslProtocol = $SslProtocolResult
        }

        # --- Update vRAConnection with tenant and api version
        $Global:vRAConnection.Tenant = (Get-vRATenant -Id $Tenant).id
        $Global:vRAConnection.APIVersion = (Get-vRAVersion).APIVersion

    }
    catch [Exception]{

        throw

    }

    Write-Output $vRAConnection

}


<#
    - Function: Disconnect-vRAServer
#>

function Disconnect-vRAServer {
<#
    .SYNOPSIS
    Disconnect from a vRA server

    .DESCRIPTION
    Disconnect from a vRA server by removing the authorization token and the global vRAConnection variable from PowerShell

    .EXAMPLE
    Disconnect-vRAServer

    .EXAMPLE
    Disconnect-vRAServer -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param ()

    # --- Test for existing connection to vRA
    if (-not $Global:vRAConnection){

        throw "vRA Connection variable does not exist. Please run Connect-vRAServer first to create it"
    }

    if ($PSCmdlet.ShouldProcess($Global:vRAConnection.Server)){

        try {

            # --- Remove the token from vRA and remove the global PowerShell variable
            $URI = "/identity/api/tokens/$($Global:vRAConnection.Token)"
            Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference

            # --- Remove custom Security Protocol if it has been specified
            if ($Global:vRAConnection.SslProtocol -ne 'Default'){

                if (!$IsCoreCLR) {

                    [System.Net.ServicePointManager]::SecurityProtocol -= [System.Net.SecurityProtocolType]::$($Global:vRAConnection.SslProtocol)
                }
            }

        }
        catch [Exception]{

            throw

        }
        finally {

            Write-Verbose -Message "Removing vRAConnection global variable"
            Remove-Variable -Name vRAConnection -Scope Global -Force -ErrorAction SilentlyContinue

        }

    }

}

<#
    - Function: Invoke-vRARestMethod
#>

function Invoke-vRARestMethod {
<#
    .SYNOPSIS
    Wrapper for Invoke-RestMethod/Invoke-WebRequest with vRA specifics

    .DESCRIPTION
    Wrapper for Invoke-RestMethod/Invoke-WebRequest with vRA specifics

    .PARAMETER Method
    REST Method:
    Supported Methods: GET, POST, PUT,DELETE

    .PARAMETER URI
    API URI, e.g. /identity/api/tenants

    .PARAMETER Headers
    Optionally supply custom headers

    .PARAMETER Body
    REST Body in JSON format

    .PARAMETER OutFile
    Save the results to a file

    .PARAMETER WebRequest
    Use Invoke-WebRequest rather than the default Invoke-RestMethod

    .INPUTS
    System.String
    Switch

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Invoke-vRARestMethod -Method GET -URI '/identity/api/tenants'

    .EXAMPLE
    $JSON = @"
        {
          "name" : "Tenant02",
          "description" : "This is Tenant02",
          "urlName" : "Tenant02",
          "contactEmail" : "test.user@tenant02.local",
          "id" : "Tenant02",
          "defaultTenant" : false,
          "password" : ""
        }
    "@

    Invoke-vRARestMethod -Method PUT -URI '/identity/api/tenants/Tenant02' -Body $JSON -WebRequest
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true, ParameterSetName="Standard")]
        [Parameter(Mandatory=$true, ParameterSetName="Body")]
        [Parameter(Mandatory=$true, ParameterSetName="OutFile")]
        [ValidateSet("GET","POST","PUT","DELETE")]
        [String]$Method,

        [Parameter(Mandatory=$true, ParameterSetName="Standard")]
        [Parameter(Mandatory=$true, ParameterSetName="Body")]
        [Parameter(Mandatory=$true, ParameterSetName="OutFile")]
        [ValidateNotNullOrEmpty()]
        [String]$URI,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [Parameter(Mandatory=$false, ParameterSetName="Body")]
        [Parameter(Mandatory=$false, ParameterSetName="OutFile")]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary]$Headers,

        [Parameter(Mandatory=$false, ParameterSetName="Body")]
        [ValidateNotNullOrEmpty()]
        [String]$Body,

        [Parameter(Mandatory=$false, ParameterSetName="OutFile")]
        [ValidateNotNullOrEmpty()]
        [String]$OutFile,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [Parameter(Mandatory=$false, ParameterSetName="Body")]
        [Parameter(Mandatory=$false, ParameterSetName="OutFile")]
        [Switch]$WebRequest
    )

    # --- Test for existing connection to vRA
    if (-not $Global:vRAConnection){

        throw "vRA Connection variable does not exist. Please run Connect-vRAServer first to create it"
    }

    # --- Create Invoke-RestMethod Parameters
    $FullURI = "$($Global:vRAConnection.Server)$($URI)"

    # --- Add default headers if not passed
    if (!$PSBoundParameters.ContainsKey("Headers")){

        $Headers = @{

            "Accept"="application/json";
            "Content-Type" = "application/json";
            "Authorization" = "Bearer $($Global:vRAConnection.Token)";
        }
    }

    # --- Set up default parmaeters
    $Params = @{

        Method = $Method
        Headers = $Headers
        Uri = $FullURI
    }

    if ($PSBoundParameters.ContainsKey("Body")) {

        $Params.Add("Body", $Body)

        # --- Log the payload being sent to the server
        Write-Debug -Message $Body

    } elseif ($PSBoundParameters.ContainsKey("OutFile")) {

        $Params.Add("OutFile", $OutFile)

    }

    # --- Support for PowerShell Core certificate checking
    if (!($Global:vRAConnection.SignedCertificates) -and ($IsCoreCLR)) {

        $Params.Add("SkipCertificateCheck", $true);
    }

    # --- Support for PowerShell Core SSL protocol checking
    if (($Global:vRAConnection.SslProtocol -ne 'Default') -and ($IsCoreCLR)) {

        $Params.Add("SslProtocol", $Global:vRAConnection.SslProtocol);
    }

    try {

        # --- Use either Invoke-WebRequest or Invoke-RestMethod
        if ($PSBoundParameters.ContainsKey("WebRequest")) {

            Invoke-WebRequest @Params
        }
        else {

            Invoke-RestMethod @Params
        }
    }
    catch {

        throw $_
    }
    finally {

        if (!$IsCoreCLR) {

            <#
                Workaround for bug in Invoke-RestMethod. Thanks to the PowerNSX guys for pointing this one out
                https://bitbucket.org/nbradford/powernsx/src
            #>
            $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($FullURI)
            $ServicePoint.CloseConnectionGroup("") | Out-Null
        }
    }
}

<#
    - Function: Get-vRAServiceBlueprint
#>

function Get-vRAServiceBlueprint {
<#
    .SYNOPSIS
    Retrieve vRA ASD Blueprints
    
    .DESCRIPTION
    Retrieve vRA ASD Blueprints
    
    .PARAMETER Id
    Specify the ID of an ASD Blueprint

    .PARAMETER Name
    Specify the Name of an ASD Blueprint

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAServiceBlueprint
    
    .EXAMPLE
    Get-vRAServiceBlueprint -Id "309100fd-b8ce-4e8c-ac8c-a667b8ace54f"

    .EXAMPLE
    Get-vRAServiceBlueprint -Name "ASDBlueprint01","ASDBlueprint02"
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,         

    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name,
    
    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100" 
    )

    try {
    
                     
        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  {
            
                foreach ($ASDBlueprintId in $Id){

                    $URI = "/advanced-designer-service/api/tenants/$($Global:vRAConnection.Tenant)/blueprints/$($ASDBlueprintId)"

                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI

                    [pscustomobject]@{

                        Name = $Response.name
                        Id = $Response.id.id               
                        Description = $Response.description
                        WorkflowId = $Response.workflowId
                        CatalogRequestInfoHidden = $Response.catalogRequestInfoHidden
                        Forms = $Response.forms
                        Status = $Response.status
                        StatusName = $Response.statusName
                        Version = $Response.version
                        OutputParameter = $Response.outputParameter
                    } 
                }                                
            
                break
            }

            "ByName"  {                

               foreach ($ASDBlueprintName in $Name){

                    $URI = "/advanced-designer-service/api/tenants/$($Global:vRAConnection.Tenant)/blueprints?`$filter=name%20eq%20'$($ASDBlueprintName)'"

                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI

                    if ($Response.content){
                    
                        $ASDBlueprints = $Response.content
                    }
                    else {

                        throw "Unable to find Service Blueprint with name $($ASDBlueprintName)"
                    }

                    foreach ($ASDBlueprint in $ASDBlueprints){

                        [pscustomobject]@{

                            Name = $ASDBlueprint.name
                            Id = $ASDBlueprint.id.id               
                            Description = $ASDBlueprint.description
                            WorkflowId = $ASDBlueprint.workflowId
                            CatalogRequestInfoHidden = $ASDBlueprint.catalogRequestInfoHidden
                            Forms = $ASDBlueprint.forms
                            Status = $ASDBlueprint.status
                            StatusName = $ASDBlueprint.statusName
                            Version = $ASDBlueprint.version
                            OutputParameter = $ASDBlueprint.outputParameter
                        }
                    }
                }  
                
                break
            }

            "Standard"  {

                $URI = "/advanced-designer-service/api/tenants/$($Global:vRAConnection.Tenant)/blueprints"

                # --- Run vRA REST Request
                $Response = Invoke-vRARestMethod -Method GET -URI $URI

                $ASDBlueprints = $Response.content

                foreach ($ASDBlueprint in $ASDBlueprints){

                    [pscustomobject]@{

                        Name = $ASDBlueprint.name
                        Id = $ASDBlueprint.id.id               
                        Description = $ASDBlueprint.description
                        WorkflowId = $ASDBlueprint.workflowId
                        CatalogRequestInfoHidden = $ASDBlueprint.catalogRequestInfoHidden
                        Forms = $ASDBlueprint.forms
                        Status = $ASDBlueprint.status
                        StatusName = $ASDBlueprint.statusName
                        Version = $ASDBlueprint.version
                        OutputParameter = $ASDBlueprint.outputParameter
                    } 
                }
                
                break
            }
        }
    }
    catch [Exception]{

        throw
    }
}

<#
    - Function: Export-vRAIcon
#>

function Export-vRAIcon {
<#
    .SYNOPSIS
    Export a vRA Icon
    
    .DESCRIPTION
    Export a vRA Icon
    
    .PARAMETER Id
    Specify the ID of an Icon

    .PARAMETER File
    Specify the file to output the icon to

    .INPUTS
    System.String

    .OUTPUTS
    System.IO.FileInfo

    .EXAMPLE
    Export-vRAIcon -Id "cafe_default_icon_genericAllServices" -File C:\Icons\AllServicesIcon.png

    Export the default All Services Icon to a local file. Note: admin permissions for the default vRA Tenant are required for this action.
#>
[CmdletBinding()][OutputType('System.IO.FileInfo')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$File
    )

    # --- Test for vRA API version
    xRequires -Version 7.1

    try {    

        foreach ($IconId in $Id){

            $URI = "/catalog-service/api/icons/$($IconId)/download"

            # --- Run vRA REST Request
            Invoke-vRARestMethod -Method GET -URI $URI -OutFile $File -Verbose:$VerbosePreference

            # --- Output the result
            Get-ChildItem -Path $File
        }
    }
    catch [Exception]{

        throw
    }
}

<#
    - Function: Get-vRACatalogItem
#>

function Get-vRACatalogItem {
<#
    .SYNOPSIS
    Get a catalog item that the user is allowed to review.
    
    .DESCRIPTION
    API for catalog items that a system administrator can interact with. It allows the user to interact 
    with catalog items that the user is permitted to review, even if they were not published or entitled to them.

    .PARAMETER Id
    The id of the catalog item
    
    .PARAMETER Name
    The name of the catalog item

    .PARAMETER ListAvailable
    Show catalog items that are not assigned to a service

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int
    Switch

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRACatalogItem
    
    .EXAMPLE
    Get-vRACatalogItem -Limit 9999

    .EXAMPLE
    Get-vRACatalogItem -ListAvailable

    .EXAMPLE
    Get-vRACatalogItem -Id dab4e578-57c5-4a30-b3b7-2a5cefa52e9e

    .EXAMPLE
    Get-vRACatalogItem -Name Centos_Template
    
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (
    
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [Switch]$ListAvailable, 

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get catalog item by id
                'ById' {

                    foreach ($CatalogItemId in $Id) {
                
                        $URI = "/catalog-service/api/catalogItems/$($CatalogItemId)"

                        $CatalogItem = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $CatalogItem.id
                            Name = $CatalogItem.name
                            Description = $CatalogItem.description
                            Service = $CatalogItem.serviceRef.label
                            Status = $CatalogItem.status
                            Quota = $CatalogItem.quota
                            Version = $CatalogItem.version
                            DateCreated = $CatalogItem.dateCreated
                            LastUpdatedDate = $CatalogItem.lastUpdatedDate                        
                            Requestable = $CatalogItem.requestable
                            IsNoteworthy = $CatalogItem.isNoteworthy
                            Organization = $CatalogItem.organization
                            CatalogItemType = $CatalogItem.catalogItemTypeRef.label                                            
                            OutputResourceType = $CatalogItem.outputResourceTypeRef.label
                            Callbacks = $CatalogItem.callbacks
                            Forms = $CatalogItem.forms
                            IconId = $CatalogItem.iconId
                            ProviderBinding = $CatalogItem.providerBinding

                        }

                    }

                    break

                }
                # --- Get catalog item by name
                'ByName' {

                    foreach ($CatalogItemName in $Name) { 

                        $URI = "/catalog-service/api/catalogItems?`$filter=name eq '$($CatalogItemName)'"            

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find catalog item with name: $($CatalogItemName)"

                        }

                        $CatalogItem = $Response.content

                        [PSCustomObject] @{

                            Id = $CatalogItem.id
                            Name = $CatalogItem.name
                            Description = $CatalogItem.description
                            Service = $CatalogItem.serviceRef.label
                            Status = $CatalogItem.status
                            Quota = $CatalogItem.quota
                            Version = $CatalogItem.version
                            DateCreated = $CatalogItem.dateCreated
                            LastUpdatedDate = $CatalogItem.lastUpdatedDate                        
                            Requestable = $CatalogItem.requestable
                            IsNoteworthy = $CatalogItem.isNoteworthy
                            Organization = $CatalogItem.organization
                            CatalogItemType = $CatalogItem.catalogItemTypeRef.label                                            
                            OutputResourceType = $CatalogItem.outputResourceTypeRef.label
                            Callbacks = $CatalogItem.callbacks
                            Forms = $CatalogItem.forms
                            IconId = $CatalogItem.iconId
                            ProviderBinding = $CatalogItem.providerBinding

                        }

                    }

                    break

                }
                # --- No parameters passed so return all catalog items
                'Standard' {

                    $URI = "/catalog-service/api/catalogItems?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    if ($PSBoundParameters.ContainsKey("ListAvailable")) {

                        $URI = "/catalog-service/api/catalogItems/available?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    }

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($CatalogItem in $Response.content) {

                        [PSCustomObject] @{

                            Id = $CatalogItem.id
                            Name = $CatalogItem.name
                            Description = $CatalogItem.description
                            Service = $CatalogItem.serviceRef.label
                            Status = $CatalogItem.status
                            Quota = $CatalogItem.quota
                            Version = $CatalogItem.version
                            DateCreated = $CatalogItem.dateCreated
                            LastUpdatedDate = $CatalogItem.lastUpdatedDate                        
                            Requestable = $CatalogItem.requestable
                            IsNoteworthy = $CatalogItem.isNoteworthy
                            Organization = $CatalogItem.organization
                            CatalogItemType = $CatalogItem.catalogItemTypeRef.label                                            
                            OutputResourceType = $CatalogItem.outputResourceTypeRef.label
                            Callbacks = $CatalogItem.callbacks
                            Forms = $CatalogItem.forms
                            IconId = $CatalogItem.iconId
                            ProviderBinding = $CatalogItem.providerBinding

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRACatalogItemRequestTemplate
#>

function Get-vRACatalogItemRequestTemplate {
<#
    .SYNOPSIS
    Get the request template of a catalog item that the user is entitled to see
    
    .DESCRIPTION
    Get the request template of a catalog item that the user is entitled to see and return a JSON payload to reuse in a request
    
    .PARAMETER Id
    The id of the catalog item

    .PARAMETER Name
    The name of the catalog item

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    .EXAMPLE
    Get-vRAConsumerCatalogItemRequestTemplate -Id dab4e578-57c5-4a30-b3b7-2a5cefa52e9e
    
    .EXAMPLE
    Get-vRAConsumerCatalogItemRequestTemplate -Name Centos_Template
    
    .EXAMPLE
    Get-vRAConsumerEntitledCatalogItem | Get-vRACatalogItemRequestTemplate
    
    .EXAMPLE
    Get-vRAConsumerEntitledCatalogItem -Name Centos_Template | Get-vRACatalogItemRequestTemplate   
 
    .EXAMPLE
    Get-vRAConsumerEntitledCatalogItem -Name Centos_Template | Get-vRACatalogItemRequestTemplate | ConvertFrom-Json        
    
#>
[CmdletBinding(DefaultParameterSetName="ById")][OutputType('System.String')]

    Param (
 
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String]$Id,        
            
        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String]$Name
    
    )
    
    Begin {
        
        # --- Test for vRA API version
        xRequires -Version 7.0

    }
 
    Process {

        try {

            # --- If the name parameter is passed derive the id from the result
            if ($PSBoundParameters.ContainsKey("Name")){ 

                $URI = "/catalog-service/api/consumer/entitledCatalogItems?&`$filter=name eq '$($Name)'"               

                $EscapedURI = [uri]::EscapeUriString($URI)

                $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                if ($Response.content.Count -eq 0) {

                    throw "Could not find entitled catalog item with name: $($Name)"

                }
                
                $Id = $Response.content.catalogitem.id
                
                Write-Verbose -Message "Got catalog item id: $($Id)"            

            }

            # --- Build base URI for the request template 
            $URI = "/catalog-service/api/consumer/entitledCatalogItems/$($Id)/requests/template"

            # --- Grab the request template and convert to JSON
            $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference
            
            Write-Verbose -Message "Converting request template to JSON"     
                        
            $Response | ConvertTo-Json -Depth 100

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRACatalogPrincipal
#>

function Get-vRACatalogPrincipal {
<#
    .SYNOPSIS
    Finds catalog principals
    
    .DESCRIPTION
    Internal function to find users or groups and return them as the api type catalogPrincipal.  

    DOCS: catalog-service/api/docs/ns0_catalogPrincipal.html
    
    [pscustomobject] is returned with lowercase property names to commply with expected payload 
    
    .PARAMETER Id
    The Id of the group

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRACatalogPrincipal -Id group@vsphere.local
    
    .EXAMPLE
    Get-vRACatalogPrincipal -Id user@vsphere.local
    
    .EXAMPLE
    Get-vRACatalogPrincipal -Id group@vsphere.local    

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Alias("Principal")]
        [String[]]$Id

    )

    Begin {

    }

    Process {

        try {

            foreach ($PrincipalId in $Id){

                # -- Test for user first
                try {

                    Write-Verbose -Message "Searching for USER $($PrincipalId)"  

                    $User = Get-vRAUserPrincipal -Id $PrincipalId

                    Write-Verbose "User found!"

                    $CatalogPrincipal = [pscustomobject] @{

                        tenantName = $($Global:vRAConnection.Tenant)
                        ref = $($User.Principalid)
                        type = "USER"
                        value = $($User.Name)

                    }

                }
                catch {

                    Write-Verbose -Message "User $($PrincipalId) not found.."

                }

                # --- Test for group if the user was not found
                if (!$CatalogPrincipal) {

                    try {

                        Write-Verbose -Message "Searching for GROUP $($PrincipalId)"  

                        $Group = Get-vRAGroupPrincipal -Id $PrincipalId

                        Write-Verbose -Message "Group found!"  

                        $CatalogPrincipal = [pscustomobject] @{

                            tenantName = $($Global:vRAConnection.Tenant)
                            ref =  $($Group.Principalid)
                            type = "GROUP"
                            value = $($Grop.Name)

                        }

                    }
                    catch {

                        Write-Verbose -Message "Group $($Id) not found.."

                    }

                }

                # --- Test to see if either search returned anything
                if (!$CatalogPrincipal) {

                    throw "$PrincipalId not found"

                    }

                # --- Return the catalogPrincipal
                $CatalogPrincipal

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRAEntitledCatalogItem
#>

function Get-vRAEntitledCatalogItem {
<#
    .SYNOPSIS
    Get a catalog item that the user is entitled to see
    
    .DESCRIPTION
    Get catalog items that are entitled to. Consumer Entitled CatalogItem(s) are basically catalog items:
    - in an active state.
    - the current user has the right to consume.
    - the current user is entitled to consume.
    - associated to a service.
    
    .PARAMETER Id
    The id of the catalog item

    .PARAMETER Name
    The name of the catalog item

    .PARAMETER Service
    Return catalog items in a specific service

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAEntitledCatalogItem
    
    .EXAMPLE
    Get-vRAEntitledCatalogItem -Limit 9999

    .EXAMPLE 
    Get-vRAEntitledCatalogItem -Service "Default Service"

    .EXAMPLE
    Get-vRAEntitledCatalogItem -Id dab4e578-57c5-4a30-b3b7-2a5cefa52e9e    

    .EXAMPLE
    Get-vRAEntitledCatalogItem -Name Centos_Template

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true,ParameterSetName="ByID")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name, 

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Service, 

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100 

    )

    Begin {

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get catalog item by id
                'ById' {

                    foreach ($EntitledCatalogItemId in $Id) {

                        $URI = "/catalog-service/api/consumer/entitledCatalogItems/$($EntitledCatalogItemId)"

                        $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        $CatalogItem = $Response.catalogItem

                        [PSCustomObject] @{

                            Id = $CatalogItem.id
                            Name = $CatalogItem.name
                            Description = $CatalogItem.description
                            Service = $CatalogItem.serviceRef.label
                            Status = $CatalogItem.status
                            Quota = $CatalogItemquota
                            Version = $CatalogItem.version
                            DateCreated = $CatalogItem.dateCreated
                            LastUpdatedDate = $CatalogItem.lastUpdatedDate
                            Requestable = $CatalogItem.requestable
                            IsNoteworthy = $CatalogItem.isNoteworthy
                            Organization = $CatalogItem.organization
                            CatalogItemType = $CatalogItem.catalogitemTypeRef.label
                            OutputResourceType = $CatalogItem.outputResourceTypeRef.label
                            Callbacks = $CatalogItem.callbacks                        
                            Forms = $CatalogItem.forms
                            IconId = $CatalogItem.iconId
                            ProviderBinding = $CatalogItem.providerBinding
                            EntitledOrganizations = $Response.entitledOrganizations 

                        }

                    }

                    break

                }
                # --- Get catalog item by name
                'ByName' {

                    foreach ($EntitledCatalogItemName in $Name) { 

                        $URI = "/catalog-service/api/consumer/entitledCatalogItems?`$filter=name eq '$($EntitledCatalogItemName)'"            

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find catalog item with name: $($EntitledCatalogItemName)"

                        }

                        $CatalogItem = $Response.content.catalogItem

                        [PSCustomObject] @{

                            Id = $CatalogItem.id
                            Name = $CatalogItem.name
                            Description = $CatalogItem.description
                            Service = $CatalogItem.serviceRef.label
                            Status = $CatalogItem.status
                            Quota = $CatalogItemquota
                            Version = $CatalogItem.version
                            DateCreated = $CatalogItem.dateCreated
                            LastUpdatedDate = $CatalogItem.lastUpdatedDate
                            Requestable = $CatalogItem.requestable
                            IsNoteworthy = $CatalogItem.isNoteworthy
                            Organization = $CatalogItem.organization
                            CatalogItemType = $CatalogItem.catalogitemTypeRef.label
                            OutputResourceType = $CatalogItem.outputResourceTypeRef.label
                            Callbacks = $CatalogItem.callbacks                        
                            Forms = $CatalogItem.forms
                            IconId = $CatalogItem.iconId
                            ProviderBinding = $CatalogItem.providerBinding
                            EntitledOrganizations = $Response.content.entitledOrganizations

                        }

                    }

                    break

                }
                # --- No parameters passed so return all catalog items
                'Standard' {

                    $URI = "/catalog-service/api/consumer/entitledCatalogItems?limit=$($Limit)&`page=$($Page)&`$orderby=name asc"

                    if ($PSBoundParameters.ContainsKey("Service")) {

                        $ServiceId = (Get-vRAService -Name $Service).Id

                        $URI = "$($URI)&serviceId=$($ServiceId)"

                    }

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($Item in $Response.content) {

                        $CatalogItem = $Item.catalogItem

                        [PSCustomObject] @{

                            Id = $CatalogItem.id
                            Name = $CatalogItem.name
                            Description = $CatalogItem.description
                            Service = $CatalogItem.serviceRef.label
                            Status = $CatalogItem.status
                            Quota = $CatalogItemquota
                            Version = $CatalogItem.version
                            DateCreated = $CatalogItem.dateCreated
                            LastUpdatedDate = $CatalogItem.lastUpdatedDate
                            Requestable = $CatalogItem.requestable
                            IsNoteworthy = $CatalogItem.isNoteworthy
                            Organization = $CatalogItem.organization
                            CatalogItemType = $CatalogItem.catalogitemTypeRef.label
                            OutputResourceType = $CatalogItem.outputResourceTypeRef.label
                            Callbacks = $CatalogItem.callbacks                        
                            Forms = $CatalogItem.forms
                            IconId = $CatalogItem.iconId
                            ProviderBinding = $CatalogItem.providerBinding
                            EntitledOrganizations = $CatalogItem.entitledOrganizations

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break
                }

            }

        }
        catch [Exception]{

            throw

        }

    }
    
    End {

    }
    
}

<#
    - Function: Get-vRAEntitledService
#>

function Get-vRAEntitledService {
<#
    .SYNOPSIS
    Retrieve vRA services that the user is entitled to see
    
    .DESCRIPTION
    A service represents a customer-facing/user friendly set of activities. In the context of this Service Catalog, 
    these activities are the catalog items and resource actions. 
    A service must be owned by a specific organization and all the activities it contains should belongs to the same organization.
    
    .PARAMETER Id
    The id of the service
    
    .PARAMETER Name
    The Name of the service

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAEntitledService
    
    .EXAMPLE
    Get-vRAEntitledService -Id 332d38d5-c8db-4519-87a7-7ef9f358091a
    
    .EXAMPLE
    Get-vRAEntitledService -Name "Default Service"
    
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$false, ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$false, ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ValueFromPipeline=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get Service by id
                'ById' {

                    foreach ($ServiceId in $Id) { 

                        $URI = "/catalog-service/api/consumer/services/$($ServiceId)"

                        $Service = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            Description = $Service.description
                            Status = $Service.status
                            StatusName = $Service.statusName
                            Version = $Service.version
                            Organization = $Service.organization
                            Hours = $Service.hours
                            Owner = $Service.owner
                            SupportTeam = $Service.supportTeam
                            ChangeWindow = $Service.changeWindow
                            NewDuration = $Service.newDuration
                            LastUpdatedDate = $Service.lastUpdatedDate
                            LastUpdatedBy = $Service.lastUpdatedBy
                            IconId = $Service.iconId

                        }

                    }

                    break
                }
                # --- Get Service by name
                'ByName' {

                    foreach ($ServiceName in $Name) {

                        $URI = "/catalog-service/api/consumer/services?`$filter=name eq '$($ServiceName)'"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find service with name: $($ServiceName)"

                        }

                        $Service = $Response.content

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            Description = $Service.description
                            Status = $Service.status
                            StatusName = $Service.statusName
                            Version = $Service.version
                            Organization = $Service.organization
                            Hours = $Service.hours
                            Owner = $Service.owner
                            SupportTeam = $Service.supportTeam
                            ChangeWindow = $Service.changeWindow
                            NewDuration = $Service.newDuration
                            LastUpdatedDate = $Service.lastUpdatedDate
                            LastUpdatedBy = $Service.lastUpdatedBy
                            IconId = $Service.iconId

                        }

                    }

                    break

                }
                # --- No parameters passed so return all services
                'Standard' {

                    $URI = "/catalog-service/api/consumer/services?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($Service in $Response.content) {

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            Description = $Service.description
                            Status = $Service.status
                            StatusName = $Service.statusName
                            Version = $Service.version
                            Organization = $Service.organization
                            Hours = $Service.hours
                            Owner = $Service.owner
                            SupportTeam = $Service.supportTeam
                            ChangeWindow = $Service.changeWindow
                            NewDuration = $Service.newDuration
                            LastUpdatedDate = $Service.lastUpdatedDate
                            LastUpdatedBy = $Service.lastUpdatedBy
                            IconId = $Service.iconId

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {
        
    }

}

<#
    - Function: Get-vRAEntitlement
#>

function Get-vRAEntitlement {
<#
    .SYNOPSIS
    Retrieve vRA entitlements
    
    .DESCRIPTION
    Retrieve vRA entitlement either by id or name. Passing no parameters will return all entitlements
    
    .PARAMETER Id
    The id of the entitlement
    
    .PARAMETER Name
    The Name of the entitlement

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAEntitlement
    
    .EXAMPLE
    Get-vRAEntitlement -Id 332d38d5-c8db-4519-87a7-7ef9f358091a
    
    .EXAMPLE
    Get-vRAEntitlement -Name "Default Entitlement"
    
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true, ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get Entitlement by id
                'ById'{
            
                    foreach ($EntitlementId in $Id ) { 
                
                        $URI = "/catalog-service/api/entitlements/$($EntitlementId)"

                        $Entitlement = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $Entitlement.id
                            Name = $Entitlement.name
                            Description = $Entitlement.description
                            Status = $Entitlement.status
                            EntitledCatalogItems = $Entitlement.entitledCatalogItems
                            EntitledResourceOperations = $Entitlement.entitledResourceOperations
                            EntitledServices = $Entitlement.entitledServices
                            ExpiryDate = $Entitlement.expiryDate
                            LastUpdatedBy = $Entitlement.lastUpdatedBy
                            LastUpdatedDate = $Entitlement.lastUpdatedDate
                            Organization = $Entitlement.organization
                            Principals = $Entitlement.principals
                            PriorityOrder = $Entitlement.priorityOrder
                            StatusName = $Entitlement.statusName
                            LocalScopeForActions = $Entitlement.localScopeForActions
                            Version = $Entitlement.version

                        }

                    }

                    break

                }

                # --- Get entitlement by name
                'ByName' {

                    foreach ($EntitlementName in $Name) {

                        $URI = "/catalog-service/api/entitlements?`$filter=name eq '$($Name)'"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find entitlement item with name: $($Name)"

                        }

                        $Entitlement = $Response.Content

                        [PSCustomObject] @{

                            Id = $Entitlement.id
                            Name = $Entitlement.name
                            Description = $Entitlement.description
                            Status = $Entitlement.status
                            EntitledCatalogItems = $Entitlement.entitledCatalogItems
                            EntitledResourceOperations = $Entitlement.entitledResourceOperations
                            EntitledServices = $Entitlement.entitledServices
                            ExpiryDate = $Entitlement.expiryDate
                            LastUpdatedBy = $Entitlement.lastUpdatedBy
                            LastUpdatedDate = $Entitlement.lastUpdatedDate
                            Organization = $Entitlement.organization
                            Principals = $Entitlement.principals
                            PriorityOrder = $Entitlement.priorityOrder
                            StatusName = $Entitlement.statusName
                            LocalScopeForActions = $Entitlement.localScopeForActions
                            Version = $Entitlement.version

                        }

                    }

                    break

                }

                # --- No parameters passed so return all entitlements
                'Standard' {

                    $URI = "/catalog-service/api/entitlements?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($Entitlement in $Response.content) {

                        [PSCustomObject] @{

                            Id = $Entitlement.id
                            Name = $Entitlement.name
                            Description = $Entitlement.description
                            Status = $Entitlement.status
                            EntitledCatalogItems = $Entitlement.entitledCatalogItems
                            EntitledResourceOperations = $Entitlement.entitledResourceOperations
                            EntitledServices = $Entitlement.entitledServices
                            ExpiryDate = $Entitlement.expiryDate
                            LastUpdatedBy = $Entitlement.lastUpdatedBy
                            LastUpdatedDate = $Entitlement.lastUpdatedDate
                            Organization = $Entitlement.organization
                            Principals = $Entitlement.principals
                            PriorityOrder = $Entitlement.priorityOrder
                            StatusName = $Entitlement.statusName
                            LocalScopeForActions = $Entitlement.localScopeForActions
                            Version = $Entitlement.version

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {
        
    }

}

<#
    - Function: Get-vRAIcon
#>

function Get-vRAIcon {
<#
    .SYNOPSIS
    Retrieve a vRA Icon
    
    .DESCRIPTION
    Retrieve a vRA Icon
    
    .PARAMETER Id
    Specify the ID of an Icon

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAIcon -Id "cafe_default_icon_genericAllServices"

    Get the default All Services Icon. Note: admin permissions for the default vRA Tenant are required for this action.

    .EXAMPLE
    Get-vRAIcon -Id "cafe_icon_Service01"

    Get the vRA Icon named cafe_icon_Service01
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id
    )

    begin {

        # --- Test for vRA API version
        xRequires -Version 7.1
    }

    process {

        try {    

            foreach ($IconId in $Id){

                $URI = "/catalog-service/api/icons/$($IconId)"

                # --- Run vRA REST Request
                $Icon = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference    
                
                [PSCustomobject]@{

                    Id = $Icon.id                
                    FileName = $Icon.fileName
                    ContentType = $Icon.contentType
                    Image = $Icon.image
                    Organization = $Icon.organization
                }
            }
        }
        catch [Exception]{

            throw
        }
    }
    end {

    }
}

<#
    - Function: Get-vRARequest
#>

function Get-vRARequest {
<#
    .SYNOPSIS
    Get information about vRA requests
    
    .DESCRIPTION
    Get information about vRA requests. These are the same services that you will see via the service tab 
    
    .PARAMETER Id
    The Id of the request to query
    
    .PARAMETER RequestNumber
    The reqest number of the request to query

    .PARAMETER RequestedFor
    Show requests that were submitted on behalf of a certain user

    .PARAMETER RequestedBy
    Show requests that were submitted by a certain user

    .PARAMETER State
    Show request that match a certain state

    Supported states are:

        UNSUBMITTED,
        SUBMITTED,
        DELETED,
        PENDING_PRE_APPROVAL,
        PRE_APPROVAL_SEND_ERROR,
        PRE_APPROVED,
        PRE_REJECTED,
        PROVIDER_DELETION_ERROR,
        IN_PROGRESS,
        PROVIDER_SEND_ERROR,
        PROVIDER_COMPLETED,
        PROVIDER_FAILED,
        PENDING_POST_APPROVAL,
        POST_APPROVAL_SEND_ERROR,
        POST_APPROVED,
        POST_REJECTION_RECEIVED,
        ROLLBACK_ERROR,
        POST_REJECTED,
        SUCCESSFUL,
        PARTIALLY_SUCCESSFUL,
        FAILED

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRARequest

    .EXAMPLE
    Get-vRARequest -Limit 9999

    .EXAMPLE
    Get-vRARequest -RequestedFor user@vsphere.local

    .EXAMPLE
    Get-vRARequest -RequestedBy user@vsphere.local

    .EXAMPLE
    Get-vRARequest -Id 697db588-b706-4836-ae38-35e0c7221e3b
    
    .EXAMPLE
    Get-vRARequest -RequestNumber 3

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject', 'System.Object[]')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByRequestNumber")]
        [ValidateNotNullOrEmpty()]
        [String[]]$RequestNumber,

        [Parameter(Mandatory=$false,ParameterSetName="RequestedFor")]
        [ValidateNotNullOrEmpty()]
        [String]$RequestedFor,

        [Parameter(Mandatory=$false,ParameterSetName="RequestedBy")]
        [ValidateNotNullOrEmpty()]
        [String]$RequestedBy,

        [Parameter(Mandatory=$false,ParameterSetName="State")]
        [ValidateSet(
            "UNSUBMITTED",
            "SUBMITTED",
            "DELETED",
            "PENDING_PRE_APPROVAL",
            "PRE_APPROVAL_SEND_ERROR",
            "PRE_APPROVED",
            "PRE_REJECTED",
            "PROVIDER_DELETION_ERROR",
            "IN_PROGRESS",
            "PROVIDER_SEND_ERROR",
            "PROVIDER_COMPLETED",
            "PROVIDER_FAILED",
            "PENDING_POST_APPROVAL",
            "POST_APPROVAL_SEND_ERROR",
            "POST_APPROVED",
            "POST_REJECTION_RECEIVED",
            "ROLLBACK_ERROR",
            "POST_REJECTED",
            "SUCCESSFUL",
            "PARTIALLY_SUCCESSFUL",
            "FAILED"
        )]
        [String]$State,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [Parameter(Mandatory=$false,ParameterSetName="RequestedFor")]
        [Parameter(Mandatory=$false,ParameterSetName="RequestedBy")] 
        [Parameter(Mandatory=$false,ParameterSetName="State")]       
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,
    
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [Parameter(Mandatory=$false,ParameterSetName="RequestedFor")]
        [Parameter(Mandatory=$false,ParameterSetName="RequestedBy")]
        [Parameter(Mandatory=$false,ParameterSetName="State")]      
        [ValidateNotNullOrEmpty()]
        [int]$Page = 1

    )

    Begin {

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- If the id parameter is passed returned detailed information about the request
                'ById' { 

                    foreach ($RequestId in $Id) {

                        $URI = "/catalog-service/api/consumer/requests/$($RequestId)"

                        $Request = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $Request.id
                            RequestNumber = $Request.RequestNumber
                            State = $Request.state
                            Description = $Request.description
                            CatalogItem = $Request.catalogItemRef.label
                            RequestedItemName = $Request.requestedItemName
                            RequestedItemDescription = $Request.requestedItemDescription                                                
                            Reasons = $Request.reasons
                            RequestedFor = $Request.requestedFor
                            RequestedBy = $Request.requestedBy
                            DateCreated = $Request.dateCreated
                            LastUpdated = $Request.lastUpdated
                            DateSubmitted = $Request.dateSubmitted
                            DateApproved = $Request.dateApproved
                            DateCompleted = $Request.dateCompleted
                            WaitingStatus = $Request.waitingStatus
                            ExecutionStatus = $Request.executionStatus
                            ApprovalStatus = $Request.approvalStatus
                            Phase = $Request.phase
                            IconId = $Request.iconId
                            Version = $Request.version
                            Organization = $Request.organization
                            RequestorEntitlementId = $Request.requestorEntitlementId
                            PreApprovalId = $Request.preApprovalId
                            PostApprovalId = $Request.postApprovalId
                            Quote = $Request.quote
                            RequestCompletion = $Request.requestCompletion
                            RequestData = $Request.requestData
                            RetriesRemaining = $Request.retriesRemaining
                            Components = $Request.components
                            StateName = $Request.stateName
                            CatalogItemProviderBinding = $Request.catalogItemProviderBinding

                        }

                    }

                    break

                }
                # --- If the requestnumber parameter is passed returned detailed information about the request
                'ByRequestNumber' {

                    foreach ($RequestN in $RequestNumber) {

                        $URI = "/catalog-service/api/consumer/requests?`$filter=requestNumber eq '$($RequestN)'"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find request number $($RequestN)"

                        }

                        $Request = $Response.content

                        [PSCustomObject] @{

                            Id = $Request.id
                            RequestNumber = $Request.RequestNumber
                            State = $Request.state
                            Description = $Request.description
                            CatalogItem = $Request.catalogItemRef.label
                            RequestedItemName = $Request.requestedItemName
                            RequestedItemDescription = $Request.requestedItemDescription                                                
                            Reasons = $Request.reasons
                            RequestedFor = $Request.requestedFor
                            RequestedBy = $Request.requestedBy
                            DateCreated = $Request.dateCreated
                            LastUpdated = $Request.lastUpdated
                            DateSubmitted = $Request.dateSubmitted
                            DateApproved = $Request.dateApproved
                            DateCompleted = $Request.dateCompleted
                            WaitingStatus = $Request.waitingStatus
                            ExecutionStatus = $Request.executionStatus
                            ApprovalStatus = $Request.approvalStatus
                            Phase = $Request.phase
                            IconId = $Request.iconId
                            Version = $Request.version
                            Organization = $Request.organization
                            RequestorEntitlementId = $Request.requestorEntitlementId
                            PreApprovalId = $Request.preApprovalId
                            PostApprovalId = $Request.postApprovalId
                            Quote = $Request.quote
                            RequestCompletion = $Request.requestCompletion
                            RequestData = $Request.requestData
                            RetriesRemaining = $Request.retriesRemaining
                            Components = $Request.components
                            StateName = $Request.stateName
                            CatalogItemProviderBinding = $Request.catalogItemProviderBinding

                        }

                    }

                    break

                }
                {('Standard') -or ('RequestedFor') -or ('RequestedBy') -or ('State')} {

                    $URI = "/catalog-service/api/consumer/requests?limit=$($Limit)&page=$($Page)&`$orderby=dateSubmitted desc"

                    if ($PSBoundParameters.ContainsKey("RequestedFor")) {

                        $URI = "$($URI)&`$filter=requestedFor eq '$($RequestedFor)'"

                    }

                    if ($PSBoundParameters.ContainsKey("RequestedBy")) {

                        $URI = "$($URI)&`$filter=requestedBy eq '$($RequestedBy)'"

                    }

                    if ($PSBoundParameters.ContainsKey("State")) {

                        $URI = "$($URI)&`$filter=state eq '$($State)'"

                    }

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    # --- Make the first request to determine the size of the request
                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($Request in $Response.content) {

                        [PSCustomObject] @{

                            Id = $Request.id
                            RequestNumber = $Request.RequestNumber
                            State = $Request.state
                            Description = $Request.description
                            CatalogItem = $Request.catalogItemRef.label
                            RequestedItemName = $Request.requestedItemName
                            RequestedItemDescription = $Request.requestedItemDescription                                                
                            Reasons = $Request.reasons
                            RequestedFor = $Request.requestedFor
                            RequestedBy = $Request.requestedBy
                            DateCreated = $Request.dateCreated
                            LastUpdated = $Request.lastUpdated
                            DateSubmitted = $Request.dateSubmitted
                            DateApproved = $Request.dateApproved
                            DateCompleted = $Request.dateCompleted
                            WaitingStatus = $Request.waitingStatus
                            ExecutionStatus = $Request.executionStatus
                            ApprovalStatus = $Request.approvalStatus
                            Phase = $Request.phase
                            IconId = $Request.iconId
                            Version = $Request.version
                            Organization = $Request.organization
                            RequestorEntitlementId = $Request.requestorEntitlementId
                            PreApprovalId = $Request.preApprovalId
                            PostApprovalId = $Request.postApprovalId
                            Quote = $Request.quote
                            RequestCompletion = $Request.requestCompletion
                            RequestData = $Request.requestData
                            RetriesRemaining = $Request.retriesRemaining
                            Components = $Request.components
                            StateName = $Request.stateName
                            CatalogItemProviderBinding = $Request.catalogItemProviderBinding

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRARequestDetail
#>


function Get-vRARequestDetail {
<#
    .SYNOPSIS
    Get detailed information about vRA request
    
    .DESCRIPTION
    Get detailed information about vRA request. These are result produced by the request (if any)
    
    .PARAMETER Id
    The Id of the request to query
    
    .PARAMETER RequestNumber
    The request number of the request to query

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRARequestDetail -Id 972ab103-950a-4240-8a3d-97174ee07f35
    
    .EXAMPLE
    Get-vRARequestDetail -RequestNumber 965299

    .EXAMPLE
    Get-vRARequestDetail -RequestNumber 965299,965300
    
    .EXAMPLE
    Get-vRARequest -RequestNumber 965299 | Get-vRARequestDetail

#>
[CmdletBinding(DefaultParameterSetName="ById")][OutputType('System.Management.Automation.PSObject', 'System.Object[]')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByRequestNumber")]
        [ValidateNotNullOrEmpty()]
        [String[]]$RequestNumber

    )

    Begin {

        # --- Test for vRA API version
        xRequires -Version 7.0

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- If the id parameter is passed returned detailed information about the request
                'ById' { 

                        foreach ($RequestId in $Id){

                            $RequestNumber = (Get-vRARequest -Id $RequestId).RequestNumber
                            $URI = "/catalog-service/api/consumer/requests/$($RequestId)/forms/details"
                            $RequestDetail = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference
                            
                            [PSCustomObject] @{
                                
                                Id = $RequestId
                                RequestNumber = $RequestNumber
                                Detail = $RequestDetail.values.entries
                            }                                
                        }

                        break

                }
                # --- If the request number parameter is passed returned detailed information about the request
                'ByRequestNumber' {

                        foreach ($Number in $RequestNumber){                             

                            $RequestId = (Get-vRARequest -RequestNumber $Number).id
                            $URI = "/catalog-service/api/consumer/requests/$($RequestId)/forms/details"
                            $RequestDetail = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference
                            
                            [PSCustomObject] @{
                                
                                Id = $RequestId
                                RequestNumber = $Number
                                Detail = $RequestDetail.values.entries
                            }                            
                        }

                        break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}


<#
    - Function: Get-vRAResource
#>

function Get-vRAResource {
<#
    .SYNOPSIS
    Get a deployed resource
    
    .DESCRIPTION
    A deployment represents a collection of deployed artifacts that have been provisioned by a provider.

    .PARAMETER Id
    The id of the resource
    
    .PARAMETER Name
    The Name of the resource

    .PARAMETER Type
    Show resources that match a certain type.

    Supported types ar:

        Deployment,
        Machine

    .PARAMETER WithExtendedData
    Populate the resources extended data by calling their provider

    .PARAMETER WithOperations
    Populate the resources operations attribute by calling the provider. This will force withExtendedData to true.

    .PARAMETER ManagedOnly
    Show resources owned by the users managed business groups, excluding any machines owned by the user in a non-managed
    business group
        
    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display

    .INPUTS
    System.String
    System.Int
    Switch

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAResource

    .EXAMPLE
    Get-vRAResource -WithExtendedData

    .EXAMPLE
    Get-vRAResource -WithOperations
    
    .EXAMPLE
    Get-vRAResource -Id "6195fd70-7243-4dc9-b4f3-4b2300e15ef8"

    .EXAMPLE
    Get-vRAResource -Name "CENTOS-555667"

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateSet("Deployment","Machine")]
        [String]$Type,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Switch]$WithExtendedData,
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Switch]$WithOperations,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Switch]$ManagedOnly, 
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1

    )

    Begin {

        # --- Test for vRA API version
        xRequires -Version 7.0

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get Resource by id
                'ById' {
                
                    foreach ($ResourceId in $Id) { 
                
                        $URI = "/catalog-service/api/consumer/resourceViews?`$filter=id eq '$($ResourceId)'&withExtendedData=true&withOperations=true"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -ne 0) {
                            intNewvRAObjectResource $Response.content
                        }
                        else {
                            Write-Verbose -Message "Could not find resource item with id: $($ResourceId)"
                        }

                    }

                    break

                }        
                # --- Get Resource by name
                'ByName' {

                    foreach ($ResourceName in $Name) {
                
                        $URI = "/catalog-service/api/consumer/resourceViews?`$filter=tolower(name) eq '$($ResourceName.ToLower())'&withExtendedData=true&withOperations=true"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -ne 0) {
                            intNewvRAObjectResource $Response.content
                        }
                        else {
                            Write-Verbose -Message "Could not find resource item with name: $($ResourceName)"
                        }
                        
                    }
                    
                    break
                
                }
                # --- No parameters passed so return all resources
                'Standard' {

                    # vRA REST query is limited to only 100 items per page when extended data is requested. So the script must parse all pages returned
                    $nbPage = 1
                    $TotalPages = 99999 #Total pages is known after the 1st vRA REST query
                    
                    For ($nbPage=1; $nbPage -le $TotalPages; $nbPage++) {
                        # --- Set the default URI with no filtering to return all resource types
                        $URI = "/catalog-service/api/consumer/resourceViews/?withExtendedData=$($WithExtendedData)&withOperations=$($WithOperations)&managedOnly=$($ManagedOnly)&`$orderby=name asc&limit=$($Limit)&page=$($nbPage)"

                        # --- If type is passed set the filter
                        if ($PSBoundParameters.ContainsKey("Type")){

                            switch ($Type) {

                                'Deployment' {

                                    $Filter = "resourceType/id eq 'composition.resource.type.deployment'"
                                    $URI = "$($URI)&`$filter=$($filter)"

                                    break

                                }

                                'Machine' {

                                    $Filter = "resourceType/id eq 'Infrastructure.Machine' or `
                                    resourceType/id eq 'Infrastructure.Virtual' or `
                                    resourceType/id eq 'Infrastructure.Cloud' or `
                                    resourceType/id eq 'Infrastructure.Physical'"

                                    $URI = "$($URI)&`$filter=$($filter)"

                                    break

                                }

                            }

                            Write-Verbose -Message "Type $($Type) selected"

                        }

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        try {
                            $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference
                            
                            foreach ($Resource in $Response.content) {
                               intNewvRAObjectResource $Resource
                            }

                            $TotalPages = $Response.metadata.totalPages
                            Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($nbPage) of $($TotalPages) | Size: $($Response.metadata.size)"
                        }
                        catch {
                            throw "An error occurred when getting vRA Resources! $($_.Exception.Message)"
                        }
                    }
                    
                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

Function intNewvRAObjectResource {
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $Data
    )

    [PSCustomObject]@{
        ResourceId = $Data.ResourceId
        BusinessGroupId = $Data.businessGroupId
        BusinessGroupName = $Data.data.MachineGroupName
        TenantId = $Data.tenantId
        CatalogItemLabel = $Data.data.Component
        ParentResourceId = $Data.parentResourceId
        HasChildren = $Data.hasChildren
        Data = $Data.data
        ResourceType = $Data.resourceType
        Name = $Data.name
        Description = $Data.description
        Status = $Data.status
        RequestId = $Data.requestId      
        Owners = $Data.owners
        DateCreated = $Data.dateCreated
        LastUpdated = $Data.lastUpdated
        Lease = $Data.lease
        Costs = $Data.costs
        CostToDate = $Data.costToDate
        TotalCost = $Data.totalCost
        Links = $Data.links
        IconId = $Data.iconId
    }
}


<#
    - Function: Get-vRAResourceAction
#>

function Get-vRAResourceAction {
<#
    .SYNOPSIS
    Retrieve available Resource Actions for a resource
    
    .DESCRIPTION
    A resourceAction is a specific type of ResourceOperation that is performed by submitting a request. 

    .PARAMETER ResourceId
    The id of the resource

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAResource -Name vm01 | Get-vRAResourceAction 
    
    .EXAMPLE
    Get-vRAResource -Name vm01 | Get-vRAResourceAction | Select Id, Name, BindingId

#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$ResourceId

    )

    Begin {

    }

    Process {

        try {

            foreach ($Id in $ResourceId) {

                # --- Set the uri
                $URI = "/catalog-service/api/consumer/resources/$($Id)/actions"

                # --- Get all available resource actions

                $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                if ($Response.content.Count -lt 1){

                    throw "No resource Actions available for the resource. Check the users entitlements."

                }

                foreach ($Action in $Response.content) {

                    [PSCustomObject] @{

                        Id = $Action.id
                        Name = $Action.name
                        Description = $Action.description
                        Type = $Action.type
                        ExtensionId = $Action.extensionId
                        ProviderTypeId = $Action.providerTypeId
                        BindingId = $Action.bindingId
                        IconId = $Action.iconId
                        HasForm = $Action.hasForm
                        FormScale = $Action.formScale

                    }

                }

            }

        }
        catch [Exception]{

            throw

        }

    }
    
    End {

    }

}

<#
    - Function: Get-vRAResourceActionRequestTemplate
#>

function Get-vRAResourceActionRequestTemplate {
<#
    .SYNOPSIS
    Get the request template of a resource action that the user is entitled to see
    
    .DESCRIPTION
    Get the request template of a resource action that the user is entitled to see

    .PARAMETER ActionId
    The id resource action
    
    .PARAMETER ResourceId
    The id of the resource

    .PARAMETER ResourceName
    The name of the resource

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    .EXAMPLE
    Get-vRAResourceActionRequestTemplate -ActionId "fae08c75-3506-40f6-9c9b-35966fe9125c" -ResourceName vm01
    
    .EXAMPLE
    Get-vRAResourceActionRequestTemplate -ActionId "fae08c75-3506-40f6-9c9b-35966fe9125c" -ResourceId 20402e93-fb1d-4bd9-8a51-b809fbb946fd

#>
[CmdletBinding(DefaultParameterSetName="ByResourceId")][OutputType('System.String')]

    Param (

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$ActionId,
    
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ByResourceId")]
        [ValidateNotNullOrEmpty()]
        [String[]]$ResourceId,

        [Parameter(Mandatory=$true,ParameterSetName="ByResourceName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$ResourceName
           
    )
    
    Begin {

        xRequires -Version 7.0

        function intRequestResourceActionTemplate($ResourceId, $ActionId) {
        <#

            Private function to invoke the resource action request template
            request

        #>
            $URI = "/catalog-service/api/consumer/resources/$($ResourceId)/actions/$($ActionId)/requests/template"
            $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference
            $Response | ConvertTo-Json -Depth 100
        }        
    }
 
    Process {

        try {


            switch ($PSCmdlet.ParameterSetName) {

                'ByResourceId' {

                    foreach ($Id in $ResourceId) {

                        intRequestResourceActionTemplate -ResourceId $Id -ActionId $ActionId

                    }

                    break

                }

                'ByResourceName' {

                    foreach ($Name in $ResourceName) {

                        # --- Get the resource id
                        Write-verbose -Message "Retrieving Id for resource $($Name)"
                        $Resource = Get-vRAResource -Name $ResourceName
                        $ResourceId = $Resource.ResourceId

                        intRequestResourceActionTemplate -ResourceId $ResourceId -ActionId $ActionId

                    }

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {
        
    }

}

<#
    - Function: Get-vRAResourceOperation
#>

function Get-vRAResourceOperation {
<#
    .SYNOPSIS
    Get a resource operation

    .DESCRIPTION
    A resource operation represents a Day-2 operation that can be performed on a resource. 
    Resource operations are registered in the Service Catalog and target a specific resource type. 
    These operations can be invoked / accessed by consumers through the self-service interface on the resources they own.
    
    .PARAMETER Id
    The id of the resource operation

    .PARAMETER ExternalId
    The external id of the resource operation

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAResourceOperation
    
    .EXAMPLE
    Get-vRAResourceOperation -Id "a4d57b16-9706-471b-9960-d0855fe544bb"

    .EXAMPLE
    Get-vRAResourceOperation -Name "Power On"

    .EXAMPLE
    Get-vRAResourceOperation -ExternalId "Infrastructure.Machine.Action.PowerOn"
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByExternalId")]
        [ValidateNotNullOrEmpty()]
        [String[]]$ExternalId,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {

    } 

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get resource operation by id
                'ById'{

                    foreach ($ResourceOperation in $Id ) { 

                        $URI = "/catalog-service/api/resourceOperations/$($ResourceOperation)"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $ResourceOperation = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $ResourceOperation.id
                            Name = $ResourceOperation.name
                            ExternalId = $ResourceOperation.externalId
                            Description = $ResourceOperation.description
                            IconId = $ResourceOperation.iconId
                            TargetCriteria = $ResourceOperation.targetCriteria
                            TargetResourceTypeRef = $ResourceOperation.targetResourceTypeRef
                            Status = $ResourceOperation.status
                            Entitleable = $ResourceOperation.entitleable
                            organization = $ResourceOperation.organization
                            RequestSchema =$ResourceOperation.requestSchema
                            Forms = $ResourceOperation.forms
                            Callbacks = $ResourceOperation.callbacks
                            LifecycleAction = $ResourceOperation.lifecycleACtion
                            BindingId = $ResourceOperation.bindingId
                            ProviderTypeRef =$ResourceOperation.providerTypeRef

                        }

                    }

                    break

                }

                # --- Get resource operation by external id
                'ByExternalId' {

                    foreach ($ResourceOperation in $ExternalId) {           

                        $URI = "/catalog-service/api/resourceOperations?`$filter=externalId eq '$($ResourceOperation)'"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find resource operation item with name: $Name"

                        }

                        $ResourceOperation = $Response.content

                        [PSCustomObject] @{

                            Id = $ResourceOperation.id
                            Name = $ResourceOperation.name
                            ExternalId = $ResourceOperation.externalId
                            Description = $ResourceOperation.description
                            IconId = $ResourceOperation.iconId
                            TargetCriteria = $ResourceOperation.targetCriteria
                            TargetResourceTypeRef = $ResourceOperation.targetResourceTypeRef
                            Status = $ResourceOperation.status
                            Entitleable = $ResourceOperation.entitleable
                            organization = $ResourceOperation.organization
                            RequestSchema =$ResourceOperation.requestSchema
                            Forms = $ResourceOperation.forms
                            Callbacks = $ResourceOperation.callbacks
                            LifecycleAction = $ResourceOperation.lifecycleACtion
                            BindingId = $ResourceOperation.bindingId
                            ProviderTypeRef =$ResourceOperation.providerTypeRef

                        }

                    }

                    break

                }
                    
                # --- No parameters passed so return all resource operations
                'Standard' {
                
                    $URI = "/catalog-service/api/resourceOperations?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($ResourceOperation in $Response.content) {

                        [PSCustomObject] @{

                            Id = $ResourceOperation.id
                            Name = $ResourceOperation.name
                            ExternalId = $ResourceOperation.externalId
                            Description = $ResourceOperation.description
                            IconId = $ResourceOperation.iconId
                            TargetCriteria = $ResourceOperation.targetCriteria
                            TargetResourceTypeRef = $ResourceOperation.targetResourceTypeRef
                            Status = $ResourceOperation.status
                            Entitleable = $ResourceOperation.entitleable
                            organization = $ResourceOperation.organization
                            RequestSchema =$ResourceOperation.requestSchema
                            Forms = $ResourceOperation.forms
                            Callbacks = $ResourceOperation.callbacks
                            LifecycleAction = $ResourceOperation.lifecycleACtion
                            BindingId = $ResourceOperation.bindingId
                            ProviderTypeRef =$ResourceOperation.providerTypeRef

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRAResourceType
#>

function Get-vRAResourceType {
<#
    .SYNOPSIS
    Get a resource type
    
    .DESCRIPTION
    A Resource type is a type assigned to resources. The types are defined by the provider types. 
    It allows similar resources to be grouped together.
    
    .PARAMETER Id
    The id of the resource type
    
    .PARAMETER Name
    The Name of the resource type

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAResourceType
    
    .EXAMPLE
    Get-vRAResourceType -Id "Infrastructure.Machine"
    
    .EXAMPLE
    Get-vRAResourceType -Name "Machine"
    
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,         

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {

        # --- Test for vRA API version
        xRequires -Version 7.0

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get Resource Type by id
                'ById' {
                
                    foreach ($ResourceTypeId in $Id) { 

                        $URI = "/catalog-service/api/resourceTypes?`$filter=id eq '$($ResourceTypeId)'"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0){

                            throw "Could not find Resource Type with Id: $($ResourceTypeId)"

                        }

                        $ResourceType = $Response.content

                        [PSCustomObject] @{

                            Id = $ResourceType.id
                            Callbacks = $ResourceType.callbacks
                            CostFeatures =  $ResourceType.costFeatures
                            Description = $ResourceType.description
                            Forms = $ResourceType.forms
                            ListView = $ResourceType.listView
                            Name = $ResourceType.name
                            PluralizedName = $ResourceType.pluralizedName
                            Primary = $ResourceType.primary
                            ProviderTypeId = $ResourceType.providerTYpeId
                            Schema = $ResourceType.schema
                            ListDescendantTypesSeparately = $ResourceType.listDescendantTypesSeparately
                            ShowChildrenOutsideParent = $ResourceType.ShowChildrenOutsideParent
                            Status = $ResourceType.status

                        }

                    }

                    break

                }
                # --- Get Resource Type by name
                'ByName' {

                    foreach ($ResourceTypeName in $Name) {

                        $URI = "/catalog-service/api/resourceTypes?`$filter=name eq '$($ResourceTypeName)'"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find resource type item with name: $($ResourceTypeName)"

                        }

                        $ResourceType = $Response.content

                        [PSCustomObject] @{

                            Id = $ResourceType.id
                            Callbacks = $ResourceType.callbacks
                            CostFeatures =  $ResourceType.costFeatures
                            Description = $ResourceType.description
                            Forms = $ResourceType.forms
                            ListView = $ResourceType.listView
                            Name = $ResourceType.name
                            PluralizedName = $ResourceType.pluralizedName
                            Primary = $ResourceType.primary
                            ProviderTypeId = $ResourceType.providerTYpeId
                            Schema = $ResourceType.schema
                            ListDescendantTypesSeparately = $ResourceType.listDescendantTypesSeparately
                            ShowChildrenOutsideParent = $ResourceType.ShowChildrenOutsideParent
                            Status = $ResourceType.status

                        }

                    }

                    break

                }
                # --- No parameters passed so return all resource types
                'Standard' {
                
                    $URI = "/catalog-service/api/resourceTypes?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($ResourceType in $Response.content) {

                        [PSCustomObject] @{

                            Id = $ResourceType.id
                            Callbacks = $ResourceType.callbacks
                            CostFeatures =  $ResourceType.costFeatures
                            Description = $ResourceType.description
                            Forms = $ResourceType.forms
                            ListView = $ResourceType.listView
                            Name = $ResourceType.name
                            PluralizedName = $ResourceType.pluralizedName
                            Primary = $ResourceType.primary
                            ProviderTypeId = $ResourceType.providerTYpeId
                            Schema = $ResourceType.schema
                            ListDescendantTypesSeparately = $ResourceType.listDescendantTypesSeparately
                            ShowChildrenOutsideParent = $ResourceType.ShowChildrenOutsideParent
                            Status = $ResourceType.status

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRAService
#>

function Get-vRAService {
<#
    .SYNOPSIS
    Retrieve vRA services that the user is has access to

    .DESCRIPTION
    A service represents a customer-facing/user friendly set of activities. In the context of this Service Catalog, 
    these activities are the catalog items and resource actions. 
    A service must be owned by a specific organization and all the activities it contains should belongs to the same organization.
    
    .PARAMETER Id
    The id of the service
    
    .PARAMETER Name
    The Name of the service

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAService
    
    .EXAMPLE
    Get-vRAService -Id 332d38d5-c8db-4519-87a7-7ef9f358091a
    
    .EXAMPLE
    Get-vRAService -Name "Default Service"
    
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true, ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get Service by id
                'ById' {

                    foreach ($ServiceId in $Id) { 

                        $URI = "/catalog-service/api/services/$($ServiceId)"

                        $Service = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            Description = $Service.description
                            Status = $Service.status
                            StatusName = $Service.statusName
                            Version = $Service.version
                            Organization = $Service.organization
                            Hours = $Service.hours
                            Owner = $Service.owner
                            SupportTeam = $Service.supportTeam
                            ChangeWindow = $Service.changeWindow
                            NewDuration = $Service.newDuration
                            LastUpdatedDate = $Service.lastUpdatedDate
                            LastUpdatedBy = $Service.lastUpdatedBy
                            IconId = $Service.iconId

                        }

                    }

                    break

                }
                # --- Get Service by name
                'ByName' {

                    foreach ($ServiceName in $Name) {

                        $URI = "/catalog-service/api/services?`$filter=name eq '$($ServiceName)'"

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find service with name: $($ServiceName)"

                        }

                        $Service = $Response.Content

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            Description = $Service.description
                            Status = $Service.status
                            StatusName = $Service.statusName
                            Version = $Service.version
                            Organization = $Service.organization
                            Hours = $Service.hours
                            Owner = $Service.owner
                            SupportTeam = $Service.supportTeam
                            ChangeWindow = $Service.changeWindow
                            NewDuration = $Service.newDuration
                            LastUpdatedDate = $Service.lastUpdatedDate
                            LastUpdatedBy = $Service.lastUpdatedBy
                            IconId = $Service.iconId

                        }

                    }

                    break

                }
                # --- No parameters passed so return all services
                'Standard' {

                    $URI = "/catalog-service/api/services?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($Service in $Response.content) {

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            Description = $Service.description
                            Status = $Service.status
                            StatusName = $Service.statusName
                            Version = $Service.version
                            Organization = $Service.organization
                            Hours = $Service.hours
                            Owner = $Service.owner
                            SupportTeam = $Service.supportTeam
                            ChangeWindow = $Service.changeWindow
                            NewDuration = $Service.newDuration
                            LastUpdatedDate = $Service.lastUpdatedDate
                            LastUpdatedBy = $Service.lastUpdatedBy
                            IconId = $Service.iconId

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw
        }

    }

    End {

    }

}

<#
    - Function: Import-vRAIcon
#>

function Import-vRAIcon {
<#
    .SYNOPSIS
    Imports a vRA Icon   

    .DESCRIPTION
    Imports a vRA Icon

    .PARAMETER Id
    Specify the ID of an Icon

    .PARAMETER File
    The Icon file

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Import-vRAIcon -Id "cafe_default_icon_genericAllServices" -File C:\Icons\NewIcon.png

    Update the default All Services Icon with a new image file. Note: admin permissions for the default vRA Tenant are required for this action.

    .EXAMPLE
    Get-ChildItem -Path C:\Icons\NewIcon.png | Import-vRAIcon -Id "cafe_default_icon_genericAllServices" -Confirm:$false

    Update the default All Services Icon with a new image file via the pipeline. Note: admin permissions for the default vRA Tenant are required for this action.

    .EXAMPLE
    Import-vRAIcon -Id "cafe_icon_Service01" -File C:\Icons\Service01Icon.png -Confirm:$false

    Create a new Icon named cafe_icon_Service01

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$File
    )

    begin {

        # --- Test for vRA API version
        xRequires -Version 7.1
    }

    process {

        foreach ($FilePath in $File){

            try {


                # --- Resolve the file path
                $FileInfo = [System.IO.FileInfo](Resolve-Path $FilePath).Path

                # --- Create the base64 string
                $Base64 = [convert]::ToBase64String((Get-Content $FileInfo.FullName -Encoding byte))

                # --- Set content type
                $Extension = $FileInfo.Extension.TrimStart('.')                
                $ContentType = "image/$($Extension)"              

                # --- Prepare payload        
                $Body = @"
                    {
                        "id": "$($Id)",
                        "fileName": "$($FileInfo.Name)",
                        "contentType": "$($ContentType)",
                        "image": "$($Base64)",
                        "organization": {}
                    }
"@

                $URI = "/catalog-service/api/icons"

                if ($PSCmdlet.ShouldProcess($FileInfo.FullName)){

                    # --- Run vRA REST request
                    Invoke-vRARestMethod -Method POST -Uri $URI -Body $Body -Verbose:$VerbosePreference

                    # --- Output the result
                    Get-vRAIcon -Id $Id
                }
            }
            catch [Exception]{

                throw
            }
        }
    }
    end {

    }
}

<#
    - Function: New-vRAEntitlement
#>

function New-vRAEntitlement {
<#
    .SYNOPSIS
    Create a new entitlement

    .DESCRIPTION
    Create a new entitlement

    .PARAMETER Name
    The name of the entitlement

    .PARAMETER Description
    A description of the entitlement

    .PARAMETER BusinessGroup
    The business group that will be associated with the entitlement

    .PARAMETER Principals
    Users or groups that will be associated with the entitlement

    If this parameter is not specified, the entitlement will be created as DRAFT

    .PARAMETER EntitledCatalogItems
    One or more entitled catalog item 

    .PARAMETER EntitledResourceOperations
    The externalId of one or more entitled resource operation (e.g. Infrastructure.Machine.Action.PowerOn)

    .PARAMETER EntitledServices
    One or more entitled service

    .PARAMETER LocalScopeForActions
    Determines if the entitled actions are entitled for all applicable service catalog items or only
    items in this entitlement

    The default value for this parameter is True.

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRAEntitlement -Name "TestEntitlement" -Description "a test" -BusinessGroup "Test01" -Principals "user@vsphere.local" -EntitledCatalogItems "centos7","centos6" -EntitledServices "Default service" -Verbose

    .EXAMPLE
    $JSON = @"
                    {
                      "description": "",
                      "entitledCatalogItems": [],
                      "entitledResourceOperations": [],
                      "entitledServices": [],
                      "expiryDate": null,
                      "id": null,
                      "lastUpdatedBy": null,
                      "lastUpdatedDate": null,
                      "name": "Test api 4",
                      "organization": {
                        "tenantRef": "Tenant01",
                        "tenantLabel": "Tenant",
                        "subtenantRef": "792e859a-8a5e-4814-bf04-e4489b27cada",
                        "subtenantLabel": "Default Business Group[Tenant01]"
                      },
                      "principals": [
                        {
                          "tenantName": "Tenant01",
                          "ref": "user@vsphere.local",
                          "type": "USER",
                          "value": "Test User"
                        }
                      ],
                      "priorityOrder": 2,
                      "status": "ACTIVE",
                      "statusName": "Active",
                      "localScopeForActions": true,
                      "version": null
                    }
"@

    $JSON | New-vRAEntitlement -Verbose

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$true,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$BusinessGroup,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Principals,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String[]]$EntitledCatalogItems,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String[]]$EntitledResourceOperations,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String[]]$EntitledServices,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [bool]$LocalScopeForActions = $true,        

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
        [ValidateNotNullOrEmpty()]
        [String]$JSON

    )    

    Begin {

    }
    
    Process {

        try {
    
            # --- Set Body for REST request depending on ParameterSet
            if ($PSBoundParameters.ContainsKey("JSON")){

                $Data = ($JSON | ConvertFrom-Json)
        
                $Body = $JSON
                $Name = $Data.name
            }
            else {

                # --- Get business group information for the request
                Write-Verbose -Message "Requesting business group information for $($BusinessGroup)"

                $BusinessGroupObject = Get-vRABusinessGroup -Name $BusinessGroup

                # --- Prepare payload        
                $Body = @"
                    {
                      "description": "$($Description)",
                      "entitledCatalogItems": [],
                      "entitledResourceOperations": [],
                      "entitledServices": [],
                      "expiryDate": null,
                      "id": null,
                      "lastUpdatedBy": null,
                      "lastUpdatedDate": null,
                      "name": "$($Name)",
                      "organization": {
                        "tenantRef": "$($Global:vRAConnection.Tenant)",
                        "tenantLabel": null,
                        "subtenantRef": "$($BusinessGroupObject.ID)",
                        "subtenantLabel": "$($BusinessGroupObject.Name)"
                      },
                      "principals": [],
                      "priorityOrder": null,
                      "status": "DRAFT",
                      "statusName": "Draft",
                      "localScopeForActions": "$($LocalScopeForActions.ToString().ToLower())",
                      "version": null
                    }
"@

            }

            # --- If certain parameters are specified, ConvertFrom-Json, update, then ConvertTo-Json
            if ($PSBoundParameters.ContainsKey("Principals") -or $PSBoundParameters.ContainsKey("EntitledCatalogItems")  -or $PSBoundParameters.ContainsKey("EntitledResourceOperations")  -or $PSBoundParameters.ContainsKey("EntitledServices")){

                $Object = $Body | ConvertFrom-Json
              
                if ($PSBoundParameters.ContainsKey("Principals")) {

                    Write-Verbose -Message "Principal specified, changing status to ACTIVE"
                    $Object.status = "ACTIVE"

                    foreach($Principal in $Principals) {

                        Write-Verbose -Message "Adding principal: $($Principal)"

                        $CatalogPrincipal = Get-vRACatalogPrincipal -Id $Principal

                        $Object.principals += $CatalogPrincipal

                    }

                }

                if ($PSBoundParameters.ContainsKey("EntitledCatalogItems")) {

                    foreach($CatalogItem in $EntitledCatalogItems) {

                        Write-Verbose "Adding entitled catalog item: $($CatalogItem)"

                        # --- Build catalog item ref object
                        $CatalogItemRef = [PSCustomObject] @{

                            id = $((Get-vRACatalogItem -Name $CatalogItem).Id)
                            label = $null

                        }
                        
                        # --- Build entitled catalog item object and insert catalogItemRef
                        $EntitledCatalogItem = [PSCustomObject] @{

                            approvalPolicyId = $null
                            active = $null
                            catalogItemRef = $CatalogItemRef

                        }

                        $Object.entitledCatalogItems += $EntitledCatalogItem

                    }

                }

                if ($PSBoundParameters.ContainsKey("EntitledServices")) {

                    foreach($Service in $EntitledServices) {

                        Write-Verbose -Message "Adding service: $($Service)"

                        # --- Build service ref object
                        $ServiceRef = [PSCustomObject] @{

                            id = $((Get-vRAService -Name $Service).Id)
                            label = $null

                        }
                        
                        # --- Build entitled service object and insert serviceRef
                        $EntitledService = [PSCustomObject] @{

                            approvalPolicyId = $null
                            active = $null
                            serviceRef = $ServiceRef

                        }

                        $Object.entitledServices += $EntitledService

                    }

                }

                if ($PSBoundParameters.ContainsKey("EntitledResourceOperations")) {

                    foreach ($ResourceOperation in $EntitledResourceOperations) {

                        Write-Verbose -Message "Adding resouceoperation: $($resourceOperation)"

                        $Operation = Get-vRAResourceOperation -ExternalId $ResourceOperation

                        $ResourceOperationRef = [PSCustomObject] @{

                            id = $Operation.Id
                            label = $null

                        }

                        $EntitledResourceOperation = [PSCustomObject] @{

                            approvalPolicyId =  $null
                            resourceOperationType = "ACTION"
                            externalId = $Operation.ExternalId
                            active = $true
                            resourceOperationRef = $ResourceOperationRef
                            targetResourceTypeRef = $Operation.TargetResourceTypeRef

                        }

                        $Object.entitledResourceOperations += $EntitledResourceOperation

                    }

                }

                $Body = $Object | ConvertTo-Json -Depth 50 -Compress

                Write-Verbose $Body

            }

            if ($PSCmdlet.ShouldProcess($Name)){

                $URI = "/catalog-service/api/entitlements/"

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRAEntitlement -Name $Name
            }

        }
        catch [Exception]{

            throw
        }

    }
    
    End {

    }

}

<#
    - Function: New-vRAService
#>

function New-vRAService {
<#
    .SYNOPSIS
    Create a vRA Service for the current tenant
    
    .DESCRIPTION
    Create a vRA Service for the current tenant

    Currently unsupported interactive actions:

    * HoursStartTime
    * HoursEndTime
    * ChangeWindowDayOfWeek
    * ChangeWindowStartTime
    * ChangeWindowEndTime

    .PARAMETER Name
    The name of the service

    .PARAMETER Description
    A description of the service

    .PARAMETER Owner
    The owner of the service

    .PARAMETER SupportTeam
    The support team of the service

    .PARAMETER IconId
    The Icon Id of the service. This must already exist in the Service Catalog. Typically it would have already been created via Import-vRAServiceIcon

    .PARAMETER JSON
    A json string of type service (catalog-service/api/docs/el_ns0_service.html)
    
    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRAService -Name "New Service"
    
    .EXAMPLE
    New-vRAService -Name "New Service" -Description "A new service" -Owner user@vsphere.local -SupportTeam customgroup@vsphere.local -IconId "cafe_icon_Service01"
    
    .EXAMPLE
    $JSON = @"

        {
          "name": "New Service",
          "description": "A new Service",
          "status": "ACTIVE",
          "statusName": "Active",
          "version": 1,
          "organization": {
            "tenantRef": "Tenant01",
            "tenantLabel": "Tenant01",
            "subtenantRef": null,
            "subtenantLabel": null
          },
          "newDuration": null,
          "iconId": "cafe_default_icon_genericService"
        }
"@

    $JSON | New-vRAService
       
    
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (
        
        [Parameter(Mandatory=$true,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Description,            

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Owner,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$SupportTeam,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$IconId,
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
        [ValidateNotNullOrEmpty()]
        [String]$JSON      
     
    )    

    Begin {
    
    }
    
    Process {

            if ($PSBoundParameters.ContainsKey("JSON")) {

                $Data = ($JSON | ConvertFrom-Json)
        
                $Body = $JSON
                $Name = $Data.name
            }
            else {

                $Body = @"
                    {
                        "name": "$($Name)",
                        "description": "$($Description)",
                        "status": "ACTIVE",
                        "statusName": "Active",
                        "version": 1,
                        "organization": {
                            "tenantRef": "$($Global:vRAConnection.Tenant)",
                            "tenantLabel": null,
                            "subtenantRef": null,
                            "subtenantLabel": null
                        },   
                        "newDuration": null,
                        "iconId": "cafe_default_icon_genericService"
                    }
"@

                # --- If certain parameters are specified, ConvertFrom-Json, update, then ConvertTo-Json
                if ($PSBoundParameters.ContainsKey("Owner") -or $PSBoundParameters.ContainsKey("SupportTeam") -or $PSBoundParameters.ContainsKey("IconId")){

                    $Object = $Body | ConvertFrom-Json

                    # --- Add owner catalogPrincipal
                    if ($PSBoundParameters.ContainsKey("Owner")) {

                        Write-Verbose -Message "Adding owner principal: $($Owner)"

                        $CatalogPrincipal = Get-vRACatalogPrincipal -Id $Owner   

                        $Object | Add-Member -MemberType NoteProperty -Name "owner" -Value $CatalogPrincipal                                         

                    }

                    # --- Add supportTeam catalogPrincipal
                    if ($PSBoundParameters.ContainsKey("SupportTeam")) {

                        Write-Verbose -Message "Adding support team principal: $($SupportTeam)"

                        $CatalogPrincipal = Get-vRACatalogPrincipal -Id $SupportTeam   

                        $Object | Add-Member -MemberType NoteProperty -Name "supportTeam" -Value $CatalogPrincipal

                    }

                    if ($PSBoundParameters.ContainsKey("IconId")) {

                        Write-Verbose -Message "Setting IconId: $($IconId)"

                        $Object.iconId = $IconId

                    }

                    $Body = $Object | ConvertTo-Json -Compress

                }
                        
            }
       
        # --- Create new service
        try {
            if ($PSCmdlet.ShouldProcess($Name)){
                
                # --- Build the URI string for the service         
            
                $URI = "/catalog-service/api/services"
                           
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null
                Get-vRAService -Name "$($Name)"

            }

        }
        catch [Exception] {
            
            throw
            
        }
    
    }

    End {

    }

}

<#
    - Function: Remove-vRAIcon
#>

function Remove-vRAIcon {
<#
    .SYNOPSIS
    Remove a vRA Icon
    
    .DESCRIPTION
    Remove a vRA Icon from the service catalog. If the icon is one of the default system icons, it will be reverted to its default state instead of being deleted.

    .PARAMETER Id
    The id of the Icon

    .INPUTS
    System.String

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRAIcon -Id "cafe_default_icon_genericAllServices"

    Set the default All Services Icon back to the original icon. Note: admin permissions for the default vRA Tenant are required for this action.

    .EXAMPLE
    Get-vRAIcon -Id "cafe_icon_Service01" | Remove-vRAIcon -Confirm:$false

    Delete the Icon named cafe_icon_Service01
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id
          
    )    

    begin {

        # --- Test for vRA API version
        xRequires -Version 7.1
    }
    
    process {

        foreach ($IconId in $Id) {

            # --- Remove the service
            try {

                if ($PSCmdlet.ShouldProcess($IconId)){                
       
                    $URI = "/catalog-service/api/icons/$($IconId)"
                
                    Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference              
                }
            }
            catch [Exception] {
            
                throw            
            }
        }
    }

    end {

    }
}

<#
    - Function: Remove-vRAService
#>

function Remove-vRAService {
<#
    .SYNOPSIS
    Remove a vRA Service
    
    .DESCRIPTION
    Remove a vRA Service

    .PARAMETER Id
    The id of the service

    .INPUTS
    System.String

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRAService -Id "d00d3631-997c-40f7-90e8-7ccbc153c20c"       

    .EXAMPLE
    Get-vRAService -Id "d00d3631-997c-40f7-90e8-7ccbc153c20c" | Remove-vRAService

    .EXAMPLE
    Get-vRAService | Where-Object {$_.name -ne "Default Service"} | Remove-vRAService
    
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id
          
    )    

    Begin {
    
    }
    
    Process {

        foreach ($ServiceId in $Id) {

            $URI = "/catalog-service/api/services/$($ServiceId)"
            
            $Service = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

            Write-Verbose -Message "Removing service $($Service.name)"

            $Service.status = "DELETED"

            # --- Remove the service
            try {

                if ($PSCmdlet.ShouldProcess($Service.name)){
                
                    # --- Build the URI string for the service         
            
                    $URI = "/catalog-service/api/services/$($ServiceId)"
                
                    Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Service | ConvertTo-Json -Compress) -Verbose:$VerbosePreference | Out-Null
                
                }

            }
            catch [Exception] {
            
                throw
            
            }

        }

    }

    End {

    }

}

<#
    - Function: Request-vRACatalogItem
#>

function Request-vRACatalogItem {
<#
    .SYNOPSIS
    Request a vRA catalog item
    
    .DESCRIPTION
    Request a vRA catalog item with a given request template payload. 
    
    If the wait switch is passed the cmdlet will wait until the request has completed. If successful informaiton
    about the new resource will be returned
    
    If no switch is passed then the request id will be returned
    
    .PARAMETER Id
    The Id of the catalog item to request

    .PARAMETER RequestedFor
    The user principal that the request is for (e.g. user@vsphere.local). If not specified the current user is used

    .PARAMETER Description
    A description for the request

    .PARAMETER Reasons
    Reasons for the request

    .PARAMETER JSON
    JSON string containing the request template

    .PARAMETER Wait
    Wait for the request to complete
    
    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    $Template = Get-vRAEntitledCatalogItem -Id "dab4e578-57c5-4a30-b3b7-2a5cefa52e9e" | Get-vRACatalogItemRequestTemplate

    $Resource = Request-vRACatalogItem -JSON $Template -Wait -Verbose
    
    .EXAMPLE
    $Template = Get-vRAEntitledCatalogItem -Id "dab4e578-57c5-4a30-b3b7-2a5cefa52e9e" | Get-vRACatalogItemRequestTemplate

    $RequestId = Request-vRACatalogItem -JSON $Template -Verbose

    .EXAMPLE
    Request-vRACatalogItem -Id "dab4e578-57c5-4a30-b3b7-2a5cefa52e9e"

    .EXAMPLE
    Request-vRACatalogItem -Id "dab4e578-57c5-4a30-b3b7-2a5cefa52e9e" -Wait

    .EXAMPLE
    Request-vRACatalogItem -Id "dab4e578-57c5-4a30-b3b7-2a5cefa52e9e" -Description "Test" -Reasons "Test Reason"
      
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Id,
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$RequestedFor,      

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Description,
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Reasons,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
        [ValidateNotNullOrEmpty()]
        [String]$JSON,  
        
        [Parameter(Mandatory=$false)] 
        [Switch]$Wait
    
    )    

    Begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    Process {
    
        try {

            if ($PSBoundParameters.ContainsKey("JSON")) {

                # --- Get the Id of the catalog Item being requested then POST            
                $Id = ($JSON | ConvertFrom-Json).catalogItemId      
                Write-Verbose -Message "Got cataligItemId from payload: $($Id)"

                }
            else {

                # --- Get request Template
                $JSON = Get-vRACatalogItemRequestTemplate -Id $Id

                if ($PSBoundParameters.ContainsKey("RequestedFor")-or 
                    $PSBoundParameters.ContainsKey("Description") -or 
                    $PSBoundParameters.ContainsKey("Reasons")){

                    $Object = $JSON | ConvertFrom-Json

                    if ($PSBoundParameters.ContainsKey("RequestedFor")) {

                        Write-Verbose -Message "Setting requestedFor: $($RequestedFor)"

                        $Object.requestedFor = $RequestedFor

                        }

                    if ($PSBoundParameters.ContainsKey("Description")) {

                        Write-Verbose -Message "Setting description: $($Description)"

                        $Object.description = $description

                        }

                    if ($PSBoundParameters.ContainsKey("Reasons")) {

                        Write-Verbose -Message "Setting reasons: $($Reasons)"

                        $Object.reasons = $reasons

                        }

                    # --- Overwrite JSON variable with new content
                    $JSON = $Object | ConvertTo-Json -Depth 100 -Compress
                
                    }

                }
 
            if ($PSCmdlet.ShouldProcess($Id)){
                
                $URI = "/catalog-service/api/consumer/entitledCatalogItems/$($Id)/requests"
                
                $Response = Invoke-vRARestMethod -Method POST -URI $URI -Body $JSON -Verbose:$VerbosePreference
                
                if ($PSBoundParameters.ContainsKey("Wait")) {

                    While($true) {
                        
                        $URI = "/catalog-service/api/consumer/requests/$($Response.Id)"                       
                        
                        $Request = Invoke-vRARestMethod -Method Get -URI $URI -Verbose:$VerbosePreference

                        Write-Verbose -Message "State: $($Request.state)"
                        
                        if ($Request.state -eq "SUCCESSFUL" -or $Request.state -Like "*FAILED") {
                            
                            if ($Request.state -Like "*FAILED") {
                                
                                throw "$($Request.requestCompletion.completionDetails)"
                                
                            }
                            
                            Write-Verbose -Message "Request $($Request.id) was successful"
                            break
                        }
                        
                        Start-Sleep -Seconds 5
                        
                    }
                    
                }

                # --- Return the request
                Get-vRARequest -Id $Response.Id

            }

        }
        catch [Exception]{

            throw

        }    

    }

    End {

    }

}

<#
    - Function: Request-vRAResourceAction
#>

function Request-vRAResourceAction {
<#
    .SYNOPSIS
    Request an available resourceAction for a catalog resource
    
    .DESCRIPTION
    A resourceAction is a specific type of ResourceOperation that is performed by submitting a request. 
    Unlike ResourceExtensions, resource actions can be invoked via the Service Catalog service and subject to approvals.
    
    .PARAMETER ActionId
    The Id for the resource action
    
    .PARAMETER ResourceId
    The id of the resource that the resourceAction will execute against

    .PARAMETER ResourceName
    The name of the resource that the resourceAction will execute against

    .PARAMETER JSON
    A JSON payload for the request

    .PARAMETER Wait
    Wait for the request to complete

    .INPUTS
    System.String

    .EXAMPLE
    $ResourceActionId = (Get-vRAResource -Name vm01 | Get-vRAResourceAction | Where-Object {$_.Name -eq "Reboot"}).id
    Request-vRAResourceAction -Id $ResourceActionId -ResourceName vm01

    .EXAMPLE
    Request-vRAResourceAction -Id 6a301f8c-d868-4908-8348-80ad0eb35b00 -ResourceId 20402e93-fb1d-4bd9-8a51-b809fbb946fd

    .EXAMPLE
    Request-vRAResourceAction -Id 6a301f8c-d868-4908-8348-80ad0eb35b00 -ResourceName vm01

    .EXAMPLE
    Request-vRAResourceAction -Id 6a301f8c-d868-4908-8348-80ad0eb35b00 -ResourceName vm01 -Wait

    .EXAMPLE

    $JSON = @"
        {
            "type":  "com.vmware.vcac.catalog.domain.request.CatalogResourceRequest",
            "resourceId":  "448fcd09-b8c0-482c-abbc-b3ab818c2e31",
            "actionId":  "fae08c75-3506-40f6-9c9b-35966fe9125c",
            "description":  null,
            "data":  {
                         "description":  null,
                         "reasons":  null
                     }
        }        
    "@

    $JSON | Request-vRAResourceAction

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="ByResourceId")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="ByResourceId")]
        [Parameter(Mandatory=$true,ParameterSetName="ByResourceName")]
        [ValidateNotNullOrEmpty()]
        [Alias('Id')]
        [String]$ActionId,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ByResourceId")]
        [ValidateNotNullOrEmpty()]
        [String]$ResourceId,

        [Parameter(Mandatory=$true,ParameterSetName="ByResourceName")]
        [ValidateNotNullOrEmpty()]
        [String]$ResourceName,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true, ParameterSetName="JSON")]
        [ValidateNotNullOrEmpty()]
        [String]$JSON,
        
        [Parameter(Mandatory=$false)] 
        [Switch]$Wait

    )

    Begin {

        xRequires -Version 7.0

    }

    Process {
                
         try {

            switch ($PsCmdlet.ParameterSetName) {

                'JSON' {

                    # --- Extract id's from json payload
                    $Body = $JSON | ConvertFrom-Json
                    $ResourceId = $Body.resourceId
                    $ActionId = $Body.actionId

                    break

                }

                'ByResourceName' {

                    # --- Get the resource id
                    Write-verbose -Message "Retrieving Id for resource $($Name)"
                    $Resource = Get-vRAResource -Name $ResourceName
                    $ResourceId = $Resource.ResourceId

                    break

                }

            }

            if (!$PSBoundParameters.ContainsKey("JSON")) {

                # --- Get the request template
                Write-Verbose -Message "Retrieving request template"

                $JSON = Get-vRAResourceActionRequestTemplate -ActionId $ActionId -ResourceId $ResourceId

            }

            # --- Execute the request
            if ($PSCmdlet.ShouldProcess($ResourceId)){

                $URI = "/catalog-service/api/consumer/resources/$($ResourceId)/actions/$($ActionId)/requests"

                $Response = Invoke-vRARestMethod -Method POST -URI $URI -Body $JSON -WebRequest -Verbose:$VerbosePreference

                   $ResponseId = ($Response.Headers.Location) -replace '^http.*requests/',''

                   if ($PSBoundParameters.ContainsKey("Wait")) {

                       While($true) {

                           $URI = "/catalog-service/api/consumer/requests/$ResponseId"

                           $Request = Invoke-vRARestMethod -Method Get -URI $URI -Verbose:$VerbosePreference

                           Write-Verbose -Message "State: $($Request.state)"

                           if ($Request.state -eq "SUCCESSFUL" -or $Request.state -Like "*FAILED") {

                               if ($Request.state -Like "*FAILED") {

                                   throw "$($Request.requestCompletion.completionDetails)"

                               }

                               Write-Verbose -Message "Request ($ResponseId) was successful"

                               break

                           }

                           Start-Sleep -Seconds 5

                       }

                   }

                   # --- Return the request
                   Get-vRARequest -Id $ResponseId

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}


<#
    - Function: Set-vRACatalogItem
#>

function Set-vRACatalogItem {
<#
    .SYNOPSIS
    Update a vRA catalog item
    
    .DESCRIPTION
    Update a vRA catalog item    

    .PARAMETER Id
    The id of the catalog item
    
    .PARAMETER Status
    The status of the catalog item (e.g. PUBLISHED, RETIRED, STAGING)   
    
    .PARAMETER Quota
    The Quota of the catalog item
    
    .PARAMETER Service
    The Service to assign the catalog item to
    
    .PARAMETER NewAndNoteworthy
    Mark the catalog item as New and noteworthy in the UI

    .PARAMETER IconId
    The Icon Id of the catalog item. This must already exist in the Service Catalog. Typically it would have already been created via Import-vRAServiceIcon
    
    .INPUTS
    System.Int
    System.String
    System.Bool

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE    
    Set-vRACatalogItem -Id dab4e578-57c5-4a30-b3b7-2a5cefa52e9e -Status PUBLISHED
    
    .EXAMPLE    
    Set-vRACatalogItem -Id dab4e578-57c5-4a30-b3b7-2a5cefa52e9e -Quota 1
    
    .EXAMPLE    
    Set-vRACatalogItem -Id dab4e578-57c5-4a30-b3b7-2a5cefa52e9e -Service "Default Service" 
    
    .EXAMPLE    
    Set-vRACatalogItem -Id dab4e578-57c5-4a30-b3b7-2a5cefa52e9e -NewAndNoteworthy $false

    .EXAMPLE    
    Get-vRACatalogItem  -Name "Create cluster" | Set-vRACatalogItem -IconId "cafe_icon_CatalogItem01" -Confirm:$false           
    
    TODO:
    - Investigate / fix authorization error 
    
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter(Mandatory=$false,ParameterSetName="SetStatus")]
        [ValidateSet("PUBLISHED","RETIRED","STAGING")]
        [String]$Status,
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Quota,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$Service,
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Bool]$NewAndNoteworthy,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$IconId
    
    )    

    Begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    Process {

        # --- Check for existing catalog item        
        try {

            Write-Verbose -Message "Testing for existing catalog item"                       
                
            #$CatalogItem = Get-vRACatalogItem -Id $($Id)                             

            $URI = "/catalog-service/api/catalogItems/$($Id)"
            $CatalogItem = Invoke-vRARestMethod -Method GET -URI $URI          
            
            
        }
        catch [Exception] {
            
            throw
            
        }
        
        if ($PSBoundParameters.ContainsKey("Status")){

                Write-Verbose -Message "Updating Status: $($CatalogItem.status) >> $($Status)"
                $CatalogItem.status = $Status

            }
            
        if ($PSBoundParameters.ContainsKey("Quota")){

                Write-Verbose -Message "Updating Quota: $($CatalogItem.quota) >> $($Quota)"
                $CatalogItem.quota = $Quota

            }
            
        if ($PSBoundParameters.ContainsKey("Service")){

                $NewService = Get-vRAService -Name $($Service)

                # --- If the catalog item does not currently have service assigned, add one
                if (-not($CatalogItem.serviceRef)) {

                    Write-Verbose -Message "Associating catalog item with service $($Service)"

                    $ServiceRef = [PSCustomObject] @{

                        id = $NewService.Id;
                        name = $NewService.Name;

                        }

                    $CatalogItem | Add-Member -MemberType NoteProperty -Name "serviceRef" -Value $ServiceRef -Force

                    }
                else {                             
                
                    Write-Verbose -Message "Updating Service >> $($Service)"
                
                    $CatalogItem.serviceRef.id = $NewService.Id
                    $CatalogItem.serviceRef.label = $NewService.Name

                    }
            } 
            
        if ($PSBoundParameters.ContainsKey("NewAndNoteworthy")){

                Write-Verbose -Message "Updating isNoteworthy: $($CatalogItem.isNoteworthy) >> $($NewAndNoteworthy)"

                $CatalogItem.isNoteworthy = $NewAndNoteworthy

            }

        if ($PSBoundParameters.ContainsKey("IconId")){

                Write-Verbose -Message "Updating IconId: $($CatalogItem.iconId) >> $($IconId)"
                $CatalogItem.iconId = $IconId

            }

        # --- Update the existing catalog item
        try {
            if ($PSCmdlet.ShouldProcess($Id)){
                
                # --- Build the URI string for the catalog item   
                $URI = "/catalog-service/api/catalogItems/$($Id)"      
            
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($CatalogItem | ConvertTo-Json -Depth 100) -Verbose:$VerbosePreference | Out-Null
                Get-vRACatalogItem -Id $($CatalogItem.id)
                
            }
                        
        }
        catch [Exception] {
            
            throw
            
        }
    
    }  

    End {

    }  

}

<#
    - Function: Set-vRAEntitlement
#>

function Set-vRAEntitlement {
<#
    .SYNOPSIS
    Update an existing entitlement

    .DESCRIPTION
    Update an existing entitlement

    .PARAMETER Id
    The id of the entitlement

    .PARAMETER Name
    The name of the entitlement

    .PARAMETER Description
    A description of the entitlement

    .PARAMETER Principals
    Users or groups that will be associated with the entitlement

    .PARAMETER EntitledCatalogItems
    One or more entitled catalog item 

    .PARAMETER EntitledResourceOperations
    The externalId of one or more entitled resource operation (e.g. Infrastructure.Machine.Action.PowerOn)

    .PARAMETER EntitledServices
    One or more entitled service 

    .PARAMETER Status
    The status of the entitlement. Accepted values are ACTIVE and INACTIVE

    .PARAMETER LocalScopeForActions
    Determines if the entitled actions are entitled for all applicable service catalog items or only
    items in this entitlement

    .PARAMETER AllUsers
    Add all users to the entitlement

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Set-vRAEntitlement -Id "e5cd1c84-3b76-4ae9-9f2e-35114da6cfd2" -Name "Updated Name"

    .EXAMPLE
    Set-vRAEntitlement -Id "e5cd1c84-3b76-4ae9-9f2e-35114da6cfd2" -Name "Updated Name" -Description "Updated Description" -Principals "user@vsphere.local" -EntitledCatalogItems "Centos" -EntitledServices "A service" -EntitledResourceOperations "Infrastructure.Machine.Action.PowerOff" -Status ACTIVE

    .EXAMPLE
    Set-vRAEntitlement -Id "e5cd1c84-3b76-4ae9-9f2e-35114da6cfd2" -Name "Updated Name" -Description "Updated Description" -AllUsers:$true

    .EXAMPLE
    Get-vRAEntitlement -Name "Entitlement 1" | Set-vRAEntitlement -Description "Updated description!"

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Principals,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$EntitledCatalogItems,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$EntitledResourceOperations,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$EntitledServices,

        [Parameter(Mandatory=$false)]
        [ValidateSet("ACTIVE","INACTIVE")]
        [String]$Status,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [bool]$LocalScopeForActions,
		
		[Parameter(Mandatory=$false, ParameterSetName='AllUsers')]
        [ValidateNotNullOrEmpty()]
        [bool]$AllUsers

    )    

    Begin {
    
    }
    
    Process {

        try {

            Write-Verbose -Message "Testing for existing entitlement"

            $URI = "/catalog-service/api/entitlements/$($Id)"

            $Entitlement = Invoke-vRARestMethod -URI $URI -Method Get

            # --- Update name
            if ($PSBoundParameters.ContainsKey("Name")){

            Write-Verbose -Message "Updating Name: $($Entitlement.name) >> $($Name)"
            $Entitlement.name = $Name

            }

            # --- Update description
            if ($PSBoundParameters.ContainsKey("Description")){

            Write-Verbose -Message "Updating Description: $($Entitlement.description) >> $($Description)"
            $Entitlement.description = $Description

            }

            # --- Update principals
            if ($PSBoundParameters.ContainsKey("Principals")) {

                foreach($Principal in $Principals) {

                    Write-Verbose -Message "Adding principal: $($Principal)"

                    $CatalogPrincipal = Get-vRACatalogPrincipal -Id $Principal

                    $Entitlement.principals += $CatalogPrincipal


                }

            }
                
            # --- Update entitled catalog items
            if ($PSBoundParameters.ContainsKey("EntitledCatalogItems")) {

                foreach($CatalogItem in $EntitledCatalogItems) {

                    Write-Verbose "Adding entitled catalog item: $($CatalogItem)"

                    # --- Build catalog item ref object
                    $CatalogItemRef = [PSCustomObject] @{

                        id = $((Get-vRACatalogItem -Name $CatalogItem).Id)
                        label = $null

                    }
                        
                    # --- Build entitled catalog item object and insert catalogItemRef
                    $EntitledCatalogItem = [PSCustomObject] @{

                    approvalPolicyId = $null
                    active = $null
                    catalogItemRef = $CatalogItemRef

                    }

                    $Entitlement.entitledCatalogItems += $EntitledCatalogItem

                }

            }

            # ---  Update entitled services             
            if ($PSBoundParameters.ContainsKey("EntitledServices")) {

                foreach($Service in $EntitledServices) {

                    Write-Verbose -Message "Adding service: $($Service)"

                    # --- Build service ref object
                    $ServiceRef = [PSCustomObject] @{

                    id = $((Get-vRAService -Name $Service).Id)
                    label = $null

                    }
                        
                    # --- Build entitled service object and insert serviceRef
                    $EntitledService = [PSCustomObject] @{

                        approvalPolicyId = $null
                        active = $null
                        serviceRef = $ServiceRef

                    }

                    $Entitlement.entitledServices += $EntitledService

                }

            }

            # --- Update entitled resource operations
            if ($PSBoundParameters.ContainsKey("EntitledResourceOperations")) {

                foreach ($ResourceOperation in $EntitledResourceOperations) {

                    Write-Verbose -Message "Adding resouceoperation: $($resourceOperation)"

                    $Operation = Get-vRAResourceOperation -ExternalId $ResourceOperation

                    $ResourceOperationRef = [PSCustomObject] @{

                        id = $Operation.Id
                        label = $null

                    }

                    $EntitledResourceOperation = [PSCustomObject] @{

                        approvalPolicyId =  $null
                        resourceOperationType = "ACTION"
                        externalId = $Operation.ExternalId
                        active = $true
                        resourceOperationRef = $ResourceOperationRef
                        targetResourceTypeRef = $Operation.TargetResourceTypeRef

                    }

                    $Entitlement.entitledResourceOperations += $EntitledResourceOperation

                }

            }

            # --- Update status
            if ($PSBoundParameters.ContainsKey("Status")) {

                Write-Verbose -Message "Updating Status: $($Entitlement.status) >> $($Status)"
                $Entitlement.status = $Status

            }

            # --- Update LocalScopeForActions
            if ($PSBoundParameters.ContainsKey("LocalScopeForActions")) {

                Write-Verbose -Message "Updating LocalScopeForActions: $($Entitlement.localScopeForActions) >> $($LocalScopeForActions)"
                $Entitlement.localScopeForActions = $LocalScopeForActions

            }
			
	    # --- Update AllUsers
            if ($PSBoundParameters.ContainsKey("AllUsers")) {

                Write-Verbose -Message "Updating AllUsers: $($Entitlement.AllUsers) >> $($AllUsers)"
                $Entitlement.AllUsers = $AllUsers

            }
			
            # --- Convert the modified entitlement to json 
            $Body = $Entitlement | ConvertTo-Json -Depth 50 -Compress

            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/catalog-service/api/entitlements/$($Id)"
                
                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRAEntitlement -Id $Id
            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}


<#
    - Function: Set-vRAService
#>

function Set-vRAService {
<#
    .SYNOPSIS
    Set a vRA Service
    
    .DESCRIPTION
    Set a vRA Service

    Currently unsupported interactive actions:

    * HoursStartTime
    * HoursEndTime
    * ChangeWindowDayOfWeek
    * ChangeWindowStartTime
    * ChangeWindowEndTime
 
    .PARAMETER Id
    The id of the service

    .PARAMETER Name
    The name of the service

    .PARAMETER Description
    A description of the service

    .PARAMETER Status
    The status of the service

    .PARAMETER Owner
    The owner of the service

    .PARAMETER SupportTeam
    The support team of the service

    .PARAMETER IconId
    The Icon Id of the service. This must already exist in the Service Catalog. Typically it would have already been created via Import-vRAServiceIcon

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAService -Name "Default" | Set-vRAService -Owner user@vsphere.local   
    
    .EXAMPLE   
    Set-vRAService -Id 25c0f3db-5906-4d42-8633-7b05f695432c -Name "Default 1"

    .EXAMPLE   
    Set-vRAService -Id 25c0f3db-5906-4d42-8633-7b05f695432c -Name "Default 1" -Description "updated from posh"

    .EXAMPLE   
    Set-vRAService -Id 25c0f3db-5906-4d42-8633-7b05f695432c -Name "Default 1" -Description "updated from posh" -Owner "user@vsphere.local"

    .EXAMPLE   
    Set-vRAService -Id 25c0f3db-5906-4d42-8633-7b05f695432c -Name "Default 1" -Description "updated from posh" -Owner "user@vsphere.local" -SupportTeam "support@vsphere.local"

    .EXAMPLE   
    Set-vRAService -Id 25c0f3db-5906-4d42-8633-7b05f695432c -Name "Default 1" -Description "updated from posh" -Owner "user@vsphere.local" -SupportTeam "support@vsphere.local" -Status INACTIVE
    
    .EXAMPLE   
    Set-vRAService -Id 25c0f3db-5906-4d42-8633-7b05f695432c -Name "Default 1" -Description "updated from posh" -Owner "user@vsphere.local" -SupportTeam "support@vsphere.local" -Status INACTIVE -IconId "cafe_icon_Service01"
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (
        
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,            

        [Parameter(Mandatory=$false)]
        [ValidateSet("ACTIVE","RETIRED")]
        [String]$Status,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Owner,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$SupportTeam,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$IconId          
        
    )    

    Begin {
    
    }
    
    Process {

        # --- Check for existing service        
        try {

            Write-Verbose -Message "Testing for existing service"                       

            $URI = "/catalog-service/api/services/$($Id)"
            
            $Service = Invoke-vRARestMethod -Method GET -URI $URI

                        
        }
        catch [Exception] {
            
            throw
            
        }
        
        if ($PSBoundParameters.ContainsKey("Name")){

                Write-Verbose -Message "Updating Name: $($Service.name) >> $($Name)"
                $Service.name = $Name

            }

        if ($PSBoundParameters.ContainsKey("Description")){

               Write-Verbose -Message "Updating Description: $($Service.description) >> $($Description)"
               $Service.description = $Description

            }

        if ($PSBoundParameters.ContainsKey("Status")){
                
                Write-Verbose -Message "Updating Status: $($Service.status) >> $($Status)"
                $Service.status = $Status

            }

        if ($PSBoundParameters.ContainsKey("Owner")){

            # --- if the service does not have an owner, add one
            if(-not($Service.owner)) {

                Write-Verbose -Message "Adding owner principal: $($Owner)"

                $CatalogPrincipal = Get-vRACatalogPrincipal -Id $Owner   

                $Service | Add-Member -MemberType NoteProperty -Name "owner" -Value $catalogPrincipal    

            }
            else {

                Write-Verbose -Message "Updating Owner: $($Service.owner.ref) >> $($Owner)"           
                $Service.owner.ref = $Owner

                }

            }

        if ($PSBoundParameters.ContainsKey("SupportTeam")){

            # --- if the service does not have an support team, add one
            if(-not($Service.supportTeam)) {

                Write-Verbose -Message "Adding support team principal: $($SupportTeam)"

                $CatalogPrincipal = Get-vRACatalogPrincipal -Id $SupportTeam   

                $Service | Add-Member -MemberType NoteProperty -Name "supportTeam" -Value $catalogPrincipal    

            }
            else {

            Write-Verbose -Message "Updating Support Team: $($Service.supportTeam.ref) >> $($SupportTeam)"
            $Service.supportTeam.ref = $SupportTeam

            }
        }

        if ($PSBoundParameters.ContainsKey("IconId")){

                Write-Verbose -Message "Updating IconId: $($Service.iconId) >> $($IconId)"
                $Service.iconId = $IconId

            }

        # --- Update the existing service
        try {
            if ($PSCmdlet.ShouldProcess($Service.Name)){
                
                # --- Build the URI string for the service         
            
                $URI = "/catalog-service/api/services/$($Id)"
                           
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Service | ConvertTo-Json -Compress) -Verbose:$VerbosePreference | Out-Null

                Get-vRAService -Id $Id
                
            }
                        
        }
        catch [Exception] {
            
            throw
            
        }
    
    }

    End {
        
    }

}

<#
    - Function: Get-vRAApplianceServiceStatus
#>

function Get-vRAApplianceServiceStatus {
<#
    .SYNOPSIS
    Get information about vRA services

    Deprecated. Use Get-vRAComponentRegistryServiceStatus instead.
    
    .DESCRIPTION
    Get information about vRA services. These are the same services that you will see via the service tab 
    
    Deprecated. Use Get-vRAComponentRegistryServiceStatus instead.
    
    .PARAMETER Name
    The name of the service to query

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
     Get-vRAApplianceServiceStatus

    .EXAMPLE
     Get-vRAApplianceServiceStatus -Limit 9999
    
    .EXAMPLE
     Get-vRAApplianceServiceStatus -Name iaas-service
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,
        
        [Parameter(Mandatory=$false,ValueFromPipeline=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Limit = "100"    
       
    )   

    try {

        Write-Warning -Message "This function is now deprecated. Please use Get-vRAComponentRegsitryService instead"

        # --- Build base URI with limit 
        $URI =  "/component-registry/services/status/current?limit=$($Limit)"

        # --- If the name parameter is passed returned detailed information about the service
        if ($PSBoundParameters.ContainsKey("Name")){
                    
            foreach ($ServiceName in $Name) {
            
                $Filter = "name%20eq%20'$($ServiceName)'" 

                Write-Verbose -Message "Preparing GET to $($URI)&`$filter=$($Filter)"

                $Response = Invoke-vRARestMethod -Method GET -URI "$($URI)&`$filter=$($Filter)"

                Write-Verbose -Message "SUCCESS"

                if ($Response.content.Length -eq 0) {

                    throw "Could not find service"

                }

                [pscustomobject]@{

                    Id = $Response.content.serviceId
                    Name = $Response.content.serviceName
                    TypeId = $Response.content.serviceTypeId
                    NotAvailable = $Response.content.notAvailable
                    LastUpdated = $Response.content.lastUpdated
                    EndpointUrl = $Response.content.statusEndPointUrl

                    Initialized = $Response.content.serviceStatus.initialized
                    SolutionUser = $Response.content.serviceStatus.solutionUser
                    StartedTime = $Response.content.serviceStatus.startedTime
                    Status = $Response.content.serviceStatus.serviceInitializationStatus
                    ErrorMessage = $Response.content.serviceStatus.errorMessage
                    IdentityCertificateInfo = $Response.content.serviceStatus.identityCertificateInfo
                    ServiceRegistrationId = $Response.content.serviceStatus.serviceRegistrationId
                    SSLCertificateInfo = $Response.content.serviceStatus.sslCertificateInfo
                    DefaultServiceEndpointType = $Response.content.serviceStatus.defaultServiceEndpointType

                }

            }

        }
        else {
            
            Write-Verbose -Message "Preparing GET to $($URI)"

            $Response = Invoke-vRARestMethod -Method GET -URI $URI

            Write-Verbose -Message "SUCCESS"
            
            Write-Verbose -Message "Response contains $($Response.content.Length) records"

            foreach ($Service in $Response.content) {

                [pscustomobject]@{

                    Id = $Service.serviceId
                    Name = $Service.serviceName
                    TypeId = $Service.serviceTypeId
                    NotAvailable = $Service.notAvailable
                    LastUpdated = $Service.lastUpdated
                    EndpointUrl = $Response.content.statusEndPointUrl

                    Initialized = $Service.serviceStatus.initialized
                    SolutionUser = $Service.serviceStatus.solutionUser
                    StartedTime = $Service.serviceStatus.startedTime
                    Status = $Service.serviceStatus.serviceInitializationStatus
                    ErrorMessage = $Service.serviceStatus.errorMessage
                    IdentityCertificateInfo = $Service.serviceStatus.identityCertificateInfo
                    ServiceRegistrationId = $Service.serviceStatus.serviceRegistrationId
                    SSLCertificateInfo = $Service.serviceStatus.sslCertificateInfo
                    DefaultServiceEndpointType = $Service.serviceStatus.defaultServiceEndpointType

                }

            }
    
        }
           
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRAComponentRegistryService
#>

function Get-vRAComponentRegistryService {
<#
    .SYNOPSIS
    Get information about vRA services
    
    .DESCRIPTION
    Get information about vRA services.

    .PARAMETER Id
    The Id of the service. Specifying the Id of the service will retrieve detailed information.
    
    .PARAMETER Name
    The name of the service

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int
    System.Management.Automation.SwitchParameter

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
     Get-vRAComponentRegistryService

    .EXAMPLE
     Get-vRAComponentRegistryService -Limit 9999

    .EXAMPLE
     Get-vRAComponentRegistryService -Page 1

    .EXAMPLE
    Get-vRAComponentRegistryService -Id xxxxxxxxxxxxxxxxxxxxxxxx

    .EXAMPLE
    Get-vRAComponentRegistryService -Name "iaas-service"

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [parameter(Mandatory=$true, ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100
       
    )

    Begin {

        $BaseURI = "/component-registry/services"

    }

    Process {

        try {

            switch($PSCmdlet.ParameterSetName) {

                'ById'{

                    foreach ($ServiceId in $Id) {

                        $URI = "$($BaseURI)/$($ServiceId)"

                        $Service = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            CreatedDate = $Service.createdDate
                            LastUpdated = $Service.lastUpdated
                            OwnerId = $Service.ownerId
                            ServiceVersion = $Service.serviceVersion
                            ServiceAttributes = $Service.serviceAttributes
                            EndPoints = $Service.endPoints
                            ServiceType = $Service.serviceType
                            NameMsgKey = $Service.nameMsgKey

                        }

                    }

                    break
                }

                'ByName' {

                    foreach ($ServiceName in $Name) {

                        $URI = "$($BaseURI)?`$filter=name eq '$($ServiceName)'"            

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Service = (Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference).content

                        if ($Service.Length -eq 0) {

                            throw "Could not find service with name $($ServiceName)"

                        }

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            CreatedDate = $Service.createdDate
                            LastUpdated = $Service.lastUpdated
                            OwnerId = $Service.ownerId
                            ServiceVersion = $Service.serviceVersion
                            ServiceAttributes = $Service.serviceAttributes
                            EndPoints = $Service.endPoints
                            ServiceType = $Service.serviceType
                            NameMsgKey = $Service.nameMsgKey

                        }

                    }

                    break
                }

                'Standard' {

                    # --- Build up the URI string depending on switch
                    $URI = "$($BaseURI)?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                    foreach ($Service in $Response.content) {

                        [PSCustomObject] @{

                            Id = $Service.id
                            Name = $Service.name
                            CreatedDate = $Service.createdDate
                            LastUpdated = $Service.lastUpdated
                            OwnerId = $Service.ownerId
                            ServiceVersion = $Service.serviceVersion
                            ServiceAttributes = $Service.serviceAttributes
                            EndPoints = $Service.endPoints
                            ServiceType = $Service.serviceType
                            NameMsgKey = $Service.nameMsgKey

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break
                }

            }
            
        }
        catch [Exception]{
            
            throw

        }   


    }
     
}



<#
    - Function: Get-vRAComponentRegistryServiceEndpoint
#>

function Get-vRAComponentRegistryServiceEndpoint {
<#
    .SYNOPSIS
    Retrieve a list of endpoints for a service

    .DESCRIPTION
    Retrieve a list of endpoints for a service

    .PARAMETER Id
    The Id of the service. Specifying the Id of the service will retrieve detailed information.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
     Get-vRAComponentRegistryServiceEndpoint

    .EXAMPLE
    Get-vRAComponentRegistryService -Id xxxxxxxxxxxxxxxxxxxxxxxx | Get-vRAComponentRegistryServiceEndpoint

#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id
    )

    Begin {

    }

    Process {

        try {

            foreach ($ServiceId in $Id) {

                $URI = "/component-registry/services/$($ServiceId)/endpoints"
                $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                foreach ($Endpoint in $Response.content) {

                    [PSCustomObject] @{

                        Id = $Endpoint.id
                        CreatedDate = $Endpoint.createdDate
                        LastUpdated = $Endpoint.lastUpdated
                        Url = $Endpoint.url
                        EndPointType = $Endpoint.endpointType
                        ServiceInfoId = $Endpoint.serviceInfoId
                        EndPointAttributes = $Endpoint.endPointAttributes
                        SSlTrusts = $Endpoint.sslTrusts

                    }

                }

            }

            Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

        } catch [Exception] {

            throw
        }

    }

    End {

    }

}



<#
    - Function: Get-vRAComponentRegistryServiceStatus
#>

function Get-vRAComponentRegistryServiceStatus {
<#
    .SYNOPSIS
    Get component registry service status
    
    .DESCRIPTION
    Get component registry service status

    .PARAMETER Id
    The Id of the service
    
    .PARAMETER Name
    The name of the service

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int
    System.Management.Automation.SwitchParameter

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
     Get-vRAComponentRegistryServiceStatus

    .EXAMPLE
     Get-vRAComponentRegistryServiceStatus -Limit 9999

    .EXAMPLE
     Get-vRAComponentRegistryServiceStatus -Page 1

    .EXAMPLE
     Get-vRAComponentRegistryServiceStatus -Id xxxxxxxxxxxxxxxxxxxxxxxx

    .EXAMPLE
     Get-vRAComponentRegistryServiceStatus -Name "iaas-service"

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [parameter(Mandatory=$true, ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100
       
    )

    Begin {

        $BaseURI = "/component-registry/services/status"

    }

    Process {

        try {

            switch($PSCmdlet.ParameterSetName) {

                'ById'{

                    foreach ($ServiceId in $Id) {

                        $URI = "$($BaseURI)/current/$($ServiceId)"

                        $Service = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject]@{

                            Id = $Service.serviceId
                            Name = $Service.serviceName
                            TypeId = $Service.serviceTypeId
                            NotAvailable = $Service.notAvailable
                            LastUpdated = $Service.lastUpdated
                            EndpointUrl = $Service.statusEndPointUrl
                            ServiceStatus = $Service.serviceStatus
                        }

                    }

                    break
                }

                'ByName' {

                    foreach ($ServiceName in $Name) {

                        $URI = "$($BaseURI)/current?`$filter=name eq '$($ServiceName)'"            

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Service = (Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference).content

                        if ($Service.Length -eq 0) {

                            throw "Could not find service with name $($ServiceName)"

                        }

                        [PSCustomObject]@{

                            Id = $Service.serviceId
                            Name = $Service.serviceName
                            TypeId = $Service.serviceTypeId
                            NotAvailable = $Service.notAvailable
                            LastUpdated = $Service.lastUpdated
                            EndpointUrl = $Service.statusEndPointUrl
                            ServiceStatus = $Service.serviceStatus
                        }

                    }

                    break
                }

                'Standard' {

                    $URI = "$($BaseURI)/current/?limit=$($Limit)&page=$($Page)&`$orderby=name asc"
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                    foreach ($Service in $Response.content) {

                        [PSCustomObject]@{

                            Id = $Service.serviceId
                            Name = $Service.serviceName
                            TypeId = $Service.serviceTypeId
                            NotAvailable = $Service.notAvailable
                            LastUpdated = $Service.lastUpdated
                            EndpointUrl = $Service.statusEndPointUrl
                            ServiceStatus = $Service.serviceStatus
                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break
                }

            }
            
        }
        catch [Exception]{
            
            throw

        }   


    }

}

<#
    - Function: Add-vRACustomForm
#>

function Add-vRACustomForm {
<#
    .SYNOPSIS
    Add a vRA Custom Form for a Blueprint

    .DESCRIPTION
    Add a vRA Custom Form for a Blueprint

    .PARAMETER BlueprintId
    Specify the ID of a Blueprint

    .PARAMETER Body
    The JSON string containing the custom form

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    .EXAMPLE
    $JSON = Get-Content -Path ~/CentOS.json -Raw
    Add-vRACustomForm -BlueprintId "CentOS" -Body $JSON

    .EXAMPLE
    $JSON = Get-Content -Path ~/CentOS.json -Raw
    Get-vRABlueprint -Name "CentOS" | Add-vRACustomForm -Body $JSON

    .EXAMPLE
    $Form = Get-vRABlueprint -Name "CentOS" | Get-vRACustomForm
    Add-vRACustomForm -BlueprintId "RHEL7" | Add-vRACustomForm -Body $Form.JSON


#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (

      [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
      [Alias("id")]
      [ValidateNotNullOrEmpty()]
      [String[]]$BlueprintId,

      [parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]
      [String]$Body

    )
    begin {
      #Initialize
      Write-Verbose -Message "Initializing..."

      #Create PSObject for Output
      function StandardOutput ($Blueprint,$CustomFormId){
          [pscustomobject]@{

            BlueprintID = $Blueprint
            CustomFormId = $CustomFormId

          }
      }

      #Test vRA API version
      xRequires -Version 7.4

    }
    process {
      #Process
      Write-Verbose -Message "Processing..."

        try {

            foreach ($bp in $BlueprintId){
              if($PSCmdlet.ShouldProcess($bp)){
                $URI = "/composition-service/api/blueprints/$($bp)/forms/requestform"
                $JSON = $Body
                # --- Run vRA REST Request
                Write-Verbose -Message "Adding vRA Custom Form for blueprint $($bp)"
                Write-Verbose -Message "Posting $($JSON)"
                $Response = Invoke-vRARestMethod -Method POST -URI $URI -Body $($JSON)
                StandardOutput($bp)($Response)
              }
            }

        }
        catch [Exception]{
            throw
        }
    }
    end {
      #Finalize
      Write-Verbose -Message "Finalizing..."

    }
}


<#
    - Function: Get-vRABlueprint
#>

function Get-vRABlueprint {
<#
    .SYNOPSIS
    Retrieve vRA Blueprints

    .DESCRIPTION
    Retrieve vRA Blueprints

    .PARAMETER Id
    Specify the ID of a Blueprint

    .PARAMETER Name
    Specify the Name of a Blueprint

    .PARAMETER ExtendedProperties
    Return Blueprint Extended Properties. Performance will be slower since
    additional API requests may be required

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRABlueprint

    .EXAMPLE
    Get-vRABlueprint -Id "309100fd-b8ce-4e8c-ac8c-a667b8ace54f"

    .EXAMPLE
    Get-vRABlueprint -Name "Blueprint01","Blueprint02"

    .EXAMPLE
    Get-vRABlueprint -Name "Blueprint01","Blueprint02" -ExtendedProperties
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name,

    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [Switch]$ExtendedProperties,

    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"
    )

    # --- Add begin, process, end
    # -- Functions for standard and extended output
    begin {

        # --- Test for vRA API version
        xRequires -Version 7.0

        function StandardOutput ($Blueprint) {

            [pscustomobject]@{

                Name = $Blueprint.name
                Id = $Blueprint.id
                Description = $Blueprint.description
                CreatedDate = $Blueprint.createdDate
                LastUpdated = $Blueprint.lastUpdated
                Version = $Blueprint.version
                PublishStatus = $Blueprint.publishStatusName
            }
        }
        function ExtendedOutput ($Blueprint) {

            [pscustomobject]@{

                Name = $Blueprint.name
                Id = $Blueprint.id
                Description = $Blueprint.description
                CreatedDate = $Blueprint.createdDate
                LastUpdated = $Blueprint.lastUpdated
                Version = $Blueprint.version
                PublishStatus = $Blueprint.publishStatusName
                Components = $Blueprint.components
                Properties = $Blueprint.properties
                PropertyGroups = $Blueprint.propertyGroups
                ExternalId = $Blueprint.externalId
                Layout = $Blueprint.layout
                SnapshotVersion = $Blueprint.snapshotVersion
            }
        }
    }

    process {

        try {
            switch ($PsCmdlet.ParameterSetName)
            {
                "ById"  {

                    foreach ($BlueprintId in $Id){

                        $URI = "/composition-service/api/blueprints/$($BlueprintId)"

                        # --- Run vRA REST Request
                        $ReturnedBlueprint = Invoke-vRARestMethod -Method GET -URI $URI

                        if ($PSBoundParameters.ContainsKey('ExtendedProperties')){

                            ExtendedOutput($ReturnedBlueprint)
                        }
                        else {
                            StandardOutput($ReturnedBlueprint)
                        }
                    }

                    break
                }

                "ByName"  {

                foreach ($BlueprintName in $Name){

                        $URI = "/composition-service/api/blueprints?`$filter=name%20eq%20'$($BlueprintName)'"

                        # --- Run vRA REST Request
                        $Response = Invoke-vRARestMethod -Method GET -URI $URI
                        $Blueprints = $Response.content

                        if (-not $Blueprints){

                            throw "Unable to find vRA Blueprint: $($BlueprintName)"
                        }

                        foreach ($ReturnedBlueprint in $Blueprints){

                            if ($PSBoundParameters.ContainsKey('ExtendedProperties')){

                                $URI = "/composition-service/api/blueprints/$($ReturnedBlueprint.id)"

                                # --- Run vRA REST Request
                                $ReturnedExtendedBlueprint = Invoke-vRARestMethod -Method GET -URI $URI

                                ExtendedOutput($ReturnedExtendedBlueprint)
                            }
                            else {

                                StandardOutput($ReturnedBlueprint)
                            }
                        }
                    }

                    break
                }

                "Standard"  {

                    $URI = "/composition-service/api/blueprints?limit=$($Limit)"

                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI
                    $Blueprints = $Response.content

                    foreach ($ReturnedBlueprint in $Blueprints){

                        if ($PSBoundParameters.ContainsKey('ExtendedProperties')){

                            $URI = "/composition-service/api/blueprints/$($ReturnedBlueprint.id)"

                            # --- Run vRA REST Request
                            $ReturnedExtendedBlueprint = Invoke-vRARestMethod -Method GET -URI $URI

                            ExtendedOutput($ReturnedExtendedBlueprint)
                        }
                        else {

                            StandardOutput($ReturnedBlueprint)
                        }
                    }

                    break
                }
            }
        }
        catch [Exception]{

            throw
        }
    }
    end {

    }
}

<#
    - Function: Get-vRACustomForm
#>

function Get-vRACustomForm {
<#
    .SYNOPSIS
    Retrieve vRA Custom Form for a Blueprint

    .DESCRIPTION
    Retrieve vRA Custom Form for a Blueprint

    .PARAMETER BlueprintId
    Specify the ID of a Blueprint

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    .EXAMPLE
    Get-vRACustomForm -BlueprintId "CentOS"

    .EXAMPLE
    Get-vRABlueprint -Name "CentOS" | Get-vRACustomForm


#>
[OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [Alias("id")]
    [ValidateNotNullOrEmpty()]
    [String[]]$BlueprintId

    )
    begin {
      #Initialize
      Write-Verbose -Message "Initializing..."

      #Create PSObject for Output
      function StandardOutput ($Blueprint,$CustomForm){
          [pscustomobject]@{

            BlueprintID = $Blueprint
            JSON = $CustomForm

          }
      }

      #Test vRA API version
      xRequires -Version 7.4

    }
    process {
      #Process
      Write-Verbose -Message "Processing..."

        try {

            foreach ($bp in $BlueprintId){
                $URI = "/composition-service/api/blueprints/$($bp)/forms/requestform"

                # --- Run vRA REST Request
                Write-Verbose -Message "Getting vRA Custom Form for blueprint $($bp)"
                try {
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI
                    $ReturnedForm = $Response.TrimStart('"').TrimEnd('"').Replace('\"','"');
                    StandardOutput($bp)($ReturnedForm)
                }
                catch {
                    Write-Warning -Message "Blueprint $($bp) does not have a custom form"
                }

            }

        }
        catch [Exception]{
            throw
        }
    }
    end {
      #Finalize
      Write-Verbose -Message "Finalizing..."

    }
}


<#
    - Function: Remove-vRACustomForm
#>

function Remove-vRACustomForm {
<#
    .SYNOPSIS
    Remove a vRA Custom Form for a Blueprint

    .DESCRIPTION
    Remove a vRA Custom Form for a Blueprint

    .PARAMETER BlueprintId
    Specify the ID of a Blueprint

    .INPUTS
    System.String

    .EXAMPLE
    Remove-vRACustomForm -BlueprintId "CentOS"

    .EXAMPLE
    Get-vRABlueprint -Name "CentOS" | Remove-vRACustomForm


#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

      [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
      [Alias("id")]
      [ValidateNotNullOrEmpty()]
      [String[]]$BlueprintId

    )
    begin {
      #Initialize
      Write-Verbose -Message "Initializing..."

      #Test vRA API version
      xRequires -Version 7.4

    }
    process {
      #Process
      Write-Verbose -Message "Processing..."

        try {
            foreach ($bp in $blueprintId){
                if($PSCmdlet.ShouldProcess($bp)){
                    $URI = "/composition-service/api/blueprints/$($bp)/forms/requestform"

                    # --- Run vRA REST Request
                    Write-Verbose -Message "Removing vRA Custom Form for blueprint $($bp)"
                    Invoke-vRARestMethod -Method DELETE -URI $URI
                }
            }
        }
        catch [Exception]{
            throw
        }
    }
    end {
      #Finalize
      Write-Verbose -Message "Finalizing..."

    }
}


<#
    - Function: Set-vRACustomForm
#>

function Set-vRACustomForm {
<#
    .SYNOPSIS
    Enable or Disable vRA Custom Form for a Blueprint

    .DESCRIPTION
    Enable or Disable a vRA Custom Form to a Blueprint

    .PARAMETER BlueprintId
    The objectId of the blueprint

    .PARAMETER Action
    The action to take on the Custom Form of the Blueprint

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    .EXAMPLE
    Set-vRACustomForm -BlueprintId "CentOS" -Action Enable

    .EXAMPLE
    Set-vRACustomForm -BlueprintId "CentOS" -Action Disable

    .EXAMPLE
    Get-vRABlueprint -Name "CentOS" | Set-vRACustomForm -Action Enable


#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.String')]

    Param (

      [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
      [Alias("id")]
      [ValidateNotNullOrEmpty()]
      [String[]]$BlueprintId,

      [parameter(Mandatory=$true,ValueFromPipeline=$false)]
      [ValidateSet("Enable","Disable")]
      [String]$Action

    )
    begin {
      #Initialize
      Write-Verbose -Message "Initializing..."

      #Change action to lower
      $action = $action.ToLower()

      #Test vRA API version
      xRequires -Version 7.4

    }
    process {
      #Process
      Write-Verbose -Message "Processing..."

        try {
            foreach ($bp in $blueprintId){
                if($PSCmdlet.ShouldProcess($bp)){
                    Write-Verbose -Message "Executing action $($action) on blueprint $($bp)"
                    $URI = "/composition-service/api/blueprints/$($bp)/forms/requestform/$($action)"

                    # --- Run vRA REST Request
                    Invoke-vRARestMethod -Method GET -URI $URI

                }
            }
        }
        catch [Exception]{
            throw
        }
    }
    end {
      #Finalize
      Write-Verbose -Message "Finalizing..."

    }
}


<#
    - Function: Export-vRAPackage
#>

function Export-vRAPackage {
<#
    .SYNOPSIS
    Export a vRA Package
    
    .DESCRIPTION
    Export a vRA Package
    
    .PARAMETER Id
    Specify the ID of a Package

    .PARAMETER Name
    Specify the Name of a Package

    .PARAMETER Path
    The resulting path. If this parameter is not passed the action will be exported to
    the current working directory.

    .INPUTS
    System.String

    .OUTPUTS
    System.IO.FileInfo
    
    .EXAMPLE
    Export-vRAPackage -Id "b2d72c5d-775b-400c-8d79-b2483e321bae" -Path C:\Packages\Package01.zip

    .EXAMPLE
    Export-vRAPackage -Name "Package01" -Path C:\Packages\Package01.zip

    .EXAMPLE
    Get-vRAPackage | Export-vRAPackage

    .EXAMPLE
    Get-vRAPackage -Name "Package01" | Export-vRAPackage -Path C:\Packages\Package01.zip

#>
[CmdletBinding(DefaultParameterSetName="ById")][OutputType('System.IO.FileInfo')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,         

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Path

    )

    Begin {

        # --- Test for vRA API version
        xRequires -Version 7.0

        function internalWorkings ($InternalPackage, $InternalId, $InternalPath) {
            
            $Headers = @{

                "Authorization" = "Bearer $($Global:vRAConnection.Token)";
                "Accept"="application/zip";
                "Content-Type" = "Application/zip";

            }
            
            $FileName = "$($InternalPackage.Name).zip"

            if (!$InternalPath) {

                Write-Verbose -Message "Path parameter not passed, exporting to current directory."
                $FullPath = "$($(Get-Location).Path)\$($FileName)"

            }
            else {

                Write-Verbose -Message "Path parameter passed."
                
                if ($InternalPath.EndsWith("\")) {

                    Write-Verbose -Message "Ends with"

                    $InternalPath = $InternalPath.TrimEnd("\")

                }
                
                $FullPath = "$($InternalPath)\$($FileName)"
            }

            # --- Run vRA REST Request
            $URI = "/content-management-service/api/packages/$($InternalId)"

            Invoke-vRARestMethod -Method GET -Headers $Headers -URI $URI -OutFile $FullPath -Verbose:$VerbosePreference

            # --- Output the result
            Get-ChildItem -Path $FullPath
        }
    }

    Process {

        try {    

            switch ($PsCmdlet.ParameterSetName) {
            
                'ByName' {

                    foreach ($PackageName in $Name) {

                        $Package = Get-vRAPackage -Name $PackageName
                        $Id = $Package.Id

                        internalWorkings -InternalPackage $Package -InternalId $Id -InternalPath $Path                   
                    }
                }
                'ById' {

                    foreach ($PackageId in $Id){

                        $Package = Get-vRAPackage -Id $PackageId

                        internalWorkings -InternalPackage $Package -InternalId $PackageId -InternalPath $Path
                    }
                }
            }
        }
        catch [Exception]{

            throw
        }
    }
}

<#
    - Function: Get-vRAContent
#>

function Get-vRAContent {
<#
    .SYNOPSIS
    Get available vRA content
    
    .DESCRIPTION
    Get available vRA content

    .PARAMETER Id
    The Id of the content

    .PARAMETER Name
    The name of the content

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAContent

    .EXAMPLE
    Get-vRAContent -Id b2d72c5d-775b-400c-8d79-b2483e321bae

    .EXAMPLE
    Get-vRAContent -Name "some content"
    
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (
    
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {

        xRequires -Version 7.0

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get content by id
                'ById' {

                    foreach ($ContentId in $Id) {
                
                        $URI = "/content-management-service/api/contents/$($ContentId)"

                        $Content = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $Content.id
                            ContentId = $Content.contentId
                            Name = $Content.name
                            Description = $Content.description
                            ContentTypeId = $Content.contentTypeId
                            MimeType = $Content.mimeType
                            TenantId = $Content.tenantId
                            SubtenantId = $Content.subtenantId
                            Dependencies = $Content.dependencies
                            CreatedDate = $Content.createdDate
                            LastUpdated = $Content.lastUpdated
                            Version = $Content.version

                        }

                    }

                    break

                }
                # --- Get content by name
                'ByName' {

                    foreach ($ContentName in $Name) { 

                        $URI = "/content-management-service/api/contents?`$filter=name eq '$($ContentName)'"            

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find content with name: $($ContentName)"

                        }

                        $Content = $Response.content

                        [PSCustomObject] @{

                            Id = $Content.id
                            ContentId = $Content.contentId
                            Name = $Content.name
                            Description = $Content.description
                            ContentTypeId = $Content.contentTypeId
                            MimeType = $Content.mimeType
                            TenantId = $Content.tenantId
                            SubtenantId = $Content.subtenantId
                            Dependencies = $Content.dependencies
                            CreatedDate = $Content.createdDate
                            LastUpdated = $Content.lastUpdated
                            Version = $Content.version

                        }

                    }

                    break

                }
                # --- No parameters passed so return all content
                'Standard' {

                    $URI = "/content-management-service/api/contents?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($Content in $Response.content) {

                        [PSCustomObject] @{

                            Id = $Content.id
                            ContentId = $Content.contentId
                            Name = $Content.name
                            Description = $Content.description
                            ContentTypeId = $Content.contentTypeId
                            MimeType = $Content.mimeType
                            TenantId = $Content.tenantId
                            SubtenantId = $Content.subtenantId
                            Dependencies = $Content.dependencies
                            CreatedDate = $Content.createdDate
                            LastUpdated = $Content.lastUpdated
                            Version = $Content.version

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRAContentData
#>

function Get-vRAContentData {
<#
    .SYNOPSIS
    Get the raw data associated with vRA content
    
    .DESCRIPTION
    Get the raw data associated with vRA content

    .PARAMETER Id
    The id of the content

    .PARAMETER SecureValueFormat
    How secure data will be represented in the export

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    .EXAMPLE
    Get-vRAContent -Name "Some Content" | Get-vRAContentData

    .EXAMPLE
    Get-vRAContent -Name "Some Content" | Get-vRAContentData | Out-File SomeContent.yml

#>
[CmdletBinding()][OutputType('System.String')]

    Param (
    
        [Parameter(Mandatory=$true,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$false)]
        [ValidateSet("BLANKOUT", "ENCRYPT", "DECRYPT")]
        [String]$SecureValueFormat = "BLANKOUT"

    )

    Begin {

        xRequires -Version 7.0
    }

    Process {

        try {
        
            foreach ($ContentId in $Id) {

                $URI = "/content-management-service/api/contents/$($ContentId)/data?secureValueFormat=$($SecureValueFormat)"

                $Content = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                if ($Content) {

                    Write-Output $Content

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRAContentType
#>

function Get-vRAContentType {
<#
    .SYNOPSIS
    Get a list of available vRA content types
    
    .DESCRIPTION
    Get a list of available vRA content types

    .PARAMETER Id
    The id of the content type

    .PARAMETER Name
    The name of the content type

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAContentType -Id property-group

    .EXAMPLE
    Get-vRAContentType -Name "Property Group"

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (
    
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {

        xRequires -Version 7.0

    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get content type by id
                'ById' {

                    foreach ($ContentTypeId in $Id) {
                
                        $URI = "/content-management-service/api/provider/contenttypes/$($ContentTypeId)"

                        $ContentType = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $ContentType.id
                            Name = $ContentType.name
                            Description = $ContentType.description
                            ClassId = $ContentType.classId
                            ServiceTypeId = $ContentType.serviceTypeId

                        }

                    }

                    break

                }
                # --- Get content type by name
                'ByName' {

                    foreach ($ContentTypeName in $Name) { 

                        $URI = "/content-management-service/api/provider/contenttypes?`$filter=name eq '$($ContentTypeName)'"            

                        $EscapedURI = [uri]::EscapeUriString($URI)

                        $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                        if ($Response.content.Count -eq 0) {

                            throw "Could not find content type with name: $($ContentName)"

                        }

                        $ContentType = $Response.content

                        [PSCustomObject] @{

                            Id = $ContentType.id
                            Name = $ContentType.name
                            Description = $ContentType.description
                            ClassId = $ContentType.classId
                            ServiceTypeId = $ContentType.serviceTypeId

                        }

                    }

                    break

                }
                # --- No parameters passed so return all content types
                'Standard' {

                    $URI = "/content-management-service/api/provider/contenttypes?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($ContentType in $Response.content) {

                        [PSCustomObject] @{

                            Id = $ContentType.id
                            Name = $ContentType.name
                            Description = $ContentType.description
                            ClassId = $ContentType.classId
                            ServiceTypeId = $ContentType.serviceTypeId

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}

<#
    - Function: Get-vRAPackage
#>

function Get-vRAPackage {
<#
    .SYNOPSIS
    Retrieve vRA Packages
    
    .DESCRIPTION
    Retrieve vRA Packages
    
    .PARAMETER Id
    Specify the ID of a Package

    .PARAMETER Name
    Specify the Name of a Package

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAPackage
    
    .EXAMPLE
    Get-vRAPackage -Id "b2d72c5d-775b-400c-8d79-b2483e321bae"

    .EXAMPLE
    Get-vRAPackage -Name "Package01","Package02"
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,         

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    # --- Test for vRA API version
    xRequires -Version 7.0
    
    try {                
        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  {                
                
                foreach ($PackageId in $Id){

                    $URI = "/content-management-service/api/packages/$($PackageId)"

                    # --- Run vRA REST Request
                    $Package = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference    
                    
                    [PSCustomobject]@{

                        Name = $Package.name
                        Id = $Package.id                
                        Description = $Package.description
                        TenantId = $Package.tenantId
                        SubtenantId = $Package.subtenantId
                        Contents = $Package.contents
                        CreatedDate = $Package.createdDate
                        LastUpdated = $Package.lastUpdated
                        version = $Package.version
                    }
                }                              
            
                break
            }

            "ByName"  {                

               foreach ($PackageName in $Name){

                    $URI = "/content-management-service/api/packages?`$filter=name eq '$($PackageName)'"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference
                    
                    if (-not $Response.content){
                    
                        throw "Unable to retrieve Package with Name $($Name)"
                    }                  

                    foreach ($Package in $Response.content){

                        [PSCustomobject]@{

                            Name = $Package.name
                            Id = $Package.id                
                            Description = $Package.description
                            TenantId = $Package.tenantId
                            SubtenantId = $Package.subtenantId
                            Contents = $Package.contents
                            CreatedDate = $Package.createdDate
                            LastUpdated = $Package.lastUpdated
                            version = $Package.version
                        }
                    }
                }  
                
                break
            }

            "Standard"  {

                $URI = "/content-management-service/api/packages?limit=$($Limit)&page=$($Page)&`$orderby=name asc"

                $EscapedURI = [uri]::EscapeUriString($URI)

                $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                foreach ($Package in $Response.content){

                    [PSCustomobject]@{

                        Name = $Package.name
                        Id = $Package.id                
                        Description = $Package.description
                        TenantId = $Package.tenantId
                        SubtenantId = $Package.subtenantId
                        Contents = $Package.contents
                        CreatedDate = $Package.createdDate
                        LastUpdated = $Package.lastUpdated
                        version = $Package.version
                    }
                }

                Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"
                
                break
            }
        }
    }
    catch [Exception]{

        throw
    }
}

<#
    - Function: Get-vRAPackageContent
#>

function Get-vRAPackageContent {
<#
    .SYNOPSIS
    Get content items for a given package
    
    .DESCRIPTION
    Get content items for a given package
    
    .PARAMETER Id
    Specify the ID of a Package

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAPackage
    
    .EXAMPLE
    Get-vRAPackage -Id "b2d72c5d-775b-400c-8d79-b2483e321bae"

    .EXAMPLE
    Get-vRAPackage -Name "Package01","Package02"
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100


    )

    # --- Test for vRA API version
    xRequires -Version 7.0
    
    try {                
                         
        foreach ($PackageId in $Id){

            $URI = "/content-management-service/api/packages/$($PackageId)/contents?limit=$($Limit)&page=$($Page)"

            # --- Run vRA REST Request
            $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

            if ($Response.content.Count -eq 0) {

                Write-Verbose -Message "The specified package has no content"
                return

            }
            
            foreach ($Content in $Response.Content) {

                [PSCustomObject] @{

                    Id = $Content.id
                    ContentId = $Content.contentId
                    Name = $Content.name
                    Description = $Content.description
                    ContentTypeId = $Content.contentTypeId
                    MimeType = $Content.mimeType
                    TenantId = $Content.tenantId
                    SubtenantId = $Content.subtenantId
                    Dependencies = $Content.dependencies
                    CreatedDate = $Content.createdDate
                    LastUpdated = $Content.lastUpdated
                    Version = $Content.version

                }

            }

             Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

        }                             
            
    }
    catch [Exception]{

        throw
    }
}

<#
    - Function: Import-vRAContentData
#>

function Import-vRAContentData {
<#
    .SYNOPSIS
    Import a yaml file associated with vRA content

    .DESCRIPTION
    Import a yaml file associated with vRA content

    .PARAMETER ContentType
    The Content Type of the imported item such as composite-blueprint or property-group

    .PARAMETER Path
    The path to file to import

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    .EXAMPLE
    Import-vRAContentData -Path ./CentOS.yaml -ContentType composite-blueprint

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.String')]

    Param (

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("form-definition","property-group", "property-definition", "composite-blueprint", "component-profile-value", "software-component", "o11n-package-type", "reservation-type-category-type", "reservation-type-type", "xaas-bundle-content", "xaas-blueprint", "xaas-resource-action", "xaas-resource-type", "xaas-resource-mapping")]
        [String]$ContentType,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Path
    )

    Begin {

        xRequires -Version 7.0

        $Headers = @{

            "Authorization" = "Bearer $($Global:vRAConnection.Token)";
            "Accept" = "Application/json"
            "Content-Type" = "text/yaml"
        }
    }

    Process {

        try {

            if ($PSCmdlet.ShouldProcess($Path)){

                $Body = Get-Content -Raw -Path $Path

                #vRA API - The string "import" isn't actually processed by vRA. The content id is processed via the body automatically. Validated this for new and exiting content items.
                $URI = "/content-management-service/api/contents/$($ContentType)/import/data"

                Invoke-vRARestMethod -Method POST -URI $URI -Headers $Headers -Verbose:$VerbosePreference -Body $Body

            }

        }
        catch [Exception]{

            throw

        }

    }

    End {

    }

}


<#
    - Function: Import-vRAPackage
#>

function Import-vRAPackage {
<#
    .SYNOPSIS
    Imports a vRA Content Package    

    .DESCRIPTION
    Imports a vRA Content Package  

    .PARAMETER File
    The content package file

    .PARAMETER DontValidatePackage
    Skip Package Validation. Not recommended by the API documentation

    .INPUTS
    System.String
    System.Switch

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Import-vRAPackage -File C:\Packages\Package100.zip

    .EXAMPLE
    Get-ChildItem -Path C:\Packages\Package100.zip| Import-vRAPackage -Confirm:$false

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$File,

        [Parameter(Mandatory=$false)]
        [Switch]$DontValidatePackage

    )

    Begin {

        xRequires -Version 7.0

        # --- Set Set Line Feed
        $LF = "`r`n"
   
    }

    Process {

        foreach ($FilePath in $File){

            try {
                # --- Validate the Content Package
                if (!$PSBoundParameters.ContainsKey('DontValidatePackage')){

                    $Test = Test-vRAPackage -File $FilePath

                    switch ($Test.operationStatus) {

                        'FAILED' {

                            $Test.operationResults
                            throw "Content Package failed validation test. You should remedy the issue with the Content Package before importing - A failed import may potentially leave the system in an inconsistent state"
                        }
                        'WARNING' {

                            $Test.operationResults
                            Write-Warning "Content Package $FilePath contains a warning. Please check the Operation Results for details"
                        }
                        'SUCCESS' {

                            Write-Verbose "Content Package $FileInfo has been successfully validated"
                        }
                        Default {

                            throw "Unable to validate Content Package $FilePath"
                        }
                    }
                }
                else {

                    Write-Verbose "Skipping Content Package validation"
                }

                # --- Resolve the file path
                $FileInfo = [System.IO.FileInfo](Resolve-Path $FilePath).Path

                # --- Create the multi-part form
                $Boundary = [guid]::NewGuid().ToString()
                $FileBin = [System.IO.File]::ReadAllBytes($FileInfo.FullName)
                $Encoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")
                $EncodedFile = $Encoding.GetString($FileBin)

                $Form = (
                    "--$($Boundary)",
                    "Content-Disposition: form-data; name=`"file`"; filename=`"$($FileInfo.Name)`"",
                    "Content-Type:application/octet-stream$($LF)",
                    $EncodedFile,
                    "--$($Boundary)--$($LF)"
                ) -join $LF

                $URI = "/content-management-service/api/packages/"

                # --- Set custom headers for the request
                $Headers = @{
                
                    "Authorization" = "Bearer $($Global:vRAConnection.Token)";
                    "Accept" = "Application/json"
                    "Accept-Encoding" = "gzip,deflate,sdch";
                    "Content-Type" = "multipart/form-data; boundary=$($Boundary)"
                }

                if ($PSCmdlet.ShouldProcess($FileInfo.FullName)){

                    # --- Run vRA REST request
                    Invoke-vRARestMethod -Method POST -Uri $URI -Body $Form -Headers $Headers -Verbose:$VerbosePreference

                }

            }
            catch [Exception]{

                throw
            }
        }
    }

    End {

    }
}

<#
    - Function: New-vRAPackage
#>

function New-vRAPackage {
<#
    .SYNOPSIS
    Create a vRA Content Package
    
    .DESCRIPTION
    Create a vRA Package
    
    .PARAMETER Name
    Content Package Name
    
    .PARAMETER Description
    Content Package Description

    .PARAMETER Id
    A list of content Ids to include in the Package

    .PARAMETER ContentName
    A list of content names to include in the Package

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRAPackage -Name Package01 -Description "This is Content Package 01" -Id "58e10956-172a-48f6-9373-932f99eab37a","0c74b085-dbc1-4fea-9cbf-a1601f668a1f"

    .EXAMPLE
    New-vRAPackage -Name Package01 -Description "This is Content Package 01" -ContentName "Blueprint01","Blueprint02"
    
    .EXAMPLE
    Get-vRAContent | New-vRAPackage -Name Package01 - Description "This is Content Package 01"

    .EXAMPLE
    $JSON = @"
    {
        "name":"Package01",
        "description":"This is Content Package 01",
        "contents":[ "58e10956-172a-48f6-9373-932f99eab37a","0c74b085-dbc1-4fea-9cbf-a1601f668a1f" ]
    }
    "@
    $JSON | New-vRAPackage
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="ById")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="ById")]
        [parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$true,ParameterSetName="ById", ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("ContentId")]
        [String[]]$Id,

        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$ContentName,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
        [ValidateNotNullOrEmpty()]
        [String]$JSON

    )

    begin {

        xRequires -Version 7.0

        $Object = [PSCustomObject] @{

            name = $Name
            description = $Description
            contents = @()
        }

    }
    
    process {

        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  { 

                foreach ($CId in $Id) {

                    Write-Verbose -Message "Adding content with id $($CId) to package"
                    $Object.contents += $CId

                }

                break
            }

            "ByName"  {

                foreach ($CName in $ContentName) {

                    Write-Verbose -Message "Adding content with id $($CName) to package"
                    $Id = (Get-vRAContent -Name $CName).Id
                    $Object.contents += $Id

                }
                
                break
            }

            "JSON"  {

                $Data = ($JSON | ConvertFrom-Json)
        
                $Body = $JSON
                $Name = $Data.name  
                
                break
            }
        }
    }
    end {

        # --- Convert PSCustomObject to a string
        $Body = $Object | ConvertTo-Json                    

        if ($PSCmdlet.ShouldProcess($Name)){

            $URI = "/content-management-service/api/packages"

            # --- Run vRA REST Request
            Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

            # --- Output the Successful Result
            Get-vRAPackage -Name $Name -Verbose:$VerbosePreference
        }   
    }
}

<#
    - Function: Remove-vRAPackage
#>

function Remove-vRAPackage {
<#
    .SYNOPSIS
    Remove a vRA Content Package
    
    .DESCRIPTION
    Remove a vRA Content Package

    .PARAMETER Id
    Content Package Id

    .PARAMETER Name
    Content Package Name

    .INPUTS
    System.String.

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRAPackage -Id "f8e0d99e-c567-4031-99cb-d8410c841ed7"

    .EXAMPLE
    Remove-vRAPackage -Name "Package01","Package02"
    
    .EXAMPLE
    Get-vRAPackage -Name "Package01","Package02" | Remove-vRAPackage -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="Id")]

    Param (

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="Id")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [parameter(Mandatory=$true,ParameterSetName="Name")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name
    )    

    begin {

        xRequires -Version 7.0

    }
    
    process {    

        switch ($PsCmdlet.ParameterSetName) 
        { 
            "Id"  {

                foreach ($PackageId in $Id){
                
                    try {
                        if ($PSCmdlet.ShouldProcess($PackageId)){

                            $URI = "/content-management-service/api/packages/$($id)"  

                            # --- Run vRA REST Request
                            Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-NUll

                        }
                    }
                    catch [Exception]{

                        throw
                    } 
                }                
            
                break
            }

            "Name"  {

                foreach ($PackageName in $Name){
                
                    try {
                        if ($PSCmdlet.ShouldProcess($PackageName)){

                            # --- Find the Content Package
                            $Package = Get-vRAPackage -Name $PackageName
                            $Id = $Package.ID

                            $URI = "/content-management-service/api/packages/$($Id)"  

                            # --- Run vRA REST Request
                            Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
                        }
                    }
                    catch [Exception]{

                        throw
                    } 
                }
                
                break
            } 
        }             
    }
    end {
        
    }
}

<#
    - Function: Test-vRAPackage
#>

function Test-vRAPackage {
<#
    .SYNOPSIS
    Validates a vRA Content Package    

    .DESCRIPTION
    Validates a vRA Content Package  

    .PARAMETER File
    The content package file

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Test-vRAPackage -File C:\Packages\Package100.zip

    .EXAMPLE
    Get-ChildItem -Path C:\Packages\Package100.zip| Test-vRAPackage

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$File

    )

    begin {

        xRequires -Version 7.0

        # --- Set Set Line Feed
        $LF = "`r`n"
   
    }

    process {

        foreach ($FilePath in $File){

            try {

                # --- Resolve the file path
                $FileInfo = [System.IO.FileInfo](Resolve-Path $FilePath).Path

                # --- Create the multi-part form
                $Boundary = [guid]::NewGuid().ToString()
                $FileBin = [System.IO.File]::ReadAllBytes($FileInfo.FullName)
                $Encoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")
                $EncodedFile = $Encoding.GetString($FileBin)

                $Form = (
                    "--$($Boundary)",
                    "Content-Disposition: form-data; name=`"file`"; filename=`"$($FileInfo.Name)`"",
                    "Content-Type:application/octet-stream$($LF)",
                    $EncodedFile,
                    "--$($Boundary)--$($LF)"
                ) -join $LF

                $URI = "/content-management-service/api/packages/validate"

                # --- Set custom headers for the request
                $Headers = @{
                
                    "Authorization" = "Bearer $($Global:vRAConnection.Token)";
                    "Accept" = "Application/json"
                    "Accept-Encoding" = "gzip,deflate,sdch";
                    "Content-Type" = "multipart/form-data; boundary=$($Boundary)"
                }

                if ($PSCmdlet.ShouldProcess($FileInfo.FullName)){

                    Invoke-vRARestMethod -Method POST -Uri $URI -Body $Form -Headers $Headers -Verbose:$VerbosePreference

                }

            }
            catch [Exception]{

                throw

            }
        }
    }

    end {

    }
}

<#
    - Function: Get-vRAExternalNetworkProfile
#>

function Get-vRAExternalNetworkProfile {
<#
    .SYNOPSIS
    Get vRA external network profiles
    
    .DESCRIPTION
    Get vRA external network profiles

    .PARAMETER Id
    The id of the external network profile
    
    .PARAMETER Name
    The name of the external network profile

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. By default this is 1.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAExternalNetworkProfile -Id 597ff2c1-a35f-4a81-bfd3-ca014

    .EXAMPLE
    Get-vRAExternalNetworkProfile -Name NetworkProfile01

    .EXAMPLE
    Get-vRAExternalNetworkProfile

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,    
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,
    
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1
       
    )    

    xRequires -Version 7.1

    try {

        switch ($PsCmdlet.ParameterSetName) {

            'ById' { 

                foreach ($NetworkProfileId in $Id) {

                    $URI = "/iaas-proxy-provider/api/network/profiles/$($NetworkProfileId)"
            
                    $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                    if ($NetworkProfile) {

                        if ($NetworkProfile.profileType -ne "EXTERNAL") {

                            throw "Network profile type is not EXTERAL"

                        }

                        [PSCustomObject] @{

                            Id = $NetworkProfile.id
                            Name = $NetworkProfile.name
                            Description = $NetworkProfile.description
                            CreatedDate = $NetworkProfile.createdDate
                            LastModifiedDate = $NetworkProfile.lastModifiedDate
                            IsHidden = $NetworkProfile.ishidden
                            DefinedRanges = $NetworkProfile.definedRanges
                            DefinedAddresses = $NetworkProfile.definedAddresses
                            ReclaimedAddresses = $NetworkProfile.reclaimedAddresses
                            IPAMEndpointId = $NetworkProfile.IPAMEndpointId
                            IPAMEndpointName = $NetworkProfile.IPAMEndpointName
                            AddressSpaceExternalId = $NetworkProfile.addressspaceExternalId
                            ProfileType = $NetworkProfile.profileType
                            SubnetMask = $NetworkProfile.subnetMask
                            GatewayAddress = $NetworkProfile.gatewayAddress
                            PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                            SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                            DnsSuffix = $NetworkProfile.DnsSuffix
                            DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                            PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                            SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress

                        }

                    }
                    else {

                        throw "Could not find external network profile with Id $($NetworkProfileId)"

                    }

                }

                break

            }

            'ByName' {

                foreach ($NetworkProfileName in $Name) {

                    <#
                    
                        Filtering by name will only return a subset of information, just 
                        like /api/network/profiles. See the following from the API documentation:

                        This API will only return some basic information about each network profile. 
                        To get more details of a specific network profile use the /api/network/profiles/{id} API. 

                    #>
                                        
                    # --- Workaround to get the ID of the network profile            
            
                    $URI = "/iaas-proxy-provider/api/network/profiles?`$filter=name eq '$($NetworkProfileName)' and profileType eq EXTERNAL"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    if ($Response.content.Count -eq 0) {

                        throw "Could not find external network profile with name $($NetworkProfileName)"

                    }

                    $Id = $Response.content.id

                    # --- Now we retrieve the network profile by id to see all information
                    $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"
            
                    $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                    [PSCustomObject] @{

                        Id = $NetworkProfile.id
                        Name = $NetworkProfile.name
                        Description = $NetworkProfile.description
                        CreatedDate = $NetworkProfile.createdDate
                        LastModifiedDate = $NetworkProfile.lastModifiedDate
                        IsHidden = $NetworkProfile.ishidden
                        DefinedRanges = $NetworkProfile.definedRanges
                        DefinedAddresses = $NetworkProfile.definedAddresses
                        ReclaimedAddresses = $NetworkProfile.reclaimedAddresses
                        IPAMEndpointId = $NetworkProfile.IPAMEndpointId
                        IPAMEndpointName = $NetworkProfile.IPAMEndpointName
                        AddressSpaceExternalId = $NetworkProfile.addressspaceExternalId
                        ProfileType = $NetworkProfile.profileType
                        SubnetMask = $NetworkProfile.subnetMask
                        GatewayAddress = $NetworkProfile.gatewayAddress
                        PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                        SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                        DnsSuffix = $NetworkProfile.DnsSuffix
                        DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                        PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                        SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress

                    }
                          
                }
                
                break                                          
        
            }

            'Standard' {

                $URI = "/iaas-proxy-provider/api/network/profiles?limit=$($Limit)&page=$($Page)&`$filter=profileType eq EXTERNAL"

                $EscapedURI = [uri]::EscapeUriString($URI)

                $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$verbosePreference

                foreach ($NetworkProfile in $Response.content) {

                    [PSCustomObject] @{

                        Id = $NetworkProfile.id
                        Name = $NetworkProfile.name
                        Description = $NetworkProfile.description
                        CreatedDate = $NetworkProfile.createdDate
                        LastModifiedDate = $NetworkProfile.lastModifiedDate
                        IsHidden = $NetworkProfile.ishidden
                        DefinedRanges = $NetworkProfile.definedRanges
                        DefinedAddresses = $NetworkProfile.definedAddresses
                        ReclaimedAddresses = $NetworkProfile.reclaimedAddresses
                        IPAMEndpointId = $NetworkProfile.IPAMEndpointId
                        IPAMEndpointName = $NetworkProfile.IPAMEndpointName
                        AddressSpaceExternalId = $NetworkProfile.addressspaceExternalId
                        ProfileType = $NetworkProfile.profileType
                        SubnetMask = $NetworkProfile.subnetMask
                        GatewayAddress = $NetworkProfile.gatewayAddress
                        PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                        SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                        DnsSuffix = $NetworkProfile.DnsSuffix
                        DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                        PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                        SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress

                    }

                }

                Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                break

            }

        }
           
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRANATNetworkProfile
#>

function Get-vRANATNetworkProfile {
<#
    .SYNOPSIS
    Get vRA NAT network profiles
    
    .DESCRIPTION
    Get vRA NAT network profiles

    .PARAMETER Id
    The id of the NAT network profile
    
    .PARAMETER Name
    The name of the NAT network profile

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. By default this is 1.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRANATNetworkProfile -Id 597ff2c1-a35f-4a81-bfd3-ca014

    .EXAMPLE
    Get-vRANATNetworkProfile -Name NetworkProfile01

    .EXAMPLE
    Get-vRANATNetworkProfile

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,    
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,
    
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1
       
    )

    xRequires -Version 7.1

    try {

        switch ($PsCmdlet.ParameterSetName) {

            'ById' { 

                foreach ($NetworkProfileId in $Id) {

                    $URI = "/iaas-proxy-provider/api/network/profiles/$($NetworkProfileId)"
            
                    $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                    if ($NetworkProfile) {

                        if ($NetworkProfile.profileType -ne "NAT") {

                            throw "Network profile type is not NAT"

                        }

                        [PSCustomObject] @{

                            Id = $NetworkProfile.id
                            Name = $NetworkProfile.name
                            Description = $NetworkProfile.description
                            CreatedDate = $NetworkProfile.createdDate
                            LastModifiedDate = $NetworkProfile.lastModifiedDate
                            IsHidden = $NetworkProfile.ishidden
                            DefinedRanges = $NetworkProfile.definedRanges
                            DefinedAddresses = $NetworkProfile.definedAddresses
                            ReclaimedAddresses = $NetworkProfile.reclaimedAddresses
                            IPAMEndpointId = $NetworkProfile.IPAMEndpointId
                            IPAMEndpointName = $NetworkProfile.IPAMEndpointName
                            AddressSpaceExternalId = $NetworkProfile.addressspaceExternalId
                            ProfileType = $NetworkProfile.profileType
                            NatType = $NetworkProfile.natType
                            SubnetMask = $NetworkProfile.subnetMask
                            GatewayAddress = $NetworkProfile.gatewayAddress
                            PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                            SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                            DnsSuffix = $NetworkProfile.DnsSuffix
                            DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                            PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                            SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress
                            ExternalNetworkProfileId = $NetworkProfile.externalNetworkProfileId
                            ExternalNetworkProfileName = $NetworkProfile.externalNetworkProfileName
                            DhcpConfig = $NetworkProfile.dhcpConfig

                        }

                    }
                    else {

                        throw "Could not find NAT network profile with Id $($NetworkProfileId)"

                    }

                }

                break

            }

            'ByName' {

                foreach ($NetworkProfileName in $Name) {

                    <#
                    
                        Filtering by name will only return a subset of information, just 
                        like /api/network/profiles. See the following from the API documentation:

                        This API will only return some basic information about each network profile. 
                        To get more details of a specific network profile use the /api/network/profiles/{id} API. 

                    #>
                                        
                    # --- Workaround to get the ID of the network profile            
            
                    $URI = "/iaas-proxy-provider/api/network/profiles?`$filter=name eq '$($NetworkProfileName)' and profileType eq NAT"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    if ($Response.content.Count -eq 0) {

                        throw "Could not find NAT network profile with name $($NetworkProfileName)"

                    }

                    $Id = $Response.content.id

                    # --- Now we retrieve the network profile by id to see all information
                    $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"
            
                    $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                    [PSCustomObject] @{

                        Id = $NetworkProfile.id
                        Name = $NetworkProfile.name
                        Description = $NetworkProfile.description
                        CreatedDate = $NetworkProfile.createdDate
                        LastModifiedDate = $NetworkProfile.lastModifiedDate
                        IsHidden = $NetworkProfile.ishidden
                        DefinedRanges = $NetworkProfile.definedRanges
                        DefinedAddresses = $NetworkProfile.definedAddresses
                        ReclaimedAddresses = $NetworkProfile.reclaimedAddresses
                        IPAMEndpointId = $NetworkProfile.IPAMEndpointId
                        IPAMEndpointName = $NetworkProfile.IPAMEndpointName
                        AddressSpaceExternalId = $NetworkProfile.addressspaceExternalId
                        ProfileType = $NetworkProfile.profileType
                        NatType = $NetworkProfile.natType
                        SubnetMask = $NetworkProfile.subnetMask
                        GatewayAddress = $NetworkProfile.gatewayAddress
                        PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                        SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                        DnsSuffix = $NetworkProfile.DnsSuffix
                        DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                        PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                        SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress
                        ExternalNetworkProfileId = $NetworkProfile.externalNetworkProfileId
                        ExternalNetworkProfileName = $NetworkProfile.externalNetworkProfileName
                        DhcpConfig = $NetworkProfile.dhcpConfig

                    }
                          
                }
                
                break                                          
        
            }

            'Standard' {

                $URI = "/iaas-proxy-provider/api/network/profiles?limit=$($Limit)&page=$($Page)&`$filter=profileType eq NAT"

                $EscapedURI = [uri]::EscapeUriString($URI)

                $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$verbosePreference

                foreach ($NetworkProfile in $Response.content) {

                    [PSCustomObject] @{

                        Id = $NetworkProfile.id
                        Name = $NetworkProfile.name
                        Description = $NetworkProfile.description
                        CreatedDate = $NetworkProfile.createdDate
                        LastModifiedDate = $NetworkProfile.lastModifiedDate
                        IsHidden = $NetworkProfile.ishidden
                        DefinedRanges = $NetworkProfile.definedRanges
                        DefinedAddresses = $NetworkProfile.definedAddresses
                        ReclaimedAddresses = $NetworkProfile.reclaimedAddresses
                        IPAMEndpointId = $NetworkProfile.IPAMEndpointId
                        IPAMEndpointName = $NetworkProfile.IPAMEndpointName
                        AddressSpaceExternalId = $NetworkProfile.addressspaceExternalId
                        ProfileType = $NetworkProfile.profileType
                        NatType = $NetworkProfile.natType
                        SubnetMask = $NetworkProfile.subnetMask
                        GatewayAddress = $NetworkProfile.gatewayAddress
                        PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                        SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                        DnsSuffix = $NetworkProfile.DnsSuffix
                        DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                        PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                        SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress
                        ExternalNetworkProfileId = $NetworkProfile.externalNetworkProfileId
                        ExternalNetworkProfileName = $NetworkProfile.externalNetworkProfileName
                        DhcpConfig = $NetworkProfile.dhcpConfig

                    }

                }

                Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                break

            }

        }
           
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRANetworkProfileIPAddressList
#>

function Get-vRANetworkProfileIPAddressList {
<#
    .SYNOPSIS
    Get a list of IP addresses available within the network profile    

    .DESCRIPTION
    Get a list of IP addresses available within the network profile    

    .PARAMETER NetworkProfileId
    The id of the network profile

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. By default this is 1.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAExternalNetworkProfile -Name EXT-01 | Get-vRANetworkProfileIPAddressList

    .EXAMPLE
     Get-vRAExternalNetworkProfile -Name EXT-01 | Get-vRANetworkProfileIPAddressList -Limit 10 -Page 1

#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Alias("Id")]
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$NetworkProfileId,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1
       
    )    

    xRequires -Version 7.1

    try {

        $URI = "/iaas-proxy-provider/api/network/profiles/addresses/$($NetworkProfileId)?limit=$($limit)&page=$($page)"

        $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$verbosePreference

        foreach ($NetworkProfileIPAddress in $Response.content) {

            [PSCustomObject] @{

                Id = $NetworkProfileIPAddress.id
                IPv4Address = $NetworkProfileIPAddress.ipv4Address
                IPSortValue = $NetworkProfileIPAddress.ipSortValue
                State = $NetworkProfileIPAddress.state
                StateValue = $NetworkProfileIPAddress.stateValue
                CreatedDate = $NetworkProfileIPAddress.createdDate
                LastModifiedDate = $NetworkProfileIPAddress.lastModifiedDate

            }

        }

        Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"
    
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRANetworkProfileIPRangeSummary
#>

function Get-vRANetworkProfileIPRangeSummary {
<#
    .SYNOPSIS
    Returns a list of range summaries within the network profile.

    .DESCRIPTION
    Returns a list of range summaries within the network profile.

    .PARAMETER NetworkProfileId
    The id of the network profile

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. By default this is 1.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAExternalNetworkProfile -Name EXT-01 | Get-vRANetworkProfileIPRangeSummary

    .EXAMPLE
     Get-vRAExternalNetworkProfile -Name EXT-01 | Get-vRANetworkProfileIPRangeSummary -Limit 10 -Page 1

#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Alias("Id")]
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$NetworkProfileId,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1
       
    )    

    xRequires -Version 7.1

    try {

        $URI = "/iaas-proxy-provider/api/network/profiles/range-summaries/$($NetworkProfileId)?limit=$($limit)&page=$($page)"

        $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$verbosePreference

        foreach ($NetworkProfileRange in $Response.content) {

            [PSCustomObject] @{

                Id = $NetworkProfileRange.id
                Name = $NetworkProfileRange.name
                Description = $NetworkProfileRange.description
                BeginIPv4Address = $NetworkProfileRange.beginIPv4Address
                EndIPv4Address = $NetworkProfileRange.endIPv4Address
                State = $NetworkProfileRange.state
                CreatedDate = $NetworkProfileRange.createdDate
                LastModifiedDate = $NetworkProfileRange.lastModifiedDate
                TotalAddresses = $NetworkProfileRange.totalAddresses
                AllocatedAddresses = $NetworkProfileRange.allocatedAddresses
                UnallocatedAddresses = $NetworkProfileRange.unallocatedAddresses
                DestroyedAddresses = $NetworkProfileRange.destroyedAddresses
                ExpiredAddresses = $NetworkProfileRange.expiredAddresses

            }

        }

        Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"
    
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRARoutedNetworkProfile
#>

function Get-vRARoutedNetworkProfile {
<#
    .SYNOPSIS
    Get vRA routed network profiles
    
    .DESCRIPTION
    Get vRA routed network profile

    .PARAMETER Id
    The id of the routed network profile
    
    .PARAMETER Name
    The name of the routed network profile

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. By default this is 1.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRARoutedNetworkProfile -Id 597ff2c1-a35f-4a81-bfd3-ca014

    .EXAMPLE
    Get-vRARoutedNetworkProfile -Name NetworkProfile01

    .EXAMPLE
    Get-vRARoutedNetworkProfile

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,    
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,
    
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1
       
    )

    xRequires -Version 7.1  

    try {

        switch ($PsCmdlet.ParameterSetName) {

            'ById' { 

                foreach ($NetworkProfileId in $Id) {

                    $URI = "/iaas-proxy-provider/api/network/profiles/$($NetworkProfileId)"
            
                    $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                    if ($NetworkProfile) {

                        if ($NetworkProfile.profileType -ne "ROUTED") {

                            throw "Network profile type is not ROUTED"

                        }

                        [PSCustomObject] @{

                            Id = $NetworkProfile.id
                            Name = $NetworkProfile.name
                            Description = $NetworkProfile.description
                            CreatedDate = $NetworkProfile.createdDate
                            LastModifiedDate = $NetworkProfile.lastModifiedDate
                            IsHidden = $NetworkProfile.ishidden
                            DefinedRanges = $NetworkProfile.definedRanges
                            DefinedAddresses = $NetworkProfile.definedAddresses
                            ReclaimedAddresses = $NetworkProfile.reclaimedAddresses
                            IPAMEndpointId = $NetworkProfile.IPAMEndpointId
                            IPAMEndpointName = $NetworkProfile.IPAMEndpointName
                            AddressSpaceExternalId = $NetworkProfile.addressspaceExternalId
                            ProfileType = $NetworkProfile.profileType
                            RangeSubnetMask = $NetworkProfile.rangeSubnetMask
                            SubnetMask = $NetworkProfile.subnetMask
                            GatewayAddress = $NetworkProfile.gatewayAddress
                            PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                            SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                            DnsSuffix = $NetworkProfile.DnsSuffix
                            DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                            PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                            SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress
                            ExternalNetworkProfileId = $NetworkProfile.externalNetworkProfileId
                            ExternalNetworkProfileName = $NetworkProfile.externalNetworkProfileName
                            BaseIP = $NetworkProfile.baseIP

                        }

                    }
                    else {

                        throw "Could not find Routed network profile with Id $($NetworkProfileId)"

                    }

                }

                break

            }

            'ByName' {

                foreach ($NetworkProfileName in $Name) {

                    <#
                    
                        Filtering by name will only return a subset of information, just 
                        like /api/network/profiles. See the following from the API documentation:

                        This API will only return some basic information about each network profile. 
                        To get more details of a specific network profile use the /api/network/profiles/{id} API. 

                    #>
                                        
                    # --- Workaround to get the ID of the network profile            
            
                    $URI = "/iaas-proxy-provider/api/network/profiles?`$filter=name eq '$($NetworkProfileName)' and profileType eq ROUTED"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    if ($Response.content.Count -eq 0) {

                        throw "Could not find Routed network profile with name $($NetworkProfileName)"

                    }

                    $Id = $Response.content.id

                    # --- Now we retrieve the network profile by id to see all information
                    $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"
            
                    $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                    [PSCustomObject] @{

                        Id = $NetworkProfile.id
                        Name = $NetworkProfile.name
                        Description = $NetworkProfile.description
                        CreatedDate = $NetworkProfile.createdDate
                        LastModifiedDate = $NetworkProfile.lastModifiedDate
                        IsHidden = $NetworkProfile.ishidden
                        DefinedRanges = $NetworkProfile.definedRanges
                        ProfileType = $NetworkProfile.profileType
                        RangeSubnetMask = $NetworkProfile.rangeSubnetMask
                        SubnetMask = $NetworkProfile.subnetMask
                        GatewayAddress = $NetworkProfile.gatewayAddress
                        PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                        SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                        DnsSuffix = $NetworkProfile.DnsSuffix
                        DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                        PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                        SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress
                        ExternalNetworkProfileId = $NetworkProfile.externalNetworkProfileId
                        ExternalNetworkProfileName = $NetworkProfile.externalNetworkProfileName
                        BaseIP = $NetworkProfile.baseIP

                    }
                          
                }
                
                break                                          
        
            }

            'Standard' {

                $URI = "/iaas-proxy-provider/api/network/profiles?limit=$($Limit)&page=$($Page)&`$filter=profileType eq ROUTED"

                $EscapedURI = [uri]::EscapeUriString($URI)

                $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$verbosePreference

                foreach ($NetworkProfile in $Response.content) {

                    [PSCustomObject] @{

                        Id = $NetworkProfile.id
                        Name = $NetworkProfile.name
                        Description = $NetworkProfile.description
                        CreatedDate = $NetworkProfile.createdDate
                        LastModifiedDate = $NetworkProfile.lastModifiedDate
                        IsHidden = $NetworkProfile.ishidden
                        DefinedRanges = $NetworkProfile.definedRanges
                        ProfileType = $NetworkProfile.profileType
                        RangeSubnetMask = $NetworkProfile.rangeSubnetMask
                        SubnetMask = $NetworkProfile.subnetMask
                        GatewayAddress = $NetworkProfile.gatewayAddress
                        PrimaryDnsAddress = $NetworkProfile.primaryDnsAddress
                        SecondaryDnsAddress = $NetworkProfile.secondaryDnsAddress
                        DnsSuffix = $NetworkProfile.DnsSuffix
                        DnsSearchSuffix = $NetworkProfile.DnsSearchSuffix
                        PrimaryWinsAddress = $NetworkProfile.PrimaryWinsAddress
                        SecondaryWinsAddress = $NetworkProfile.SecondaryWinsAddress
                        ExternalNetworkProfileId = $NetworkProfile.externalNetworkProfileId
                        ExternalNetworkProfileName = $NetworkProfile.externalNetworkProfileName
                        BaseIP = $NetworkProfile.baseIP

                    }

                }

                Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                break

            }

        }
           
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRASourceMachine
#>

function Get-vRASourceMachine {
<#
    .SYNOPSIS
    Return a list of source machines
    
    .DESCRIPTION
    Return a list of source machines. A source machine represents an entity that is visible to the endpoint.

    .PARAMETER Id
    The id of the Source Machine
    
    .PARAMETER Name
    The name of the Source Macine

    .PARAMETER ManagedOnly
    Only return machines that are managed

    .PARAMETER TemplatesOnly
    Only return machines that are marked as templates

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. By default this is 1.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRASourceMachine -Id 597ff2c1-a35f-4a81-bfd3-ca014

    .EXAMPLE
    Get-vRASourceMachine -Name vra-template-01

    .EXAMPLE
    Get-vRASourceMachine

    .EXAMPLE
    Get-vRASourceMachine -Template

    .EXAMPLE
    Get-vRASourceMachine -Managed

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,
        
        [Parameter(Mandatory=$true,ParameterSetName="ByName")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Name,              

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Switch]$ManagedOnly,    

        [Parameter(Mandatory=$false,ParameterSetName="Standard-Template")]
        [ValidateNotNullOrEmpty()]
        [Switch]$TemplatesOnly,  

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [Parameter(Mandatory=$false,ParameterSetName="Standard-Template")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,
    
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [Parameter(Mandatory=$false,ParameterSetName="Standard-Template")]            
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1
       
    )    

    Begin {

        xRequires -Version 7.1
        $PlatformTypeId = "Infrastructure.CatalogItem.Machine.Virtual.vSphere"

        function intGetSourceMachineById($I, $P) {
            <#
            .SYNOPSIS
            Helper function to retrieve source machine by id
            .PARAMETER I
            The id of the source machine
            .PARAMETER P
            The PlatformTypeId
            #>
            $URI = "/iaas-proxy-provider/api/source-machines/$($I)?platformTypeId=$($P)"
            Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference
        }

        function intProcessStandardOutput([PSCustomObject[]]$Response){
            <#
            .SYNOPSIS
            Helper function to process response records from the api endpoint
            .PARAMETER Response
            An array of PSCusomObject Responses
            #>
            foreach ($Record in $Response.content) {

                # --- GET by id returns more information
                $SourceMachine = intGetSourceMachineById $Record.id $PlatformTypeId

                [PSCustomObject] @{

                    Id = $SourceMachine.id
                    Name = $SourceMachine.name
                    Description = $SourceMachine.description
                    ReservationName = $SourceMachine.reservationName
                    HostName = $SourceMachine.hostName
                    ExternalId = $SourceMachine.externalId
                    Status = $SourceMachine.status
                    EndpointName = $SourceMachine.endpointName
                    Region = $SourceMachine.region
                    ParentTemplate = $SourceMachine.parentTemplate
                    CPU = $SourceMachine.cpu
                    MemoryMB = $SourceMachine.memoryMB
                    StorageGB = $SourceMachine.storageGB
                    IsTemplate = $SourceMachine.isTemplate
                    GuestOsFamily = $SourceMachine.guestOSFamily
                    InterfaceType = $SourceMachine.interfaceType
                    Disks = $SourceMachine.disks
                    Properties = $SourceMachine.properties
                }
            }
        }        
    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                'ById' { 

                    foreach ($SourceMachineId in $Id) {

                        $SourceMachine = intGetSourceMachineById $SourceMachineId $PlatformTypeId

                        [PSCustomObject] @{

                            Id = $SourceMachine.id
                            Name = $SourceMachine.name
                            Description = $SourceMachine.description
                            ReservationName = $SourceMachine.reservationName
                            HostName = $SourceMachine.hostName
                            ExternalId = $SourceMachine.externalId
                            Status = $SourceMachine.status
                            EndpointName = $SourceMachine.endpointName
                            Region = $SourceMachine.region
                            ParentTemplate = $SourceMachine.parentTemplate
                            CPU = $SourceMachine.cpu
                            MemoryMB = $SourceMachine.memoryMB
                            StorageGB = $SourceMachine.storageGB
                            IsTemplate = $SourceMachine.isTemplate
                            GuestOsFamily = $SourceMachine.guestOSFamily
                            InterfaceType = $SourceMachine.interfaceType
                            Disks = $SourceMachine.disks
                            Properties = $SourceMachine.properties
                        }
                    }

                    break
                }

                'ByName' {

                    foreach ($SourceMachineName in $Name) {

                        $URI = "/iaas-proxy-provider/api/source-machines/?actionId=FullClone&platformTypeId=Infrastructure.CatalogItem.Machine.Virtual.vSphere&`$filter=name eq '$($SourceMachineName)'"
                        $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$verbosePreference
                        
                        if ($Response.content.Count -eq 0) {
                            throw "Resource not found with name $($SourceMachineNamae)"
                        }

                        $Id = $Response.content[0].id

                        $SourceMachine = intGetSourceMachineById $Id $PlatformTypeId

                        [PSCustomObject] @{

                            Id = $SourceMachine.id
                            Name = $SourceMachine.name
                            Description = $SourceMachine.description
                            ReservationName = $SourceMachine.reservationName
                            HostName = $SourceMachine.hostName
                            ExternalId = $SourceMachine.externalId
                            Status = $SourceMachine.status
                            EndpointName = $SourceMachine.endpointName
                            Region = $SourceMachine.region
                            ParentTemplate = $SourceMachine.parentTemplate
                            CPU = $SourceMachine.cpu
                            MemoryMB = $SourceMachine.memoryMB
                            StorageGB = $SourceMachine.storageGB
                            IsTemplate = $SourceMachine.isTemplate
                            GuestOsFamily = $SourceMachine.guestOSFamily
                            InterfaceType = $SourceMachine.interfaceType
                            Disks = $SourceMachine.disks
                            Properties = $SourceMachine.properties
                        }
                    }
                    
                    break     
                }

                'Standard-Template' {

                    $LoadTemplates = $TemplatesOnly.IsPresent
                    Write-Verbose -Message "Loadtemplates: $LoadTemplates"
                    $URI = "/iaas-proxy-provider/api/source-machines?actionId=FullClone&platformTypeId=Infrastructure.CatalogItem.Machine.Virtual.vSphere&loadTemplates=$($LoadTemplates)&limit=$($Limit)&page=$($Page)"

                    $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$verbosePreference

                    # -- Use helper function to process response from the endpoint
                    intProcessStandardOutput($Response)

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"
                    break
                }

                'Standard' {

                    $URI = "/iaas-proxy-provider/api/source-machines?actionId=FullClone&platformTypeId=Infrastructure.CatalogItem.Machine.Virtual.vSphere&loadTemplates=false&limit=$($Limit)&page=$($Page)"

                    # --- Managed and Template can't work together so only allow this param if
                    if ($PSBoundParameters.ContainsKey("ManagedOnly")) {
                        Write-Verbose -Message "Filtering results for managed machines"
                        $URI = $URI + "&`$filter=status ne 'Unmanaged'"
                    }

                    $EscapedURI = [uri]::EscapeUriString($URI)
                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$verbosePreference

                    # -- Use helper function to process response from the endpoint
                    intProcessStandardOutput($Response)

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"
                    break
                }                
            }
        }
        catch [Exception]{
            
            throw $_
        }   
    }

    End {

    }
}

<#
    - Function: New-vRAExternalNetworkProfile
#>

function New-vRAExternalNetworkProfile {
<#
    .SYNOPSIS
    Create a vRA external network profile
    
    .DESCRIPTION
    Create a vRA external network profile
    
    .PARAMETER Name
    The network profile Name
    
    .PARAMETER Description
    The network profile Description

    .PARAMETER SubnetMask
    The subnet mask of the network profile

    .PARAMETER GatewayAddress
    The gateway address of the network profile

    .PARAMETER PrimaryDNSAddress
    The address of the primary DNS server

    .PARAMETER SecondaryDNSAddress
    The address of the secondary DNS server

    .PARAMETER DNSSuffix
    The DNS suffix

    .PARAMETER DNSSearchSuffix
    The DNS search suffix

    .PARAMETER IPRanges
    An array of ip address ranges

    .PARAMETER PrimaryWinsAddress
    The address of the primary wins server

    .PARAMETER SecondaryWinsAddress
    The address of the secondary wins server

    .INPUTS
    System.String
    PSCustomObject

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    $DefinedRange1 = New-vRANetworkProfileIPRangeDefinition -Name "External-Range-01" -Description "Example 1" -StartIPv4Address "10.60.1.2" -EndIPv4Address "10.60.1.5"
    $DefinedRange2 = New-vRANetworkProfileIPRangeDefinition -Name "External-Range-02" -Description "Example 2" -StartIPv4Address "10.60.1.10" -EndIPv4Address "10.60.1.20"

    New-vRAExternalNetworkProfile -Name Network-External -Description "External" -SubnetMask "255.255.255.0" -GatewayAddress "10.60.1.1" -PrimaryDNSAddress "10.60.1.100" -SecondaryDNSAddress "10.60.1.101" -DNSSuffix "corp.local" -DNSSearchSuffix "corp.local" -IPRanges $DefinedRange1,$DefinedRange2

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description, 

        [Parameter(Mandatory=$true)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SubnetMask,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$GatewayAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$PrimaryDNSAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryDNSAddress,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSuffix,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSearchSuffix,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$IPRanges,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$PrimaryWinsAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryWinsAddress

    )    

    xRequires -Version 7.1

    try {

        # --- Define the network profile template
        $Template = @"

            {
                "@type": "ExternalNetworkProfile",
                "name": "$($Name)",
                "description": "$($Description)",
                "createdDate": null,
                "lastModifiedDate": null,
                "isHidden": false,
                "definedRanges": [],
                "reclaimedAddresses":  null,
                "IPAMEndpointId":  null,
                "IPAMEndpointName":  null,
                "addressSpaceExternalId":  null,
                "profileType": "EXTERNAL",
                "subnetMask": "$($SubnetMask)",
                "gatewayAddress": "$($GatewayAddress)",
                "primaryDnsAddress": "$($PrimaryDNSAddress)",
                "secondaryDnsAddress": "$($SecondaryDNSAddress)",
                "dnsSuffix": "$($DNSSuffix)",
                "dnsSearchSuffix": "$($DNSSearchSuffix)",
                "primaryWinsAddress": "$($PrimaryWinsAddress)",
                "secondaryWinsAddress": "$($SecondaryWinsAddress)"
            }

"@

        if ($PSBoundParameters.ContainsKey("IPRanges")) {

            $Object = $Template | ConvertFrom-Json

            foreach ($IPRange in $IPRanges) {

                $Object.definedRanges += $IPRange

            }

            $Template = $Object | ConvertTo-Json

        }

        if ($PSCmdlet.ShouldProcess($Name)){

            $URI = "/iaas-proxy-provider/api/network/profiles"
                
            # --- Run vRA REST Request
            Invoke-vRARestMethod -Method POST -URI $URI -Body $Template -Verbose:$VerbosePreference | Out-Null

            # --- Output the Successful Result
            Get-vRAExternalNetworkProfile -Name $Name -Verbose:$VerbosePreference

        }

    }
    catch [Exception]{

        throw

    }

}

<#
    - Function: New-vRANATNetworkProfile
#>

function New-vRANATNetworkProfile {
<#
    .SYNOPSIS
    Create a vRA nat network profile
    
    .DESCRIPTION
    Create a vRA nat network profile
    
    .PARAMETER Name
    The network profile Name
    
    .PARAMETER Description
    The network profile Description

    .PARAMETER SubnetMask
    The subnet mask of the network profile

    .PARAMETER GatewayAddress
    The gateway address of the network profile

    .PARAMETER ExternalNetworkProfile
    The external network profile that will be linked to that Routed or NAT network profile

    .PARAMETER UseExternalNetworkProfileSettings
    Use the settings from the selected external network profile

    .PARAMETER PrimaryDNSAddress
    The address of the primary DNS server

    .PARAMETER SecondaryDNSAddress
    The address of the secondary DNS server

    .PARAMETER DNSSuffix
    The DNS suffix

    .PARAMETER DNSSearchSuffix
    The DNS search suffix

    .PARAMETER PrimaryWinsAddress
    The address of the primary wins server

    .PARAMETER SecondaryWinsAddress
    The address of the secondary wins server

    .PARAMETER IPRanges
    An array of ip address ranges

    .PARAMETER NatType
    The nat type. This can be One-to-One or One-to-Many

    .PARAMETER DHCPEnabled
    Enable DHCP for a NAT network profile. Nat type must be One-to-Many

    .PARAMETER DHCPStartAddress
    The start address of the dhcp range

    .PARAMETER DHCPEndAddress
    The end address of the dhcp range

    .PARAMETER DHCPLeaseTime
    The dhcp lease time in seconds. The default is 0.

    .INPUTS
    System.String
    System.Int
    System.Switch
    PSCustomObject

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    $DefinedRange1 = New-vRANetworkProfileIPRangeDefinition -Name "External-Range-01" -Description "Example 1" -StartIPv4Address "10.70.1.2" -EndIPv4Address "10.70.1.5"

    New-vRANATNetworkProfile -Name Network-NAT -Description "NAT" -SubnetMask "255.255.255.0" -GatewayAddress "10.70.1.1" -PrimaryDNSAddress "10.70.1.100" -SecondaryDNSAddress "10.70.1.101" -DNSSuffix "corp.local" -DNSSearchSuffix "corp.local" -NatType ONETOMANY -ExternalNetworkProfile "Network-External" -DHCPEnabled -DHCPStartAddress "10.70.1.20" -DHCPEndAddress "10.70.1.30" -IPRanges $DefinedRange1

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$true)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SubnetMask,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$GatewayAddress,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$ExternalNetworkProfile,

        [Parameter(Mandatory=$false, ParameterSetName="UseExternalProfileSettings")]
        [ValidateNotNullOrEmpty()]
        [Switch]$UseExternalNetworkProfileSettings,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$PrimaryDNSAddress,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryDNSAddress,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSuffix,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSearchSuffix,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$PrimaryWinsAddress,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryWinsAddress,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$IPRanges,

        [Parameter(Mandatory=$true)]
        [ValidateSet("ONETOONE", "ONETOMANY")]
        [String]$NatType,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Switch]$DHCPEnabled,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$DHCPStartAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$DHCPEndAddress,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$DHCPLeaseTime = 0

    )    

    xRequires -Version 7.1
               
    try {

        $ExternalNetworkProfileObject = Get-vRAExternalNetworkProfile -Name $ExternalNetworkProfile -Verbose:$VerbosePreference

        if ($PSBoundParameters.ContainsKey("UseExternalNetworkProfileSettings")) {

            Write-Verbose -Message "Using External Network Profile Settings"
        
            if ($ExternalNetworkProfileObject.primaryDNSAddress) {
            
                $PrimaryDNSAddress = $ExternalNetworKProfileObject.primaryDNSAddress

                Write-Verbose -Message "Primary DNS Address: $($PrimaryDNSAddress)"

            }

            if ($ExternalNetworkProfileObject.secondaryDNSAddress) {

                $SecondaryDNSAddress = $ExternalNetworKProfileObject.secondaryDNSAddress

                Write-Verbose -Message "Secondary DNS Address: $($SecondaryDNSAddress)"

            }

            if ($ExternalNetworkProfileObject.dnsSuffix) {

                $DNSSuffix = $ExternalNetworKProfileObject.dnsSuffix

                Write-Verbose -Message "DNS Suffix: $($DNSSuffix)"

            }

            if ($ExternalNetworkProfileObject.dnsSearchSuffix) {

                $DNSSearchSuffix = $ExternalNetworKProfileObject.dnsSearchSuffix

                Write-Verbose -Message "DNS Search Suffix: $($DNSSearchSuffix)"

            }

            if ($ExternalNetworkProfileObject.primaryWinsAddress) {

                $PrimaryWinsAddress = $ExternalNetworKProfileObject.primaryWinsAddress

                Write-Verbose -Message "Primary Wins Address: $($PrimaryWinsAddress)"

            }

            if ($ExternalNetworkProfileObject.secondaryWinsAddress) {

                $SecondaryWinsAddress = $ExternalNetworKProfileObject.secondaryWinsAddress

                Write-Verbose -Message "Secondary Wins Address: $($SecondaryWinsAddress)"

            }

        }

        # --- Define the network profile
        $Template = @"

            {
                "@type": "NATNetworkProfile",
                "name": "$($Name)",
                "description": "$($Description)",
                "createdDate": null,
                "lastModifiedDate": null,
                "isHidden": false,
                "definedRanges": [],
                "reclaimedAddresses":  null,
                "IPAMEndpointId":  null,
                "IPAMEndpointName":  null,
                "addressSpaceExternalId":  null,
                "profileType": "NAT",
                "natType": "$($NatType)",
                "subnetMask": "$($SubnetMask)",
                "gatewayAddress": "$($GatewayAddress)",
                "primaryDnsAddress": "$($PrimaryDNSAddress)",
                "secondaryDnsAddress": "$($SecondaryDNSAddress)",
                "dnsSuffix": "$($DNSSuffix)",
                "dnsSearchSuffix": "$($DNSSearchSuffix)",
                "primaryWinsAddress": "$($PrimaryWinsAddress)",
                "secondaryWinsAddress": "$($SecondaryWinsAddress)",
                "externalNetworkProfileId": "$($ExternalNetworkProfileObject.id)",
                "externalNetworkProfileName": "$($ExternalNetworkProfileObject.name)"
            }

"@

        # --- Enable DHCP
        if ($DHCPEnabled -and $NatType -eq "ONETOMANY") {

            Write-Verbose -Message "DHCP has been enabled and nat type is set to One-to-Many"
                
            $DHCPConfigurationTemplate = @"

                    {
                        "dhcpStartIPAddress": "$($DHCPStartAddress)",
                        "dhcpEndIPAddress": "$($DHCPEndAddress)",
                        "dhcpLeaseTimeInSeconds": $($DHCPLeaseTime)
                    }

"@
                        
            # --- Add the dhcp configuration to the network profile object
            $Object = $Template | ConvertFrom-Json

            $DHCPConfiguration = $DHCPConfigurationTemplate | ConvertFrom-Json               

            Add-Member -InputObject $Object -MemberType NoteProperty -Name "dhcpConfig" -Value $DHCPConfiguration

            # --- Convert the modified object back to json
            $Template = $Object | ConvertTo-Json -Depth 20

        }

        if ($PSBoundParameters.ContainsKey("IPRanges")) {

            $Object = $Template | ConvertFrom-Json

            foreach ($IPRange in $IPRanges) {

                $Object.definedRanges += $IPRange

            }

            $Template = $Object | ConvertTo-Json -Depth 20 -Compress

        }

        if ($PSCmdlet.ShouldProcess($Name)){

            $URI = "/iaas-proxy-provider/api/network/profiles"
            
            # --- Run vRA REST Request
            Invoke-vRARestMethod -Method POST -URI $URI -Body $Template -Verbose:$VerbosePreference | Out-Null

            # --- Output the Successful Result
            Get-vRANATNetworkProfile -Name $Name -Verbose:$VerbosePreference

        }

    }
    catch [Exception]{

        throw
        
    }

}

<#
    - Function: New-vRANetworkProfileIPRangeDefinition
#>

function New-vRANetworkProfileIPRangeDefinition {
<#
    .SYNOPSIS
    Creates a new network profile ip range definition
        
    .DESCRIPTION
    Creates a new network profile ip range definition

    .PARAMETER Name
    The name of the network profile ip range

    .PARAMETER Description
    A description of the network profile ip range

    .PARAMETER StartIPv4Address
    The start IPv4 address

    .PARAMETER EndIPv4Address
    The end IPv4 address

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRANetworkProfileIPRangeDefinition -Name "External-Range-01" -Description "Example" -StartIPv4Address "10.20.1.2" -EndIPv4Address "10.20.1.5"

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$true)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$StartIPv4Address,
        
        [Parameter(Mandatory=$true)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$EndIPv4Address

    )

    if ($PSCmdlet.ShouldProcess($Name)){

        # --- Define ip address range
        $IPAddressRange = [PSCustomObject] @{

                name = $Name
                description = $Description
                beginIPv4Address = $StartIPv4Address
                endIPv4Address = $EndIPv4Address
                state = "UNALLOCATED"
                createdDate = $null
                lastModifiedDate = $null
                definedAddresses = $null

            }

        # --- Return the new ip address range
        $IPAddressRange
        
    }

}

<#
    - Function: New-vRARoutedNetworkProfile
#>

function New-vRARoutedNetworkProfile {
<#
    .SYNOPSIS
    Create a vRA routed network profile
    
    .DESCRIPTION
    Create a vRA routed network profiles
    
    .PARAMETER Name
    The network profile Name
    
    .PARAMETER Description
    The network profile Description

    .PARAMETER SubnetMask
    The subnet mask of the network profile

    .PARAMETER GatewayAddress
    The gateway address of the network profile

    .PARAMETER ExternalNetworkProfile
    The external network profile that will be linked to that Routed or NAT network profile

    .PARAMETER UseExternalNetworkProfileSettings
    Use the settings from the selected external network profile

    .PARAMETER PrimaryDNSAddress
    The address of the primary DNS server

    .PARAMETER SecondaryDNSAddress
    The address of the secondary DNS server

    .PARAMETER DNSSuffix
    The DNS suffix

    .PARAMETER DNSSearchSuffix
    The DNS search suffix

    .PARAMETER PrimaryWinsAddress
    The address of the primary wins server

    .PARAMETER SecondaryWinsAddress
    The address of the secondary wins server

    .PARAMETER RangeSubnetMask
    The subnetMask for the routed range

    .PARAMETER BaseIPAddress
    The base ip of the routed range

    .PARAMETER IPRanges
    An array of ip address ranges

    .INPUTS
    System.String
    System.Switch
    PSCustomObject

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    $DefinedRange1 = New-vRANetworkProfileIPRangeDefinition -Name "External-Range-01" -Description "Example 1" -StartIPv4Address "10.80.1.2" -EndIPv4Address "10.80.1.5"

    New-vRARoutedNetworkProfile -Name Network-Routed -Description "Routed" -SubnetMask "255.255.255.0" -GatewayAddress "10.80.1.1" -PrimaryDNSAddress "10.80.1.100" -SecondaryDNSAddress "10.80.1.101" -DNSSuffix "corp.local" -DNSSearchSuffix "corp.local" -ExternalNetworkProfile "Network-External" -RangeSubnetMask "255.255.255.0" -BaseIPAddress "10.80.1.2" -IPRanges $DefinedRange1

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description, 

        [Parameter(Mandatory=$true)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SubnetMask,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$GatewayAddress,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$ExternalNetworkProfile,

        [Parameter(Mandatory=$false, ParameterSetName="UseExternalProfileSettings")]
        [ValidateNotNullOrEmpty()]
        [Switch]$UseExternalNetworkProfileSettings,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$PrimaryDNSAddress,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryDNSAddress,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSuffix,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSearchSuffix,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$PrimaryWinsAddress,

        [Parameter(Mandatory=$false, ParameterSetName="Standard")]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryWinsAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$RangeSubnetMask,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$BaseIPAddress,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject[]]$IPRanges

    )    

    xRequires -Version 7.1

    try {
        
        $ExternalNetworkProfileObject = Get-vRAExternalNetworkProfile -Name $ExternalNetworkProfile -Verbose:$VerbosePreference

        if ($PSBoundParameters.ContainsKey("UseExternalNetworkProfileSettings")) {

            Write-Verbose -Message "Using External Network Profile Settings"
        
            if ($ExternalNetworkProfileObject.primaryDNSAddress) {
            
                $PrimaryDNSAddress = $ExternalNetworKProfileObject.primaryDNSAddress

                Write-Verbose -Message "Primary DNS Address: $($PrimaryDNSAddress)"

            }

            if ($ExternalNetworkProfileObject.secondaryDNSAddress) {

                $SecondaryDNSAddress = $ExternalNetworKProfileObject.secondaryDNSAddress

                Write-Verbose -Message "Secondary DNS Address: $($SecondaryDNSAddress)"

            }

            if ($ExternalNetworkProfileObject.dnsSuffix) {

                $DNSSuffix = $ExternalNetworKProfileObject.dnsSuffix

                Write-Verbose -Message "DNS Suffix: $($DNSSuffix)"

            }

            if ($ExternalNetworkProfileObject.dnsSearchSuffix) {

                $DNSSearchSuffix = $ExternalNetworKProfileObject.dnsSearchSuffix

                Write-Verbose -Message "DNS Search Suffix: $($DNSSearchSuffix)"

            }

            if ($ExternalNetworkProfileObject.primaryWinsAddress) {

                $PrimaryWinsAddress = $ExternalNetworKProfileObject.primaryWinsAddress

                Write-Verbose -Message "Primary Wins Address: $($PrimaryWinsAddress)"

            }

            if ($ExternalNetworkProfileObject.secondaryWinsAddress) {

                $SecondaryWinsAddress = $ExternalNetworKProfileObject.secondaryWinsAddress

                Write-Verbose -Message "Secondary Wins Address: $($SecondaryWinsAddress)"

            }

        }

        # --- Define the network profile template
        $Template = @"

            {
                "@type": "RoutedNetworkProfile",
                "name": "$($Name)",
                "description": "$($Description)",
                "createdDate": null,
                "lastModifiedDate": null,
                "isHidden": false,
                "definedRanges": [],
                "reclaimedAddresses":  null,
                "IPAMEndpointId":  null,
                "IPAMEndpointName":  null,
                "addressSpaceExternalId":  null,
                "profileType": "ROUTED",
                "rangeSubnetMask": "$($RangeSubnetMask)",
                "subnetMask": "$($SubnetMask)",
                "primaryDnsAddress": "$($PrimaryDNSAddress)",
                "secondaryDnsAddress": "$($SecondaryDNSAddress)",
                "dnsSuffix": "$($DNSSuffix)",
                "dnsSearchSuffix": "$($DNSSearchSuffix)",
                "primaryWinsAddress": "$($PrimaryWinsAddress)",
                "secondaryWinsAddress": "$($SecondaryWinsAddress)",
                "externalNetworkProfileId": "$($ExternalNetworkProfileObject.id)",
                "externalNetworkProfileName": "$($ExternalNetworkProfileObject.name)",
                "baseIP": "$($BaseIPAddress)"
            }

"@     

        if ($PSBoundParameters.ContainsKey("IPRanges")) {

            $Object = $Template | ConvertFrom-Json

            Write-Output $Object

            foreach ($IPRange in $IPRanges) {

                $Object.definedRanges += $IPRange

            }

            $Template = $Object | ConvertTo-Json -Depth 20

        }

        Write-Debug -Message $Template

        if ($PSCmdlet.ShouldProcess($Name)){

            $URI = "/iaas-proxy-provider/api/network/profiles"
                
            # --- Run vRA REST Request
            Invoke-vRARestMethod -Method POST -URI $URI -Body $Template -Verbose:$VerbosePreference | Out-Null

            # --- Output the Successful Result
            Get-vRARoutedNetworkProfile -Name $Name -Verbose:$VerbosePreference

        }

    }
    catch [Exception]{

        throw
        
    }

}

<#
    - Function: Remove-vRAExternalNetworkProfile
#>

function Remove-vRAExternalNetworkProfile {
<#
    .SYNOPSIS
    Remove an external network profile
    
    .DESCRIPTION
    Remove an external network profile
    
    .PARAMETER Id
    The id of the external network profile

    .PARAMETER Name
    The name of the external network profile

    .INPUTS
    System.String

    .EXAMPLE
    Get-vRAExternalNetworkProfile -Name NetworkProfile01 | Remove-vRAExternalNetworkProfile

    .EXAMPLE
    Remove-vRExternalANetworkProfile -Id 597ff2c1-a35f-4a81-bfd3-ca014

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id
       
    )
    
    Begin {

        xRequires -Version 7.1

    }

    Process {

        try {

            foreach ($NetworkProfileId in $Id) {

                if ($PSCmdlet.ShouldProcess($NetworkProfileId)){

                    $URI = "/iaas-proxy-provider/api/network/profiles/$($NetworkProfileId)"

                    Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null

                }

            }

        }
        catch [Exception]{
        
            throw

        }
            
    }

    End {

    }
     
}

<#
    - Function: Remove-vRANATNetworkProfile
#>

function Remove-vRANATNetworkProfile {
<#
    .SYNOPSIS
    Remove a NAT network profile
    
    .DESCRIPTION
    Remove a NAT network profile
    
    .PARAMETER Id
    The id of the NAT network profile

    .PARAMETER Name
    The name of the NAT network profile

    .INPUTS
    System.String

    .EXAMPLE
    Get-vRANATNetworkProfile -Name NetworkProfile01 | Remove-vRANATNetworkProfile

    .EXAMPLE
    Remove-vRANATNetworkProfile -Id 597ff2c1-a35f-4a81-bfd3-ca014

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id
       
    )
    
    Begin {

        xRequires -Version 7.1

    }
    
    Process {    

        try {

            foreach ($NetworkProfileId in $Id) {

                if ($PSCmdlet.ShouldProcess($NetworkProfileId)){

                    $URI = "/iaas-proxy-provider/api/network/profiles/$($NetworkProfileId)"

                    Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null

                }

            }

        }
        catch [Exception]{
        
            throw

        }
        
    }

    End {
        
    }   
     
}

<#
    - Function: Remove-vRARoutedNetworkProfile
#>

function Remove-vRARoutedNetworkProfile {
<#
    .SYNOPSIS
    Remove a routed network profile
    
    .DESCRIPTION
    Remove a routed network profile
    
    .PARAMETER Id
    The id of the routed network profile

    .PARAMETER Name
    The name of the routed network profile

    .INPUTS
    System.String

    .EXAMPLE
    Get-vRARoutedNetworkProfile -Name NetworkProfile01 | Remove-vRARoutedNetworkProfile

    .EXAMPLE
    Remove-vRARoutedNetworkProfile -Id 597ff2c1-a35f-4a81-bfd3-ca014

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id
       
    )
    
    Begin {

        xRequires -Version 7.1

    }
    
    Process {    

        try {

            foreach ($NetworkProfileId in $Id) {

                if ($PSCmdlet.ShouldProcess($NetworkProfileId)){

                    $URI = "/iaas-proxy-provider/api/network/profiles/$($NetworkProfileId)"

                    Invoke-vRARestMethod -Method DELETE -URI "$($URI)" -Verbose:$VerbosePreference | Out-Null

                }

            }

        }
        catch [Exception]{
        
            throw

        }
        
    }

    End {

    }

}

<#
    - Function: Set-vRAExternalNetworkProfile
#>

function Set-vRAExternalNetworkProfile {
<#
    .SYNOPSIS
    Set a vRA external network profile
    
    .DESCRIPTION
    Set a vRA external network profiles
    
    .PARAMETER Id
    The network profile id
    
    .PARAMETER Name
    The network profile name
    
    .PARAMETER Description
    The network profile description

    .PARAMETER PrimaryDNSAddress
    The address of the primary DNS server

    .PARAMETER SecondaryDNSAddress
    The address of the secondary DNS server

    .PARAMETER DNSSuffix
    The DNS suffix

    .PARAMETER DNSSearchSuffix
    The DNS search suffix

    .PARAMETER PrimaryWinsAddress
    The address of the primary wins server

    .PARAMETER SecondaryWinsAddress
    The address of the secondary wins server

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAExternalNetworkProfile -Name "Network-External" | Set-vRAExternalNetworkProfile -Name "Network-External-Updated" -Description "Updated Description" -PrimaryDNSAddress "10.70.1.100"

    .EXAMPLE
    Set-vRAExternalNetworkProfile -Id 1ada4023-8a02-4349-90bd-732f25001852 -Description "Update Description"

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
        [String]$Id,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description, 

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$PrimaryDNSAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryDNSAddress,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSuffix,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSearchSuffix,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$PrimaryWinsAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]
        [String]$SecondaryWinsAddress

    )    

    Begin {

        xRequires -Version 7.1
    
    }
    
    Process {     
           
        try {

            # --- Get the network profile     
            $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"

            $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

            if ($NetworkProfile.profileType -ne "EXTERNAL") {

                throw "Network Profile $($NetworkProfile.id) is not of type EXTERNAL"

            }

            # --- Set Properties
            if ($PSBoundParameters.ContainsKey("Name")) {

                Write-Verbose -Message "Updating Name: $($NetworkProfile.name) >> $($Name)"

                $NetworkProfile.name = $Name

            }

            if ($PSBoundParameters.ContainsKey("Description")) {

                Write-Verbose -Message "Updating Description: $($NetworkProfile.description) >> $($Description)"

                $NetworkProfile.description = $Description

            }

            if ($PSBoundParameters.ContainsKey("PrimaryDNSAddress")) {

                Write-Verbose -Message "Updating Primary DNS Address: $($NetworkProfile.primaryDNSAddress) >> $($PrimaryDNSAddress)"

                $NetworkProfile.primaryDNSAddress = $PrimaryDNSAddress

            }

            if ($PSBoundParameters.ContainsKey("SecondaryDNSAddress")) {

                Write-Verbose -Message "Updating Secondary DNS Address: $($NetworkProfile.secondaryDNSAddress) >> $($SecondaryDNSAddress)"

                $NetworkProfile.secondaryDNSAddress = $SecondaryDNSAddress

            }

            if ($PSBoundParameters.ContainsKey("DNSSuffix")) {

                Write-Verbose -Message "Updating DNS Suffix: $($NetworkProfile.dnsSuffix) >> $($DNSSuffix)"

                $NetworkProfile.dnsSuffix = $DNSSuffix

            }

            if ($PSBoundParameters.ContainsKey("DNSSearchSuffix")) {

                Write-Verbose -Message "Updating DNS Search Address: $($NetworkProfile.dnsSearchSuffix) >> $($DNSSearchSuffix)"

                $NetworkProfile.dnsSearchSuffix = $DNSSearchSuffix

            }

            if ($PSBoundParameters.ContainsKey("PrimaryWinsAddress")) {

                Write-Verbose -Message "Updating Primary WINS Address: $($NetworkProfile.primaryWinsAddress) >> $($PrimaryWinsAddress)"

                $NetworkProfile.primaryWinsAddress = $PrimaryWinsAddress

            }

            if ($PSBoundParameters.ContainsKey("SecondaryWinsAddress")) {

                Write-Verbose -Message "Updating Secondary WINS Address: $($NetworkProfile.secondaryWinsAddress) >> $($SecondaryWinsAddress)"

                $NetworkProfile.secondaryWinsAddress = $SecondaryWinsAddress

            }

            $NetworkProfileTemplate = $NetworkProfile | ConvertTo-Json -Depth 100

            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"
                  
                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body $NetworkProfileTemplate -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRAExternalNetworkProfile -Id $Id -Verbose:$VerbosePreference

            }

        }
        catch [Exception]{

            throw

        }

    }
    
    End {
        
    }

}

<#
    - Function: Set-vRANATNetworkProfile
#>

function Set-vRANATNetworkProfile {
<#
    .SYNOPSIS
    Set a vRA network profile
    
    .DESCRIPTION
    Set a vRA network profiles
    
    .PARAMETER Id
    The network profile id
    
    .PARAMETER Name
    The network profile name
    
    .PARAMETER Description
    The network profile description

    .PARAMETER GatewayAddress
    The gateway address of the network profile

    .PARAMETER PrimaryDNSAddress
    The address of the primary DNS server

    .PARAMETER SecondaryDNSAddress
    The address of the secondary DNS server

    .PARAMETER DNSSuffix
    The DNS suffix

    .PARAMETER DNSSearchSuffix
    The DNS search suffix

    .PARAMETER PrimaryWinsAddress
    The address of the primary wins server

    .PARAMETER SecondaryWinsAddress
    The address of the secondary wins server

    .PARAMETER NatType
    The nat type. This can be One-to-One or One-to-Many

    .PARAMETER DHCPEnabled
    Enable DHCP for a NAT network profile. Nat type must be One-to-Many

    .PARAMETER DHCPStartAddress
    The start address of the dhcp range

    .PARAMETER DHCPEndAddress
    The end address of the dhcp range

    .PARAMETER DHCPLeaseTime
    The dhcp lease time in seconds. The default is 0.

    .INPUTS
    System.String.
    System.Int.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRANATNetworkProfile -Name "Network-Nat" | Set-vRANATNetworkProfile -Name "Network-NAT-Updated" -Description "Updated Description" -GatewayAddress "10.70.2.1" -PrimaryDNSAddress "10.70.1.100"

    .EXAMPLE
    Set-vRANATNetworkProfile -Id 1ada4023-8a02-4349-90bd-732f25001852 -Description "Updated Description"

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [String]$Id,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$GatewayAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$PrimaryDNSAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryDNSAddress,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSuffix,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSearchSuffix,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$PrimaryWinsAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]
        [String]$SecondaryWinsAddress,

        [Parameter(Mandatory=$false)]
        [ValidateSet("ONETOONE", "ONETOMANY")]
        [String]$NatType,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Switch]$DHCPEnabled,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$DHCPStartAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$DHCPEndAddress,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$DHCPLeaseTime

    )    

    Begin {

        xRequires -Version 7.1
    
    }
    
    Process {     
           
        try {

            # --- Get the network profile     
            $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"

            $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

            if ($NetworkProfile.profileType -ne "NAT") {

                throw "Network Profile $($NetworkProfile.id) is not of type NAT"

            }

            # --- Set Properties
            if ($PSBoundParameters.ContainsKey("Name")) {

                Write-Verbose -Message "Updating Name: $($NetworkProfile.name) >> $($Name)"

                $NetworkProfile.name = $Name

            }

            if ($PSBoundParameters.ContainsKey("Description")) {

                Write-Verbose -Message "Updating Description: $($NetworkProfile.description) >> $($Description)"

                $NetworkProfile.description = $Description

            }

            if ($PSBoundParameters.ContainsKey("PrimaryDNSAddress")) {

                Write-Verbose -Message "Updating Primary DNS Address: $($NetworkProfile.primaryDNSAddress) >> $($PrimaryDNSAddress)"

                $NetworkProfile.primaryDNSAddress = $PrimaryDNSAddress

            }

            if ($PSBoundParameters.ContainsKey("SecondaryDNSAddress")) {

                Write-Verbose -Message "Updating Secondary DNS Address: $($NetworkProfile.secondaryDNSAddress) >> $($SecondaryDNSAddress)"

                $NetworkProfile.secondaryDNSAddress = $SecondaryDNSAddress

            }

            if ($PSBoundParameters.ContainsKey("DNSSuffix")) {

                Write-Verbose -Message "Updating DNS Suffix: $($NetworkProfile.dnsSuffix) >> $($DNSSuffix)"

                $NetworkProfile.dnsSuffix = $DNSSuffix

            }

            if ($PSBoundParameters.ContainsKey("DNSSearchSuffix")) {

                Write-Verbose -Message "Updating DNS Search Address: $($NetworkProfile.dnsSearchSuffix) >> $($DNSSearchSuffix)"

                $NetworkProfile.dnsSearchSuffix = $DNSSearchSuffix

            }

            if ($PSBoundParameters.ContainsKey("PrimaryWinsAddress")) {

                Write-Verbose -Message "Updating Primary WINS Address: $($NetworkProfile.primaryWinsAddress) >> $($PrimaryWinsAddress)"

                $NetworkProfile.primaryWinsAddress = $PrimaryWinsAddress

            }

            if ($PSBoundParameters.ContainsKey("SecondaryWinsAddress")) {

                Write-Verbose -Message "Updating Secondary WINS Address: $($NetworkProfile.secondaryWinsAddress) >> $($SecondaryWinsAddress)"

                $NetworkProfile.secondaryWinsAddress = $SecondaryWinsAddress

            }

            if ($PSBoundParameters.ContainsKey("GatewayAddress")) {

                Write-Verbose -Message "Updating Gateway Address: $($NetworkProfile.gatewayAddress) >> $GatewayAddress"

                $NetworkProfile.gatewayAddress = $GatewayAddress

            }

            if ($PSBoundParameters.ContainsKey("NatType")) {

                Write-Verbose -Message "Updating Nat Type: $($NetworkProfile.natType) >> $($NatType)"

                $NetworkProfile.natType = $NatType

                if ($NatType -eq "ONETOONE" -and $NetworkProfile.dhcpConfig) {

                    Write-Verbose -Message "Nat Type is One-to-One and DHCP is ENABLED"
                    Write-Verbose -Message "Disabling DHCP"

                    $NetworkProfile.PSObject.properties.Remove("dhcpConfig")

                }

            }

            if ($PSBoundParameters.ContainsKey("GatewayAddress")) {

                Write-Verbose -Message "Updating Gateway Address: $($NetworkProfile.gatewayAddress) >> $($GatewayAddress)"

                $NetworkProfile.gatewayAddress = $GatewayAddress

            }

            if ($PSBoundParameters.ContainsKey("DHCPEnabled")) {

                if ($DHCPEnabled -and !$NetworkProfile.dhcpConfig -and $NetworkProfile.natType -eq "ONETOMANY") {

                    Write-Verbose -Message "DHCP has been enabled and nat type is set to One-to-Many"
                    
                    $DHCPConfigurationTemplate = @"

                        {
                            "dhcpStartIPAddress": null,
                            "dhcpEndIPAddress": null,
                            "dhcpLeaseTimeInSeconds": null
                        }

"@
                    
                    # --- Add the dhcp configuration to the network profile object
                    $DHCPConfiguration = $DHCPConfigurationTemplate | ConvertFrom-Json               

                    Add-Member -InputObject $NetworkProfile -MemberType NoteProperty -Name "dhcpConfig" -Value $DHCPConfiguration

                }

                if (!$DHCPEnabled) {

                    if ($NetworkProfile.dhcpConfig) {

                        Write-Verbose -Message "Disabling DHCP"

                        $NetworkProfile.PSObject.properties.Remove("dhcpConfig")

                    }

                }

            }

            if ($PSBoundParameters.ContainsKey("DHCPStartAddress")) {

                if ($NetworkProfile.dhcpConfig) {

                    Write-Verbose -Message "Updating DHCP Start Address: $($NetworkProfile.dhcpConfig.dhcpStartIPAddress) >> $($DHCPStartAddress)"

                    $NetworkProfile.dhcpConfig.dhcpstartIPAddress = $DHCPStartAddress

                }

            }

            if ($PSBoundParameters.ContainsKey("DHCPEndAddress")) {

                if ($NetworkProfile.dhcpConfig) {

                    Write-Verbose -Message "Updating DHCP End Address: $($NetworkProfile.dhcpConfig.dhcpEndIPAddress) >> $($DHCPEndAddress)"

                    $NetworkProfile.dhcpConfig.dhcpEndIPAddress = $DHCPEndAddress

                }

            }

            if ($PSBoundParameters.ContainsKey("DHCPLeaseTime")) {

                if ($NetworkProfile.dhcpConfig) {

                    Write-Verbose -Message "Updating DHCP Lease Time: $($NetworkProfile.dhcpConfig.dhcpLeaseTimeInSeconds) >> $($DHCPLeaseTime)"

                    $NetworkProfile.dhcpConfig.dhcpLeaseTimeInSeconds = $DHCPLeaseTime

                }

            }

            $NetworkProfileTemplate = $NetworkProfile | ConvertTo-Json -Depth 100

            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"
                  
                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body $NetworkProfileTemplate -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRANATNetworkProfile -Id $Id -Verbose:$VerbosePreference
                
            }

        }
        catch [Exception]{

            throw

        }

    }
    
    End {
        
    }

}

<#
    - Function: Set-vRARoutedNetworkProfile
#>

function Set-vRARoutedNetworkProfile {
<#
    .SYNOPSIS
    Set a vRA network profile
    
    .DESCRIPTION
    Set a vRA network profiles
    
    .PARAMETER Id
    The network profile id
    
    .PARAMETER Name
    The network profile name
    
    .PARAMETER Description
    The network profile description

    .PARAMETER PrimaryDNSAddress
    The address of the primary DNS server

    .PARAMETER SecondaryDNSAddress
    The address of the secondary DNS server

    .PARAMETER DNSSuffix
    The DNS suffix

    .PARAMETER DNSSearchSuffix
    The DNS search suffix

    .PARAMETER PrimaryWinsAddress
    The address of the primary wins server

    .PARAMETER SecondaryWinsAddress
    The address of the secondary wins server

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRARoutedNetworkProfile -Name "Network-Routed" | Set-vRARoutedNetworkProfile -Name "Network-Routed-Updated" -Description "Updated Description"

    .EXAMPLE
    Set-vRARoutedNetworkProfile -Id 1ada4023-8a02-4349-90bd-732f25001852 -Description "Updated Description"

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [String]$Id,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$PrimaryDNSAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]  
        [String]$SecondaryDNSAddress,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSuffix,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$DNSSearchSuffix,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })] 
        [String]$PrimaryWinsAddress,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match [IPAddress]$_ })]
        [String]$SecondaryWinsAddress

    )    

    Begin {

        xRequires -Version 7.1
    
    }
    
    Process {     
           
        try {

            # --- Get the network profile     
            $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"

            $NetworkProfile = Invoke-vRARestMethod -Method GET -URI $URI

            if ($NetworkProfile.profileType -ne "ROUTED") {

                throw "Network Profile $($NetworkProfile.id) is not of type ROUTED"

            }

            # --- Set Properties
            if ($PSBoundParameters.ContainsKey("Name")) {

                Write-Verbose -Message "Updating Name: $($NetworkProfile.name) >> $($Name)"

                $NetworkProfile.name = $Name

            }

            if ($PSBoundParameters.ContainsKey("Description")) {

                Write-Verbose -Message "Updating Description: $($NetworkProfile.description) >> $($Description)"

                $NetworkProfile.description = $Description

            }

            if ($PSBoundParameters.ContainsKey("PrimaryDNSAddress")) {

                Write-Verbose -Message "Updating Primary DNS Address: $($NetworkProfile.primaryDNSAddress) >> $($PrimaryDNSAddress)"

                $NetworkProfile.primaryDNSAddress = $PrimaryDNSAddress

            }

            if ($PSBoundParameters.ContainsKey("SecondaryDNSAddress")) {

                Write-Verbose -Message "Updating Secondary DNS Address: $($NetworkProfile.secondaryDNSAddress) >> $($SecondaryDNSAddress)"

                $NetworkProfile.secondaryDNSAddress = $SecondaryDNSAddress

            }

            if ($PSBoundParameters.ContainsKey("DNSSuffix")) {

                Write-Verbose -Message "Updating DNS Suffix: $($NetworkProfile.dnsSuffix) >> $($DNSSuffix)"

                $NetworkProfile.dnsSuffix = $DNSSuffix

            }

            if ($PSBoundParameters.ContainsKey("DNSSearchSuffix")) {

                Write-Verbose -Message "Updating DNS Search Address: $($NetworkProfile.dnsSearchSuffix) >> $($DNSSearchSuffix)"

                $NetworkProfile.dnsSearchSuffix = $DNSSearchSuffix

            }

            if ($PSBoundParameters.ContainsKey("PrimaryWinsAddress")) {

                Write-Verbose -Message "Updating Primary WINS Address: $($NetworkProfile.primaryWinsAddress) >> $($PrimaryWinsAddress)"

                $NetworkProfile.primaryWinsAddress = $PrimaryWinsAddress

            }

            if ($PSBoundParameters.ContainsKey("SecondaryWinsAddress")) {

                Write-Verbose -Message "Updating Secondary WINS Address: $($NetworkProfile.secondaryWinsAddress) >> $($SecondaryWinsAddress)"

                $NetworkProfile.secondaryWinsAddress = $SecondaryWinsAddress

            }

            $NetworkProfileTemplate = $NetworkProfile | ConvertTo-Json -Depth 100

            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/iaas-proxy-provider/api/network/profiles/$($Id)"
                  
                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body $NetworkProfileTemplate -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRARoutedNetworkProfile -Id $Id -Verbose:$VerbosePreference

            }

        }
        catch [Exception]{

            throw

        }

    }
    
    End {
        
    }

}

<#
    - Function: Add-vRAPrincipalToTenantRole
#>

function Add-vRAPrincipalToTenantRole {
<#
    .SYNOPSIS
    Add a vRA Principal to a Tenant Role
    
    .DESCRIPTION
    Add a vRA Principal to a Tenant Role
    
    .PARAMETER TenantId
    Specify the Tenant Id

    .PARAMETER PrincipalId
    Specify the Principal Id

    .PARAMETER RoleId
    Specify the Role Id

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.
    
    .EXAMPLE
    Add-vRAPrincipalToTenantRole -TenantId Tenant01 -PrincipalId Tenantadmin@vrademo.local -RoleId CSP_TENANT_ADMIN

    .EXAMPLE
    Get-vRAUserPrincipal -UserName Tenantadmin@vrademo.local | Add-vRAPrincipalToTenantRole -TenantId Tenant01 -RoleId CSP_TENANT_ADMIN
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$TenantId,
    
    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$PrincipalId,  
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$RoleId
    )

begin {

}

process {

    foreach ($Principal in $PrincipalId){
                
        try {

            if ($PSCmdlet.ShouldProcess($Principal)){
     
                $URI = "/identity/api/authorization/tenants/$($TenantId)/principals/$($Principal)/roles/$($Roleid)"

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Verbose:$VerbosePreference | Out-Null
        
                # --- Output the Successful Result
                Get-vRATenantRole -TenantId $TenantId -PrincipalId $Principal | Where-Object {$_.Id -eq $RoleId} | Select-Object Principal,Id,Name
            }
        }
        catch [Exception]{

            throw
        }
    }
}

end {

}
}

<#
    - Function: Get-vRAAuthorizationRole
#>

function Get-vRAAuthorizationRole {
<#
    .SYNOPSIS
    Retrieve vRA Authorization Role
    
    .DESCRIPTION
    Retrieve vRA Authorization Role
    
    .PARAMETER Id
    Specify the Id of a Role

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAAuthorizationRole
    
    .EXAMPLE
    Get-vRAAuthorizationRole -Id CSP_TENANT_ADMIN
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,    
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"
    )
                
try {
    # --- If the Id parameter is passed return only that Role Id
    if ($PSBoundParameters.ContainsKey("Id")){ 
        
        foreach ($Role in $Id){

            $URI = "/identity/api/authorization/roles/$Role"

            # --- Run vRA REST Request
            $Response = Invoke-vRARestMethod -Method GET -URI $URI
        
            [pscustomobject]@{

                Id = $Response.id
                Name = $Response.name
                Description = $Response.description
                Type = $Response.'@type'
                AssignedPermissions = $Response.assignedPermissions
            }
        }
    }
    else {

        $URI = "/identity/api/authorization/roles?limit=$($Limit)"
        
        # --- Run vRA REST Request
        $Response = Invoke-vRARestMethod -Method GET -URI $URI
        
        foreach ($Role in $Response.content) {
        
            [pscustomobject]@{

                Id = $Role.id
                Name = $Role.name
                Description = $Role.description
                Type = $Role.'@type'
                AssignedPermissions = $Role.assignedPermissions
            }
        }
    }
}
catch [Exception]{

    throw
}
}

<#
    - Function: Get-vRABusinessGroup
#>

function Get-vRABusinessGroup {
<#
    .SYNOPSIS
    Retrieve vRA Business Groups
    
    .DESCRIPTION
    Retrieve vRA Business Groups
    
    .PARAMETER TenantId
    Specify the ID of a Tenant

    .PARAMETER Name
    Specify the Name of a Business Group

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.
    
    .EXAMPLE
    Get-vRABusinessGroup

    .EXAMPLE
    Get-vRABusinessGroup -TenantId Tenant01 -Name BusinessGroup01,BusinessGroup02
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$TenantId = $Global:vRAConnection.Tenant,
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name,     
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"
    )
    
# --- Test for vRA API version
xRequires -Version 7.0
                
try {

    # --- Check the TenantId
    if ($PSBoundParameters.ContainsKey("TenantId")) {

        $TenantId = (Get-vRATenant -Id $TenantId).Id
    }

    # --- Get business group by name
    if ($PSBoundParameters.ContainsKey("Name")) {

        foreach ($BusinessGroupName in $Name){

            $EscapedBusinessGroupName = [URI]::EscapeDataString($BusinessGroupName)
            $URI = "/identity/api/tenants/$($TenantId)/subtenants?`$filter=name%20eq%20'$($EscapedBusinessGroupName)'"

            # --- Run vRA REST Request
            $Response = Invoke-vRARestMethod -Method GET -URI $URI
            
            $BusinessGroup = $Response.content
            
            if (-not $BusinessGroup){

                Write-Warning "Did not find Business Group $BusinessGroupName"
                break
            }

            # --- Get the role details
            $BusinessGroupRolesURI = "/identity/api/tenants/$($TenantId)/subtenants/$($BusinessGroup.id)/roles"

            # --- Run vRA REST Request
            $BusinessGroupRolesResponse = Invoke-vRARestMethod -Method GET -URI $BusinessGroupRolesURI

            $GroupManagerRole = $BusinessGroupRolesResponse.content | Where-Object {$_.name -eq "Business Group Manager"}
            $SupportUserRole = $BusinessGroupRolesResponse.content | Where-Object {$_.name -eq "Support User"}
            $SharedAccessUserRole = $BusinessGroupRolesResponse.content | Where-Object {$_.name -eq "com.vmware.csp.core.cafe.identity@csp.scoperole.sharedaccess.user.name"}
            $UserRole = $BusinessGroupRolesResponse.content | Where-Object {$_.name -eq "Basic User"}

            [pscustomobject]@{

                Name = $BusinessGroup.name
                ID = $BusinessGroup.id
                Description = $BusinessGroup.description
                Roles = $BusinessGroup.subtenantRoles
                ExtensionData = $BusinessGroup.extensionData
                GroupManagerRole = $GroupManagerRole.principalId
                SupportUserRole = $SupportUserRole.principalId
                SharedAccessUserRole = $SharedAccessUserRole.principalId
                UserRole = $UserRole.principalId
                Tenant = $BusinessGroup.tenant
            }
        }
    }
    else {

        $URI = "/identity/api/tenants/$($TenantId)/subtenants?limit=$($Limit)"

        # --- Run vRA REST Request
        $Response = Invoke-vRARestMethod -Method GET -URI $URI

        foreach ($BusinessGroup in $Response.content){
            
            # --- Get the role details
            $BusinessGroupRolesURI = "/identity/api/tenants/$($TenantId)/subtenants/$($BusinessGroup.id)/roles"

            # --- Run vRA REST Request
            $BusinessGroupRolesResponse = Invoke-vRARestMethod -Method GET -URI $BusinessGroupRolesURI

            $GroupManagerRole = $BusinessGroupRolesResponse.content | Where-Object {$_.name -eq "Business Group Manager"}
            $SupportUserRole = $BusinessGroupRolesResponse.content | Where-Object {$_.name -eq "Support User"}
            $SharedAccessUserRole = $BusinessGroupRolesResponse.content | Where-Object {$_.name -eq "com.vmware.csp.core.cafe.identity@csp.scoperole.sharedaccess.user.name"}
            $UserRole = $BusinessGroupRolesResponse.content | Where-Object {$_.name -eq "Basic User"}

            [pscustomobject]@{

                Name = $BusinessGroup.name
                ID = $BusinessGroup.id
                Description = $BusinessGroup.description
                Roles = $BusinessGroup.subtenantRoles
                ExtensionData = $BusinessGroup.extensionData
                GroupManagerRole = $GroupManagerRole.principalId
                SupportUserRole = $SupportUserRole.principalId
                SharedAccessUserRole = $SharedAccessUserRole.principalId
                UserRole = $UserRole.principalId
                Tenant = $BusinessGroup.tenant
            }
        }
    }
}
catch [Exception]{

    throw
}
}

<#
    - Function: Get-vRAGroupPrincipal
#>

function Get-vRAGroupPrincipal {
<#
    .SYNOPSIS
    Finds groups.
    
    .DESCRIPTION
    Finds groups in one of the identity providers configured for the tenant.
    
    .PARAMETER Id
    The Id of the group
    
    .PARAMETER Tenant
    The tenant of the group
    
    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAGroupPrincipal
    
    .EXAMPLE
    Get-vRAGroupPrincipal -Id group@vsphere.local
    
    .EXAMPLE
    Get-vRAGroupPrincipal -PrincipalId group@vsphere.local    

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="ById")]    
    [ValidateNotNullOrEmpty()]
    [Alias("PrincipalId")]
    [String[]]$Id,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [parameter(Mandatory=$false,ParameterSetName="ById")]    
    [ValidateNotNullOrEmpty()]
    [String]$Tenant = $Global:vRAConnection.Tenant,          
          
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"
    
    )
    
    begin {}
    
    process {
                
        try {

            switch ($PsCmdlet.ParameterSetName) {
                
                'ById' {
                    
                    foreach ($GroupId in $Id){

                        $URI = "/identity/api/tenants/$($Tenant)/groups/$($GroupId)"

                        # --- Run vRA REST Request
                        $Response = Invoke-vRARestMethod -Method GET -URI $URI
                    
                        [pscustomobject] @{

                            GroupType = $Response.groupType
                            Name = $Response.name
                            Domain = $Response.domain
                            Description = $Response.description
                            PrincipalId = "$($Response.principalId.name)@$($Response.principalId.domain)"

                        }                                    

                    }
                    
                    break                
    
                }
                
                'Standard' {
    
                    $URI = "/identity/api/tenants/$($Tenant)/groups?limit=$($Limit)"
                    
                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI
                    
                    foreach ($Principal in $Response.content) {
                    
                        [pscustomobject] @{

                            GroupType = $Principal.groupType
                            Name = $Principal.name
                            Domain = $Principal.domain
                            Description = $Principal.description
                            PrincipalId = "$($Principal.principalId.name)@$($Principal.principalId.domain)"

                        }

                    }
                    
                    break              
                                    
                }
                
            }
            
        }
        catch [Exception]{

            throw
            
        }
        
    }
    
    end {}
        
}

<#
    - Function: Get-vRATenant
#>

function Get-vRATenant {
<#
    .SYNOPSIS
    Retrieve vRA Tenants
    
    .DESCRIPTION
    Retrieve vRA Tenants. Make sure to have permission to access all Tenant information
    
    .PARAMETER Id
    Specify the ID of a Tenant

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRATenant
    
    .EXAMPLE
    Get-vRATenant -Id Tenant01
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Alias("Name")]
    [String[]]$Id,    
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"
    )
                
try {
    # --- If the Id parameter is passed return only that Tenant
    if ($PSBoundParameters.ContainsKey("Id")){ 
        
        foreach ($TenantId in $Id){

            $URI = "/identity/api/tenants/$($TenantId)"

            # --- Run vRA REST Request
            $Response = Invoke-vRARestMethod -Method GET -URI $URI
        
            [pscustomobject]@{

                Id = $Response.id
                UrlName = $Response.urlName
                Name = $Response.name
                Description = $Response.description
                ContactEmail = $Response.contactEmail
                Password = $Response.password
                DefaultTenant = $Response.defaultTenant
            }
        }
    }
    else {

        $URI = "/identity/api/tenants?limit=$($Limit)"
        
        # --- Run vRA REST Request
        $Response = Invoke-vRARestMethod -Method GET -URI $URI
        
        foreach ($Tenant in $Response.content) {
        
            [pscustomobject]@{

                Id = $Tenant.id
                UrlName = $Tenant.urlName
                Name = $Tenant.name
                Description = $Tenant.description
                ContactEmail = $Tenant.contactEmail
                Password = $Tenant.password
                DefaultTenant = $Tenant.defaultTenant
            }
        }
    }
}
catch [Exception]{

    throw
}
}

<#
    - Function: Get-vRATenantDirectory
#>

function Get-vRATenantDirectory {
<#
    .SYNOPSIS
    Retrieve vRA Tenant Directories

    .DESCRIPTION
    Retrieve vRA Tenant Directories

    .PARAMETER Id
    Specify the ID of a Tenant

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRATenantDirectory -Id Tenant01

    .EXAMPLE
    Get-vRATenantDirectory -Id Tenant01,Tenant02
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"
    )

try {

    foreach ($TenantId in $Id){

        $URI = "/identity/api/tenants/$($TenantId)/directories?limit=$($Limit)"

        # --- Run vRA REST Request
        $Response = Invoke-vRARestMethod -Method GET -URI $URI

        if ($Response.content){

            foreach ($TenantDirectory in $Response.Content){

                [pscustomobject]@{

                    Name = $TenantDirectory.name
                    Description = $TenantDirectory.description
                    Domain = $TenantDirectory.domain
                    Alias = $TenantDirectory.alias
                    Type = $TenantDirectory.type
                    UserNameDN = $TenantDirectory.userNameDn
                    Password = $TenantDirectory.password
                    URL = $TenantDirectory.url
                    GroupBaseSearchDN = $TenantDirectory.groupBaseSearchDn
                    UserBaseSearchDN = $TenantDirectory.userBaseSearchDn
                    Subdomains = $TenantDirectory.subdomains
                    GroupBaseSearchDNs = $TenantDirectory.groupBaseSearchDns
                    UserBaseSearchDNs = $TenantDirectory.userBaseSearchDns
                    DomainAdminUsername = $TenantDirectory.domainAdminUsername
                    DomainAdminPassword = $TenantDirectory.domainAdminPassword
                    Certificate = $TenantDirectory.certificate
                    TrustAll = $TenantDirectory.trustAll
                    UseGlobalCatalog = $TenantDirectory.useGlobalCatalog
                    New = $TenantDirectory.new
                }
            }
        }
    }
}
catch [Exception]{

    throw
}
}

<#
    - Function: Get-vRATenantDirectoryStatus
#>

function Get-vRATenantDirectoryStatus {
<#
    .SYNOPSIS
    Retrieve vRA Tenant Directory Status
    
    .DESCRIPTION
    Retrieve vRA Tenant Directory Status
    
    .PARAMETER Id
    Specify the ID of a Tenant

    .PARAMETER Domain
    Specify the Domain of a Tenant Directory

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.
    
    .EXAMPLE
    Get-vRATenantDirectoryStatus -Id Tenant01 -Domain vrademo.local

    .EXAMPLE
    Get-vRATenantDirectoryStatus -Id Tenant01 -Domain vrademo.local,test.local
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Id,    
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Domain
    )

    # --- Test for vRA API version
    xRequires -Version 7.0
                
try {
        
    foreach ($TenantDomain in $Domain){

        $URI = "/identity/api/tenants/$($Id)/directories/$($TenantDomain)/status"

        # --- Run vRA REST Request
        $Response = Invoke-vRARestMethod -Method GET -URI $URI
        
        [pscustomobject]@{

            Tenant = $Id
            Directory = $TenantDomain
            Status = $Response.syncStatus.status
            Message = $Response.syncStatus.message
        }
    }
}
catch [Exception]{

    throw
}
}

<#
    - Function: Get-vRATenantRole
#>

function Get-vRATenantRole {
<#
    .SYNOPSIS
    Retrieve vRA Tenant Role
    
    .DESCRIPTION
    Retrieve vRA Tenant Role
    
    .PARAMETER TenantId
    Specify the Tenant Id

    .PARAMETER PrincipalId
    Specify the Principal Id

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.
    
    .EXAMPLE
    Get-vRATenantRole -TenantId Tenant01 -PrincipalId Tenantadmin@vrademo.local
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$TenantId,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$PrincipalId,  
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"
    )
                
try {
        
        foreach ($Principal in $PrincipalId){

            $URI = "/identity/api/authorization/tenants/$($TenantId)/principals/$Principal/roles?limit=$($Limit)"

            # --- Run vRA REST Request
            $Response = Invoke-vRARestMethod -Method GET -URI $URI
        
            foreach ($Role in $Response.content) {
        
                [pscustomobject]@{

                    Principal = $Principal
                    Id = $Role.id
                    Name = $Role.name
                    Description = $Role.description
                    Type = $Role.'@type'
                    AssignedPermissions = $Role.assignedPermissions
                }
            }
        }
}
catch [Exception]{

    throw
}
}

<#
    - Function: Get-vRAUserPrincipal
#>

function Get-vRAUserPrincipal {
<#
    .SYNOPSIS
    Finds regular users
    
    .DESCRIPTION
    Finds regular users in one of the identity providers configured for the tenant.
    
    .PARAMETER Id
    The Id of the user
    
    .PARAMETER Tenant
    The tenant of the user
    
    .PARAMETER LocalUsersOnly
    Only return local users
    
    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAUserPrincipal
    
    .EXAMPLE
    Get-vRAUserPrincipal -LocalUsersOnly

    .EXAMPLE
    Get-vRAUserPrincipal -Id user@vsphere.local
    
    .EXAMPLE
    Get-vRAUserPrincipal -UserName user@vsphere.local
    
    .EXAMPLE
    Get-vRAUserPrincipal -PrincipalId user@vsphere.local
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true, ParameterSetName="byId")]
    [ValidateNotNullOrEmpty()]
    [Alias("UserName","PrincipalId")]
    [String[]]$Id,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]  
    [parameter(Mandatory=$false,ParameterSetName="byId")]    
    [ValidateNotNullOrEmpty()]
    [String]$Tenant = $Global:vRAConnection.Tenant,    
    
    [parameter(Mandatory=$false, ParameterSetName="Standard")]
    [Switch]$LocalUsersOnly,   
          
    [parameter(Mandatory=$false, ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"
    
    )
    
    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    process {
                
        try {
            
            switch ($PSCmdlet.ParameterSetName){
                
                'ById'{

                    foreach ($UserId in $Id){

                        $URI = "/identity/api/tenants/$($Tenant)/principals/$($UserId)"

                        # --- Run vRA REST Request
                        $Response = Invoke-vRARestMethod -Method GET -URI $URI
                    
                        [pscustomobject] @{

                            FirstName = $Response.firstName
                            LastName = $Response.lastName
                            EmailAddress = $Response.emailAddress
                            Description = $Response.description
                            Locked = $Response.locked
                            Disabled = $Response.disabled
                            Password = $Response.password
                            PrincipalId = "$($Response.principalId.name)@$($Response.principalId.domain)"
                            TenantName = $Response.tenantName
                            Name = $Response.name

                        }
                        
                    }
                    
                    break
                                    
                }
                
                'Standard' {
                        
                    if ($PSBoundParameters.ContainsKey("LocalUsersOnly")) {
                        
                        $Params = "&localUsersOnly=true"
                        
                    }
                    
                    $URI = "/identity/api/tenants/$($Tenant)/principals?limit=$($Limit)$($Params)"
                    
                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI
                    
                    foreach ($Principal in $Response.content) {
                    
                        [pscustomobject] @{

                            FirstName = $Principal.firstName
                            LastName = $Principal.lastName
                            EmailAddress = $Principal.emailAddress
                            Description = $Principal.description
                            Locked = $Principal.locked
                            Disabled = $Principal.disabled
                            Password = $Principal.password
                            PrincipalId = "$($Principal.principalId.name)@$($Principal.principalId.domain)"
                            TenantName = $Principal.tenantName
                            Name = $Principal.name

                        }
                        
                    }
                    
                    break                                
                    
                }
        
            }
            
        }
        catch [Exception]{

            throw
            
        }
        
    }
    
    end {}
    
}

<#
    - Function: Get-vRAUserPrincipalGroupMembership
#>

function Get-vRAUserPrincipalGroupMembership {
<#
    .SYNOPSIS
    Retrieve a list of groups that a user is a member of
    
    .DESCRIPTION
    Retrieve a list of groups that a user is a member of
    
    .PARAMETER Id
    The Id of the user
    
    .PARAMETER Tenant
    The tenant of the user
    
    .PARAMETER GroupType
    Return either custom or sso groups
    
    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. By default this is 1.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAUserPrincipal -Id user@vsphere.local | Get-vRAUserPrincipalGroupMembership
    
    .EXAMPLE
    Get-vRAUserPrincipal -Id user@vsphere.local | Get-vRAUserPrincipalGroupMembership -GroupType SSO

    .EXAMPLE
    Get-vRAUserPrincipalGroupMembership -Id user@vsphere.local
    
    .EXAMPLE
    Get-vRAUserPrincipalGroupMembership -UserPrincipal user@vsphere.local

#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param (
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("PrincipalId")]
        [String[]]$Id,
        
        [parameter(Mandatory=$false)]  
        [ValidateNotNullOrEmpty()]
        [String]$Tenant = $Global:vRAConnection.Tenant,    
        
        [parameter(Mandatory=$false)]
        [ValidateSet("SSO","CUSTOM")]
        [String]$GroupType,   
          
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1
    )
    
    Begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    Process {
                
        try {
  
            foreach ($UserId in $Id){

                $URI = "/identity/api/tenants/$($Tenant)/principals/$($UserId)/groups?limit=$($Limit)&page=$($Page)"

                if ($PSBoundParameters.ContainsKey("GroupType")) {
                    $URI = $URI + "&groupType=$($GroupType)"
                }

                # --- Run vRA REST Request
                $Response = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                foreach ($Group in $Response.content) {
                    [PSCustomObject] @{
                        GroupType = $Group.groupType
                        Name = $Group.name
                        Domain = $Group.domain
                        Description = $Group.description
                        PrincipalId = "$($Group.principalId.name)@$($Group.principalId.domain)"
                    }
                }
            }
        }
        catch [Exception]{

            throw $_        
        }
    }
    
    End {

    }   
}

<#
    - Function: Get-vRAVersion
#>

function Get-vRAVersion {
<#
    .SYNOPSIS
    Retrieve vRA version information
    
    .DESCRIPTION
    Retrieve vRA version information

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAVersion
    
#>
[CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param ()
                
    try {
    
        $URI = "/identity/api/about"
        $Response = Invoke-vRARestMethod -URI $URI -Method GET

        [pscustomobject] @{

            BuildNumber = $Response.buildNumber
            BuildDate = $Response.buildDate
            ProductVersion = $Response.productVersion
            APIVersion = $Response.apiVersion
            ProductBuildNumber = $Response.productBuildNumber

        }

    }
    catch [Exception]{

        throw
    }
}

<#
    - Function: Invoke-vRATenantDirectorySync
#>

function Invoke-vRATenantDirectorySync {
<#
    .SYNOPSIS
    Sync an identity store
    
    .DESCRIPTION
    Sync an identity store
    
    .PARAMETER Id
    Specify the ID of a Tenant

    .PARAMETER Domain
    Specify the Domain of a Tenant Directory

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.
    
    .EXAMPLE
    Invoke-vRATenantDirectorySync -Id Tenant01 -Domain vrademo.local

    .EXAMPLE
    Invoke-vRATenantDirectorySync -Id Tenant01 -Domain vrademo.local,test.local
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Id,    
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Domain
    )

    # --- Test for vRA API version
    xRequires -Version 7.4
                
try {
        
    foreach ($TenantDomain in $Domain){

        $URI = "/identity/api/tenants/$($Id)/directories/$($TenantDomain)/sync "
        if ($PSCmdlet.ShouldProcess($Id)){

            # --- Run vRA REST Request
            Invoke-vRARestMethod -Method POST -URI $URI

            Get-vRATenantDirectoryStatus -Id $Id -Domain $Domain
        }
        # --- Run vRA REST Request
        Invoke-vRARestMethod -Method POST -URI $URI
        
        Get-vRATenantDirectoryStatus -Id $Id -Domain $Domain
		
    }
}
catch [Exception]{

    throw
}
}


<#
    - Function: New-vRABusinessGroup
#>

function New-vRABusinessGroup {
<#
    .SYNOPSIS
    Create a vRA Business Group
    
    .DESCRIPTION
    Create a vRA Business Group

    .PARAMETER TenantId
    Tenant ID
    
    .PARAMETER Name
    Business Group Name
    
    .PARAMETER Description
    Business Group Description

    .PARAMETER BusinessGroupManager
    Business Group Managers

    .PARAMETER SupportUser
    Business Group Support Users

    .PARAMETER SharedAccessUser
    Business Group Shared Access Users

    .PARAMETER User
    Business Group Users

    .PARAMETER MachinePrefixId
    Machine Prefix Id
    
    .PARAMETER SendManagerEmailsTo
    Send Manager Emails To

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRABusinessGroup -TenantId Tenant01 -Name BusinessGroup01 -Description "Business Group 01" -BusinessGroupManager "busgroupmgr01@vrademo.local","busgroupmgr02@vrademo.local" -SupportUser "supportusers@vrademo.local" `
     -User "basicusers@vrademo.local" -MachinePrefixId "87e99513-cbea-4589-8678-c84c5907bdf2" -SendManagerEmailsTo "busgroupmgr01@vrademo.local"
    
    .EXAMPLE
    New-vRABusinessGroup -TenantId Tenant01 -Name BusinessGroup02 -Description "Business Group 02" -BusinessGroupManager "busgroupmgr02@vrademo.local" -SharedAccessUser "sharedaccess01@vrademo.local" `
     -SendManagerEmailsTo "busgroupmgr02@vrademo.local"
    
    .EXAMPLE
    $JSON = @"
    {
      "name": "BusinessGroup01",
      "description": "Business Group 01",
      "subtenantRoles": [ {
        "name": "Business Group Manager",
        "scopeRoleRef" : "CSP_SUBTENANT_MANAGER",
        "principalId": [
          {
            "domain": "vrademo.local",
            "name": "busgroupmgr01"
          },
          {
            "domain": "vrademo.local",
            "name": "busgroupmgr02"
          }
        ]
      },
      {
      "name": "Basic User",
          "scopeRoleRef": "CSP_CONSUMER",
          "principalId": [
            {
              "domain": "vrademo.local",
              "name": "basicusers"
            }
          ] 
      } ,
      {
      "name": "Support User",
          "scopeRoleRef": "CSP_SUPPORT",
          "principalId": [
            {
              "domain": "vrademo.local",
              "name": "supportusers"
            }
          ] 
      } ],
      "extensionData": {
        "entries": [
          {
            "key": "iaas-machine-prefix",
            "value": {
              "type": "string",
              "value": "87e99513-cbea-4589-8678-c84c5907bdf2"
            }
          },
          {
            "key": "iaas-manager-emails",
            "value": {
              "type": "string",
              "value": "busgroupmgr01@vrademo.local"
            }
          }
        ]
      },
      "tenant": "Tenant01"
    }
    "@
    $JSON | New-vRABusinessGroup -TenantId Tenant01
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$TenantId = $Global:vRAConnection.Tenant,
    
    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$BusinessGroupManager,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$SupportUser,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$SharedAccessUser,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$User,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$MachinePrefixId,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$SendManagerEmailsTo,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0

        # --- Test for API 7.3 if SharedAccessUser parameter specified
        if ($PSBoundParameters.ContainsKey("SharedAccessUser")){

            if ($vRAConnection.APIVersion -lt 7.3){

                throw "vRA BusinessGroup Shared Access feature requires vRA version 7.3 or greater"
            }
        }
    }
    
    process {

        try {
    
        # --- Set Body for REST request depending on ParameterSet
        if ($PSBoundParameters.ContainsKey("JSON")){

            $Data = ($JSON | ConvertFrom-Json)
        
            $Body = $JSON
            $Name = $Data.name
        }
        else {
        
            $Body = @"
            {
              "name": "$($Name)",
              "description": "$($Description)",
              "subtenantRoles": [ {
                "name": "Business Group Manager",
                "scopeRoleRef" : "CSP_SUBTENANT_MANAGER",
                "principalId": [

                ]
              },
              {
              "name": "Basic User",
                  "scopeRoleRef": "CSP_CONSUMER",
                  "principalId": [

                  ] 
              } ,
              {
              "name": "Support User",
                  "scopeRoleRef": "CSP_SUPPORT",
                  "principalId": [

                  ] 
              } ],
              "extensionData": {
                "entries": [
                  {
                    "key": "iaas-manager-emails",
                    "value": {
                      "type": "string",
                      "value": "$($SendManagerEmailsTo)"
                    }
                  }
                ]
              },
              "tenant": "$($TenantId)"
            }
"@

            $BodySharedAccess = @"
            {
                "name": "com.vmware.csp.core.cafe.identity@csp.scoperole.sharedaccess.user.name",
                "scopeRoleRef": "CSP_CONSUMER_WITH_SHARED_ACCESS",
                "principalId": [
                
                ] 
            }
"@

            # --- If certain parameters are specified, ConvertFrom-Json, update, then ConvertTo-Json
            if ($PSBoundParameters.ContainsKey("BusinessGroupManager") -or $PSBoundParameters.ContainsKey("SupportUser") -or $PSBoundParameters.ContainsKey("SharedAccessUser") -or $PSBoundParameters.ContainsKey("User") -or $PSBoundParameters.ContainsKey("MachinePrefixId")){

                $JSONObject = $Body | ConvertFrom-Json
                
                # --- Add Shared Access feature from vRA 7.3
                if ($vRAConnection.APIVersion -ge 7.3){

                    $JSONObject.subtenantRoles += ($BodySharedAccess | ConvertFrom-Json)
                }

                if ($PSBoundParameters.ContainsKey("BusinessGroupManager")){

                    foreach ($Entity in $BusinessGroupManager){

                        $Domain = ($Entity -split "@")[1]
                        $Username = ($Entity -split "@")[0]
                
                        $Addition = @"
                        {
                            "domain": "$($Domain)",
                            "name": "$($Username)"
                        }
"@
                
                        $AdditionObject = $Addition | ConvertFrom-Json
                
                        $BusinessGroupManagerRole = $JSONObject.subtenantRoles | Where-Object {$_.Name -eq "Business Group Manager"}
                        $BusinessGroupManagerRole.principalId += $AdditionObject
                
                    }
                }

                if ($PSBoundParameters.ContainsKey("SupportUser")){

                    foreach ($Entity in $SupportUser){

                        $Domain = ($Entity -split "@")[1]
                        $Username = ($Entity -split "@")[0]
                
                        $Addition = @"
                        {
                            "domain": "$($Domain)",
                            "name": "$($Username)"
                        }
"@
                
                        $AdditionObject = $Addition | ConvertFrom-Json
                
                        $SupportUserRole = $JSONObject.subtenantRoles | Where-Object {$_.Name -eq "Support User"}
                        $SupportUserRole.principalId += $AdditionObject
                
                    }
                }

                if ($PSBoundParameters.ContainsKey("SharedAccessUser")){

                    foreach ($Entity in $SharedAccessUser){

                        $Domain = ($Entity -split "@")[1]
                        $Username = ($Entity -split "@")[0]
                
                        $Addition = @"
                        {
                            "domain": "$($Domain)",
                            "name": "$($Username)"
                        }
"@
                
                        $AdditionObject = $Addition | ConvertFrom-Json
                
                        $SupportUserRole = $JSONObject.subtenantRoles | Where-Object {$_.Name -eq "com.vmware.csp.core.cafe.identity@csp.scoperole.sharedaccess.user.name"}
                        $SupportUserRole.principalId += $AdditionObject
                
                    }
                }

                if ($PSBoundParameters.ContainsKey("User")){

                    foreach ($Entity in $User){

                        $Domain = ($Entity -split "@")[1]
                        $Username = ($Entity -split "@")[0]
                
                        $Addition = @"
                        {
                            "domain": "$($Domain)",
                            "name": "$($Username)"
                        }
"@
                
                        $AdditionObject = $Addition | ConvertFrom-Json
                
                        $UserRole = $JSONObject.subtenantRoles | Where-Object {$_.Name -eq "Basic User"}
                        $UserRole.principalId += $AdditionObject
                
                    }
                }
            
                if ($PSBoundParameters.ContainsKey("MachinePrefixId")){

                
                    $Addition = @"
                    {
                        "key": "iaas-machine-prefix",
                        "value": {
                          "type": "string",
                          "value": "$($MachinePrefixId)"
                        }
                   }
"@
                
                    $AdditionObject = $Addition | ConvertFrom-Json
                
                    $MachinePrefix = $JSONObject.extensionData
                    $MachinePrefix.entries += $AdditionObject
                

                }

                $Body = $JSONObject | ConvertTo-Json -Depth 5
            }  
        }

        if ($PSCmdlet.ShouldProcess($TenantId)){

            $URI = "/identity/api/tenants/$($TenantId)/subtenants"  

            # --- Run vRA REST Request
            Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

            # --- Output the Successful Result
            Get-vRABusinessGroup -TenantId $TenantId -Name $Name
        }

        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: New-vRAGroupPrincipal
#>

function New-vRAGroupPrincipal {
<#
    .SYNOPSIS
    Create a vRA custom group
    
    .DESCRIPTION
    Create a vRA Principal (user)

    .PARAMETER Tenant
    The tenant of the group
    
    .PARAMETER Name
    Group name
    
    .PARAMETER Description
    A description for the group
    
    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRAGroupPrincipal -Name TestGroup01 -Description "Test Group 01"
    
    .EXAMPLE
    $JSON = @"
        {
            "@type": "Group",
            "groupType": "CUSTOM",
            "name": "TestGroup01",
            "fqdn": "TestGroup01@Tenant",
            "domain": "Tenant",
            "description": "Test Group 01",
            "principalId": {
                "domain": "Tenant",
                "name": "TestGroup01"
            }
        }
"@    
   
#> 
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$false,ParameterSetName="Standard")] 
    [ValidateNotNullOrEmpty()]
    [String]$Tenant = $Global:vRAConnection.Tenant,
    
    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    
    )    

    begin {
    
    }
    
    process {

        try {
    
            # --- Set Body for REST request depending on ParameterSet
            if ($PSBoundParameters.ContainsKey("JSON")){
        
                $Body = $JSON
                $Tenant = ($JSON | ConvertFrom-Json).domain
                
            }
            else {

                $Body = @"
                    {
                        "@type": "Group",
                        "groupType": "CUSTOM",
                        "name": "$($Name)",
                        "fqdn": "$($Name)@$($Tenant)",
                        "domain": "$($Tenant)",
                        "description": "$($Description)",
                        "principalId": {
                            "domain": "$($Tenant)",
                            "name": "$($Name)"
                        }
                    }
"@

            }

            if ($PSCmdlet.ShouldProcess($Name)){

                $URI = "/identity/api/tenants/$($Tenant)/groups"  

                Write-Verbose -Message "Preparing POST to $($URI)"     

                # --- Run vRA REST Request           
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body | Out-Null
                
                Get-vRAGroupPrincipal -Tenant $Tenant -Id "$($Name)@$($Tenant)"
                
            }

        }
        catch [Exception]{

            throw
            
        }
        
    }
    end {
        
    }
        
}

<#
    - Function: New-vRATenant
#>

function New-vRATenant {
<#
    .SYNOPSIS
    Create a vRA Tenant
    
    .DESCRIPTION
    Create a vRA Tenant
    
    .PARAMETER Name
    Tenant Name
    
    .PARAMETER Description
    Tenant Description
    
    .PARAMETER URLName
    Tenant URL Name

    .PARAMETER ContactEmail
    Tenant Contact Email

    .PARAMETER ID
    Tenant ID

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRATenant -Name Tenant01 -Description "This is Tenant01" -URLName Tenant01 -ContactEmail admin.user@tenant01.local -ID Tenant01
    
    .EXAMPLE
    $JSON = @"
    {
      "name" : "Tenant02",
      "description" : "This is Tenant02",
      "urlName" : "Tenant02",
      "contactEmail" : "test.user@tenant02.local",
      "id" : "Tenant02",
      "defaultTenant" : false,
      "password" : ""
    }
    "@
    $JSON | New-vRATenant
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$URLName,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$ContactEmail,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$ID,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
    
    }
    
    process {
    
        # --- Set Body for REST request depending on ParameterSet
        if ($PSBoundParameters.ContainsKey("JSON")){
        
            $Data = ($JSON | ConvertFrom-Json)
            
            $Body = $JSON
            $ID =  $Data.id
            $Name = $Data.name     
        }
        else {
        
            $Body = @"
                {
                    "name" : "$($Name)",
                    "description" : "$($Description)",
                    "urlName" : "$($URLName)",
                    "contactEmail" : "$($ContactEmail)",
                    "id" : "$($ID)",
                    "defaultTenant" : false,
                    "password" : ""
                }
"@
        }   
           
        try {
            if ($PSCmdlet.ShouldProcess($Name)){

                $URI = "/identity/api/tenants/$($ID)"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRATenant -Id $ID
            }
            
        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: New-vRATenantDirectory
#>

function New-vRATenantDirectory {
<#
    .SYNOPSIS
    Create a vRA Tenant Directory
    
    .DESCRIPTION
    Create a vRA Tenant Directory

    .PARAMETER ID
    Tenant ID
    
    .PARAMETER Name
    Tenant Directory Name
    
    .PARAMETER Description
    Tenant Directory Description

    .PARAMETER Alias
    Tenant Directory Alias

    .PARAMETER Type
    Tenant Directory Type

    .PARAMETER Domain
    Tenant Directory Domain

    .PARAMETER UserNameDN
    DN of the Username to authenticate the Tenant Directory with
    
    .PARAMETER Password
    Password of the Username to authenticate the Tenant Directory with

    .PARAMETER URL
    Tenant Directory URL, e.g. ldap://dc01.vrademo.local:389

    .PARAMETER GroupBaseSearchDN
    Tenant Directory GroupBaseSearchDN

    .PARAMETER UserBaseSearchDN
    Tenant Directory UserBaseSearchDN

    .PARAMETER Subdomains
    Tenant Directory Subdomains

    .PARAMETER GroupBaseSearchDNs
    Tenant Directory GroupBaseSearchDNs

    .PARAMETER UserBaseSearchDNs
    Tenant Directory UserBaseSearchDNs

    .PARAMETER DomainAdminUserName
    Tenant Directory DomainAdminUserName

    .PARAMETER DomainAdminPassword
    Tenant Directory DomainAdminPassword

    .PARAMETER Certificate
    Tenant Directory Certificate

    .PARAMETER TrustAll
    Tenant Directory TrustAll

    .PARAMETER UseGlobalCatalog
    Tenant Directory UseGlobalCatalog

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String
    System.SecureString

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    $SecurePassword = ConvertTo-SecureString “P@ssword” -AsPlainText -Force
    New-vRATenantDirectory -ID Tenant01 -Name Tenant01 -Description "This is the Tenant01 Directory" -Type AD -Domain "vrademo.local" -UserNameDN "CN=vrasvc,OU=Service Accounts,OU=HQ,DC=vrademo,DC=local" `
      -Password $SecurePassword -URL "ldap://dc01.vrademo.local:389" -GroupBaseSearchDN "OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" -UserBaseSearchDN "OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" `
     -GroupBaseSearchDNs "OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" -UserBaseSearchDNs "OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" -TrustAll
    
    .EXAMPLE
    $JSON = @"
    {
      "name" : "Tenant01",
      "description" : "Tenant01",
      "alias" : "",
      "type" : "AD",
      "userNameDn" : "CN=vrasvc,OU=Service Accounts,OU=HQ,DC=vrademo,DC=local",
      "groupBaseSearchDn" : "OU=Tenant01,OU=Tenants,DC=vrademo,DC=local",
      "password" : "P@ssword!",
      "url" : "ldap://dc01.vrademo.local:389",
      "userBaseSearchDn" : "OU=Tenant01,OU=Tenants,DC=vrademo,DC=local",
      "domain" : "vrademo.local",
      "domainAdminUsername" : "",
      "domainAdminPassword" : "",
      "subdomains" : [ "" ],
      "groupBaseSearchDns" : [ "OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" ],
      "userBaseSearchDns" : [ "OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" ],
      "certificate" : "",
      "trustAll" : true,
      "useGlobalCatalog" : false
    }
    "@
    $JSON | New-vRATenantDirectory -ID Tenant01
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ID,
    
    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Alias,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Domain,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$UserNameDN,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [SecureString]$Password,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$URL,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$GroupBaseSearchDN,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$UserBaseSearchDN,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Subdomains,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$GroupBaseSearchDNs,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$UserBaseSearchDNs,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$DomainAdminUsername,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [SecureString]$DomainAdminPassword,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Certificate,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [Switch]$TrustAll,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [Switch]$UseGlobalCatalog,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {

        if ($PSBoundParameters.ContainsKey("Password")){

            $JSONPassword = (New-Object System.Management.Automation.PSCredential("username", $Password)).GetNetworkCredential().Password
        }
        if ($PSBoundParameters.ContainsKey("DomainAdminPassword")){

            $JSONDomainAdminPassword = (New-Object System.Management.Automation.PSCredential("username", $DomainAdminPassword)).GetNetworkCredential().Password
        }
        if ($PSBoundParameters.ContainsKey("GroupBaseSearchDNs")){

            $GroupBaseSearchDNsJSON = ($GroupBaseSearchDNs | ForEach-Object {'"' + $_ + '"'}) -join ','
        }
        if ($PSBoundParameters.ContainsKey("UserBaseSearchDNs")){

            $UserBaseSearchDNsJSON = ($UserBaseSearchDNs | ForEach-Object {'"' + $_ + '"'}) -join ','
        }
        if ($PSBoundParameters.ContainsKey("$TrustAll")){

            $TrustAllText = "true"
        }
        else {

            $TrustAllText = "false"
        }
        if ($PSBoundParameters.ContainsKey("$UseGlobalCatalog")){

            $UseGlobalCatalogText = "true"
        }
        else {

            $UseGlobalCatalogText = "false"
        }
    }
    
    process {
    
        # --- Set Body for REST request depending on ParameterSet
        if ($PSBoundParameters.ContainsKey("JSON")){

            $Data = ($JSON | ConvertFrom-Json)
        
            $Body = $JSON
            $Name = $Data.name  
        }
        else {
        
            $Body = @"
                {
                  "name" : "$($Name)",
                  "description" : "$($Description)",
                  "alias" : "$($Alias)",
                  "type" : "$($Type)",
                  "userNameDn" : "$($UserNameDN)",
                  "groupBaseSearchDn" : "$($GroupBaseSearchDN)",
                  "password" : "$($JSONPassword)",
                  "url" : "$($URL)",
                  "userBaseSearchDn" : "$($UserBaseSearchDN)",
                  "domain" : "$($Domain)",
                  "domainAdminUsername" : "$($DomainAdminUsername)",
                  "domainAdminPassword" : "$($JSONDomainAdminPassword)",
                  "subdomains" : [ "$($Subdomains)" ],
                  "groupBaseSearchDns" : [ $($GroupBaseSearchDNsJSON) ],
                  "userBaseSearchDns" : [ $($UserBaseSearchDNsJSON) ],
                  "certificate" : "$($Certificate)",
                  "trustAll" : $($TrustAllText),
                  "useGlobalCatalog" : $($UseGlobalCatalogText)
                }
"@
        }  
           
        try {
            if ($PSCmdlet.ShouldProcess($ID)){

                $URI = "/identity/api/tenants/$($ID)/directories"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRATenantDirectory -Id $ID | Where-Object {$_.Name -eq $Name}
            }
        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: New-vRAUserPrincipal
#>

function New-vRAUserPrincipal {
<#
    .SYNOPSIS
    Create a vRA local user principal
    
    .DESCRIPTION
    Create a vRA Principal (user)

    .PARAMETER Tenant
    The tenant of the user
    
    .PARAMETER PrincipalId
    Principal id in user@company.com format
    
    .PARAMETER FirstName
    First Name

    .PARAMETER LastName
    Last Name

    .PARAMETER EmailAddress
    Email Address

    .PARAMETER Description
    Users text description

    .PARAMETER Password
    Users password
    
    .PARAMETER Credential
    Credential object
    
    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.
    System.SecureString
    Management.Automation.PSCredential

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    $SecurePassword = ConvertTo-SecureString “P@ssword” -AsPlainText -Force
    New-vRAUserPrincipal -Tenant vsphere.local -FirstName "Test" -LastName "User" -EmailAddress "user@company.com" -Description "a description" -Password $SecurePassword -PrincipalId "user@vsphere.local"

    .EXAMPLE
    New-vRAUserPrincipal -Tenant vsphere.local -FirstName "Test" -LastName "User" -EmailAddress "user@company.com" -Description "a description" -Credential (Get-Credential)

    .EXAMPLE
    $JSON = @"
        {
        "locked": "false",
        "disabled": "false",
        "firstName": "Test",
        "lastName": "User",
        "emailAddress": "user@company.com",
        "description": "no",
        "password": "password123",
        "principalId": {
            "domain": "vsphere.local",
            "name": "user"
        },
        "tenantName": "Tenant01",
        "name": "Test User"
        }
   "@
   
   $JSON | New-vRAUserPrincipal
   
#> 
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Password")][OutputType('System.Management.Automation.PSObject')]

    Param (
    
    [parameter(Mandatory=$true,ParameterSetName="Password")]
    [ValidateNotNullOrEmpty()]
    [String]$PrincipalId,
    
    [parameter(Mandatory=$false,ParameterSetName="Credential")]
    [parameter(Mandatory=$false,ParameterSetName="Password")]    
    [ValidateNotNullOrEmpty()]
    [String]$Tenant = $Global:vRAConnection.Tenant,    
    
    [parameter(Mandatory=$true,ParameterSetName="Credential")]
    [parameter(Mandatory=$true,ParameterSetName="Password")] 
    [ValidateNotNullOrEmpty()]
    [String]$FirstName,

    [parameter(Mandatory=$true,ParameterSetName="Credential")]
    [parameter(Mandatory=$true,ParameterSetName="Password")] 
    [ValidateNotNullOrEmpty()]
    [String]$LastName,

    [parameter(Mandatory=$true,ParameterSetName="Credential")]
    [parameter(Mandatory=$true,ParameterSetName="Password")] 
    [ValidateNotNullOrEmpty()]
    [String]$EmailAddress,

    [parameter(Mandatory=$false,ParameterSetName="Credential")]
    [parameter(Mandatory=$false,ParameterSetName="Password")] 
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$true,ParameterSetName="Password")]
    [ValidateNotNullOrEmpty()]
    [SecureString]$Password,
    
    [Parameter(Mandatory=$true,ParameterSetName="Credential")]
	[ValidateNotNullOrEmpty()]
	[Management.Automation.PSCredential]$Credential, 

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    
    )    

    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    process {

        try {
    
            # --- Set Body for REST request depending on ParameterSet
            if ($PSBoundParameters.ContainsKey("JSON")){
        
                $Body = $JSON
                $Tenant = ($JSON | ConvertFrom-Json).tenantName
                
            }
            else {
            
                if ($PSBoundParameters.ContainsKey("Credential")){

                    $PrincipalId = $Credential.UserName
                    $JSONPassword = $Credential.GetNetworkCredential().Password
                    
                }

                if ($PSBoundParameters.ContainsKey("Password")) {

                    $JSONPassword = (New-Object System.Management.Automation.PSCredential("username", $Password)).GetNetworkCredential().Password

                }
                
                $Name = ($PrincipalId -split "@")[0]
                $Domain = ($PrincipalId -split "@")[1]                                  
                            
                $Body = @"
                {
                    "locked" : "false",
                    "disabled" : "false",
                    "firstName" : "$($FirstName)",
                    "lastName" : "$($LastName)",
                    "emailAddress" : "$($EmailAddress)",
                    "description" : "$($Description)",
                    "password" : "$($JSONPassword)",
                    "principalId": { "domain": "$($Domain)", "name": "$($Name)"} ,
                    "tenantName" : "$($Tenant)",
                    "name" : "$($FirstName) $($LastName)"
                }
"@

            }

            if ($PSCmdlet.ShouldProcess($PrincipalId)){

                $URI = "/identity/api/tenants/$($Tenant)/principals"  

                Write-Verbose -Message "Preparing POST to $($URI)"     

                # --- Run vRA REST Request           
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body | Out-Null
                
                Get-vRAUserPrincipal -Tenant $Tenant -Id $PrincipalId
                
            }

        }
        catch [Exception]{

            throw
            
        }
        
    }
    end {
        
    }
    
}

<#
    - Function: Remove-vRABusinessGroup
#>

function Remove-vRABusinessGroup {
<#
    .SYNOPSIS
    Remove a vRA Business Group
    
    .DESCRIPTION
    Remove a vRA Business Group
    
    .PARAMETER TenantId
    Tenant Id

    .PARAMETER Id
    Business Group Id

    .PARAMETER Name
    Business Group Name

    .INPUTS
    System.String.

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRABusinessGroup -TenantId Tenant01 -Id "f8e0d99e-c567-4031-99cb-d8410c841ed7"

    .EXAMPLE
    Remove-vRABusinessGroup -TenantId Tenant01 -Name "BusinessGroup01","BusinessGroup02"
    
    .EXAMPLE
    Get-vRABusinessGroup -TenantId Tenant01 -Name BusinessGroup01 | Remove-vRABusinessGroup -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="Id")]

    Param (

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("Tenant")]
    [String]$TenantId,

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="Id")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [parameter(Mandatory=$true,ParameterSetName="Name")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name
    )    

    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    process {    

        switch ($PsCmdlet.ParameterSetName) 
        { 
            "Id"  {

                foreach ($BusinessGroupId in $Id){
                
                    try {
                        if ($PSCmdlet.ShouldProcess($BusinessGroupId)){

                            $URI = "/identity/api/tenants/$($TenantId)/subtenants/$($id)"  

                            # --- Run vRA REST Request
                            $null = Invoke-vRARestMethod -Method DELETE -URI $URI
                        }
                    }
                    catch [Exception]{

                        throw
                    } 
                }                
            
                break
            }

            "Name"  {

                foreach ($BusinessGroupName in $Name){
                
                    try {
                        if ($PSCmdlet.ShouldProcess($BusinessGroupName)){

                            # --- Find the Business Group
                            $BusinessGroup = Get-vRABusinessGroup -TenantId $TenantId -Name $BusinessGroupName
                            $Id = $BusinessGroup.ID

                            $URI = "/identity/api/tenants/$($TenantId)/subtenants/$($Id)"  

                            # --- Run vRA REST Request
                            $null = Invoke-vRARestMethod -Method DELETE -URI $URI
                        }
                    }
                    catch [Exception]{

                        throw
                    } 
                }
                
                break
            } 
        }             
    }
    end {
        
    }
}

<#
    - Function: Remove-vRAGroupPrincipal
#>

function Remove-vRAGroupPrincipal {
<#
    .SYNOPSIS
    Remove a vRA custom group
    
    .DESCRIPTION
    Remove a vRA custom group
    
    .PARAMETER Id
    The principal id of the custom group
    
    .PARAMETER Tenant
    The tenant of the group

    .INPUTS
    System.String.

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRAGroupPrincipal -PrincipalId Group@Tenant
    
    .EXAMPLE
    Get-vRAGroupPrincipal -Id Group@Tenant | Remove-vRAGroupPrincipal
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("PrincipalId")]
    [String[]]$Id,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Tenant = $Global:vRAConnection.Tenant    
    
    )    

    begin {
    
    }
    
    process {    
            
        foreach ($GroupId in $Id){
                
            try {
                
                if ($PSCmdlet.ShouldProcess($GroupId)){
                   
                    $URI = "/identity/api/tenants/$($Tenant)/groups/$($GroupId)"  
                    
                    Write-Verbose -Message "Preparing DELETE to $($URI)"                        

                    # --- Run vRA REST Request                    
                    Invoke-vRARestMethod -Method DELETE -URI $URI | Out-Null
                    
                }
                
            }
            catch [Exception]{

                throw
                
            } 
        }
    }
    end {
        
    }
}

<#
    - Function: Remove-vRAPrincipalFromTenantRole
#>

function Remove-vRAPrincipalFromTenantRole {
<#
    .SYNOPSIS
    Remove a vRA Principal from a Tenant Role
    
    .DESCRIPTION
    Remove a vRA Principal from a Tenant Role
    
    .PARAMETER TenantId
    Specify the Tenant Id

    .PARAMETER PrincipalId
    Specify the Principal Id

    .PARAMETER RoleId
    Specify the Role Id

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.
    
    .EXAMPLE
    Remove-vRAPrincipalFromTenantRole -TenantId Tenant01 -PrincipalId Tenantadmin@vrademo.local -RoleId CSP_TENANT_ADMIN

    .EXAMPLE
    Get-vRAUserPrincipal -UserName Tenantadmin@vrademo.local | Remove-vRAPrincipalFromTenantRole -TenantId Tenant01 -RoleId CSP_TENANT_ADMIN
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$TenantId,
    
    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$PrincipalId,  
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$RoleId
    )

begin {

}

process {

    foreach ($Principal in $PrincipalId){
                
        try {

            if ($PSCmdlet.ShouldProcess($Principal)){
     
                $URI = "/identity/api/authorization/tenants/$($TenantId)/principals/$($Principal)/roles/$($Roleid)"

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
            }
        }
        catch [Exception]{

            throw
        }
    }
}

end {

}
}

<#
    - Function: Remove-vRATenant
#>

function Remove-vRATenant {
<#
    .SYNOPSIS
    Remove a vRA Tenant
    
    .DESCRIPTION
    Remove a vRA Tenant
    
    .PARAMETER Id
    Tenant ID

    .INPUTS
    System.String.

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRATenant -Id Tenant02
    
    .EXAMPLE
    Get-vRATenant -Id Tenant02 | Remove-vRATenant -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id
    )    

    begin {
    
    }
    
    process {    
            
        foreach ($TenantId in $Id){
                
            try {
                if ($PSCmdlet.ShouldProcess($Id)){

                    $URI = "/identity/api/tenants/$($ID)"  

                    # --- Run vRA REST Request
                    Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
                }
            }
            catch [Exception]{

                throw
            } 
        }
    }
    end {
        
    }
}

<#
    - Function: Remove-vRATenantDirectory
#>

function Remove-vRATenantDirectory {
<#
    .SYNOPSIS
    Remove a vRA Tenant Directory
    
    .DESCRIPTION
    Remove a vRA Tenant Directory
    
    .PARAMETER Id
    Tenant Id

    .PARAMETER Domain
    Tenant Directory Domain

    .INPUTS
    System.String.

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRATenantDirectory -Id Tenant01 -Domain vrademo.local
    
    .EXAMPLE
    $Id = "Tenant01"
    Get-vRATenantDirectory -Id $Id | Remove-vRATenantDirectory -Id $Id -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Id,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Domain
    )    

    begin {
    
    }
    
    process {    
            
        foreach ($TenantId in $Id){
                
            try {
                if ($PSCmdlet.ShouldProcess($Id)){

                    $URI = "/identity/api/tenants/$($ID)/directories/$($Domain)"  

                    # --- Run vRA REST Request
                    Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
                }
            }
            catch [Exception]{

                throw
            } 
        }
    }
    end {
        
    }
}

<#
    - Function: Remove-vRAUserPrincipal
#>

function Remove-vRAUserPrincipal {
<#
    .SYNOPSIS
    Remove a vRA local user principal
    
    .DESCRIPTION
    Remove a vRA local user principal
    
    .PARAMETER Id
    The principal id of the user
    
    .PARAMETER Tenant
    The tenant of the user

    .INPUTS
    System.String.

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRAUserPrincipal -PrincipalId user@vsphere.local
    
    .EXAMPLE
    Get-vRAUserPrincipal -Id user@vsphere.local | Remove-vRAUserPrincipal
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [Alias("PrincipalId")]
    [String[]]$Id,
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Tenant = $Global:vRAConnection.Tenant      
    
    )    

    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    process {    
            
        foreach ($UserId in $Id){
                
            try {
                
                if ($PSCmdlet.ShouldProcess($UserId)){

                    $URI = "/identity/api/tenants/$($Tenant)/principals/$($UserId)"  
                    
                    Write-Verbose -Message "Preparing DELETE to $($URI)"                        

                    # --- Run vRA REST Request                    
                    Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
                    
                }
                
            }
            catch [Exception]{

                throw
                
            } 
        }
    }
    end {
        
    }
}

<#
    - Function: Set-vRABusinessGroup
#>

function Set-vRABusinessGroup {
<#
    .SYNOPSIS
    Update a vRA Business Group
    
    .DESCRIPTION
    Update a vRA Business Group
    
    .PARAMETER TenantId
    Tenant ID

    .PARAMETER Id
    Business Group ID
    
    .PARAMETER Name
    Business Group Name
    
    .PARAMETER Description
    Business Group Description

    .PARAMETER MachinePrefixId
    Machine Prefix Id
    
    .PARAMETER SendManagerEmailsTo
    Send Manager Emails To

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Set-vRABusinessGroup -TenantId Tenant01 -Id "f8e0d99e-c567-4031-99cb-d8410c841ed7" -Name BusinessGroup01 -Description "Business Group 01" -MachinePrefixId "87e99513-cbea-4589-8678-c84c5907bdf2" -SendManagerEmailsTo "busgroupmgr01@vrademo.local"
    
    .EXAMPLE
    $JSON = @"
    {
        "id": "f8e0d99e-c567-4031-99cb-d8410c841ed7",
        "name": "BusinessGroup01",
        "description": "Business Group 01",
        "extensionData": {
        "entries": [
            {
            "key": "iaas-machine-prefix",
            "value": {
                "type": "string",
                "value": "87e99513-cbea-4589-8678-c84c5907bdf2"
            }
            },
            {
            "key": "iaas-manager-emails",
            "value": {
                "type": "string",
                "value": "busgroupmgr01@vrademo.local"
            }
            }
        ]
        },
        "tenant": "Tenant01"
    }
    "@
    $JSON | Set-vRABusinessGroup -ID Tenant01 -Id "f8e0d99e-c567-4031-99cb-d8410c841ed7"
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$TenantId,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ID,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$MachinePrefixId,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$SendManagerEmailsTo,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    process {
    
        # --- Set Body for REST request depending on ParameterSet
        if ($PSBoundParameters.ContainsKey("JSON")){
        
            $Data = ($JSON | ConvertFrom-Json)
            
            $Body = $JSON
            $Name = $Data.name
            
            # --- Check for existing Business Group
            try {

                $BusinessGroup = Get-vRABusinessGroup -TenantId $TenantId | Where-Object {$_.id -eq $ID}
            }
            catch [Exception]{

                throw
            }   
        }
        else {

            # --- Check for existing Business Group
            try {

                $BusinessGroup = Get-vRABusinessGroup -TenantId $TenantId | Where-Object {$_.id -eq $ID}
            }
            catch [Exception]{

                throw
            }

            
            # --- Set any properties not specified at function invocation
            if (-not($PSBoundParameters.ContainsKey("Name"))){

                if ($BusinessGroup.Name){

                    $Name = $BusinessGroup.Name
                }
            }
            if (-not($PSBoundParameters.ContainsKey("Description"))){

                if ($BusinessGroup.Description){

                    $Description = $BusinessGroup.Description
                }
            }
            if (-not($PSBoundParameters.ContainsKey("SendManagerEmailsTo"))){

                if ($BusinessGroup.ExtensionData.entries | Where-Object {$_.key -eq "iaas-manager-emails"}){

                    $SendManagerEmailsTo = ($BusinessGroup.ExtensionData.entries | Where-Object {$_.key -eq "iaas-manager-emails"}).value.value
                }
            }        
           if (-not($PSBoundParameters.ContainsKey("MachinePrefixId"))){

                if ($BusinessGroup.ExtensionData.entries | Where-Object {$_.key -eq "iaas-machine-prefix"}){

                    $MachinePrefixId = ($BusinessGroup.ExtensionData.entries | Where-Object {$_.key -eq "iaas-machine-prefix"}).value.value
                }

                if ($MachinePrefixId){
                $Body = @"
                {
                    "id": "$($ID)",
                    "name": "$($Name)",
                    "description": "$($Description)",
                    "extensionData": {
                    "entries": [
                        {
                        "key": "iaas-machine-prefix",
                        "value": {
                            "type": "string",
                            "value": "$($MachinePrefixId)"
                        }
                        },
                        {
                        "key": "iaas-manager-emails",
                        "value": {
                            "type": "string",
                            "value": "$($SendManagerEmailsTo)"
                        }
                        }
                    ]
                    },
                    "tenant": "$($TenantId)"
                }
"@
                }
                else {

                    $Body = @"
                    {
                        "id": "$($ID)",
                        "name": "$($Name)",
                        "description": "$($Description)",
                        "extensionData": {
                        "entries": [
                            {
                            "key": "iaas-manager-emails",
                            "value": {
                                "type": "string",
                                "value": "$($SendManagerEmailsTo)"
                            }
                            }
                        ]
                        },
                        "tenant": "$($TenantId)"
                    }
"@

                }

            }        

            else {

                $Body = @"
                {
                    "id": "$($ID)",
                    "name": "$($Name)",
                    "description": "$($Description)",
                    "extensionData": {
                    "entries": [
                        {
                        "key": "iaas-machine-prefix",
                        "value": {
                            "type": "string",
                            "value": "$($MachinePrefixId)"
                        }
                        },
                        {
                        "key": "iaas-manager-emails",
                        "value": {
                            "type": "string",
                            "value": "$($SendManagerEmailsTo)"
                        }
                        }
                    ]
                    },
                    "tenant": "$($TenantId)"
                }
"@

            }

            }    
        
        # --- Update existing Business Group 
        try {
            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/identity/api/tenants/$($TenantId)/subtenants/$($Id)"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRABusinessGroup -TenantId $TenantId | Where-Object {$_.id -eq $ID}
            }
        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: Set-vRAStorageReservationPolicy
#>

function Set-vRAStorageReservationPolicy {
<#
    .SYNOPSIS
    Update a vRA Storage Reservation Policy
    
    .DESCRIPTION
    Update a vRA Storage Reservation Policy

    .PARAMETER Id
    Storage Reservation Policy Id
    
    .PARAMETER Name
    Storage Reservation Policy Name

    .PARAMETER NewName
    Storage Reservation Policy NewName
    
    .PARAMETER Description
    Storage Reservation Policy Description

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Set-vRAStorageReservationPolicy -Id "34ae1d6c-9972-4736-acdb-7ee109ad1dbd" -NewName "NewName" -Description "This is the New Name"

    .EXAMPLE
    Set-vRAStorageReservationPolicy -Name StorageReservationPolicy01 -NewName "NewName" -Description "This is the New Name"
    
    .EXAMPLE
    $JSON = @"
    {
      "id": "34ae1d6c-9972-4736-acdb-7ee109ad1dbd",
      "name": "StorageReservationPolicy01",
      "description": "This is Storage Reservation Policy 01",
      "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.Storage"
    }
    "@
    $JSON | Set-vRAStorageReservationPolicy -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="ById")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String]$Id,

    [parameter(Mandatory=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [parameter(Mandatory=$false,ParameterSetName="ByName")]
    [parameter(Mandatory=$false,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String]$NewName,
    
    [parameter(Mandatory=$false,ParameterSetName="ByName")]
    [parameter(Mandatory=$false,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
    
    }
    
    process {

        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  {                
            
            # --- Check for existing Storage Reservation Policy
            try {

                $StorageReservationPolicy = Get-vRAStorageReservationPolicy -Id $Id
                
                if (-not $StorageReservationPolicy){

                    throw "Storage Reservation Policy with id $($Id) does not exist"
                }
            }
            catch [Exception]{

                throw
            }
            
            # --- Set any properties not specified at function invocation
            if (-not($PSBoundParameters.ContainsKey("NewName"))){

                if ($StorageReservationPolicy.Name){

                    $Name = $StorageReservationPolicy.Name
                }
            }
            else {

                $Name = $NewName
            }
            if (-not($PSBoundParameters.ContainsKey("Description"))){

                if ($StorageReservationPolicy.Description){

                    $Description = $StorageReservationPolicy.Description
                }
            }
        
            $Body = @"
                {
                    "id": "$($Id)",
                    "name": "$($Name)",
                    "description": "$($Description)",
                    "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.Storage"
                }
"@                                
            # --- Update existing Storage Reservation Policy
            try {
                if ($PSCmdlet.ShouldProcess($Id)){

                    $URI = "/reservation-service/api/reservations/policies/$($Id)"  

                    # --- Run vRA REST Request
                    $null = Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body

                    # --- Output the Successful Result
                    Get-vRAStorageReservationPolicy -Id $Id
                }
            }
            catch [Exception]{

                throw
            }
                break
            }

            "ByName"  {                

            # --- Check for existing Storage Reservation Policy
            try {

                $StorageReservationPolicy = Get-vRAStorageReservationPolicy -Name $Name

                if (-not $StorageReservationPolicy){

                    throw "Storage Reservation Policy with name $($Name) does not exist"
                }

                $Id = $StorageReservationPolicy.Id
            }
            catch [Exception]{

                throw
            }
            
            # --- Set any properties not specified at function invocation
            if (-not($PSBoundParameters.ContainsKey("NewName"))){

                if ($StorageReservationPolicy.Name){

                    $Name = $StorageReservationPolicy.Name
                }
            }
            else {

                $Name = $NewName
            }
            if (-not($PSBoundParameters.ContainsKey("Description"))){

                if ($StorageReservationPolicy.Description){

                    $Description = $StorageReservationPolicy.Description
                }
            }
        
            $Body = @"
                {
                    "id": "$($Id)",
                    "name": "$($Name)",
                    "description": "$($Description)",
                    "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.Storage"
                }
"@                                
            # --- Update existing Storage Reservation Policy
            try {
                if ($PSCmdlet.ShouldProcess($Name)){

                    $URI = "/reservation-service/api/reservations/policies/$($Id)"  

                    # --- Run vRA REST Request
                    $null = Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body

                    # --- Output the Successful Result
                    Get-vRAStorageReservationPolicy -Name $Name
                }
            }
            catch [Exception]{

                throw
            }

                
                break
            }

            "JSON"  {

                $Data = ($JSON | ConvertFrom-Json)
            
                $Body = $JSON
                $ID =  $Data.id
                #$Name = $Data.name
            
                # --- Check for existing Storage Reservation Policy
                try {

                    $StorageReservationPolicy = Get-vRAStorageReservationPolicy -Id $Id
                
                    if (-not $StorageReservationPolicy){

                        throw "Storage Reservation Policy with id $($Id) does not exist"
                    }
                }
                catch [Exception]{

                    throw
                }
                try {
                    if ($PSCmdlet.ShouldProcess($Id)){

                        $URI = "/reservation-service/api/reservations/policies/$($Id)"  

                        # --- Run vRA REST Request
                        Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                        # --- Output the Successful Result
                        Get-vRAStorageReservationPolicy -Id $Id
                    }
                }
                catch [Exception]{

                    throw
                }
                
                break
            }
        }
    

    }
    end {
        
    }
}

<#
    - Function: Set-vRATenant
#>

function Set-vRATenant {
<#
    .SYNOPSIS
    Update a vRA Tenant
    
    .DESCRIPTION
    Update a vRA Tenant
    
    .PARAMETER Name
    Tenant Name
    
    .PARAMETER Description
    Tenant Description

    .PARAMETER ContactEmail
    Tenant Contact Email

    .PARAMETER ID
    Tenant ID

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Set-vRATenant -Name Tenant01 -Description "This is the updated description" -ID Tenant01
    
    .EXAMPLE
    $JSON = @"
    {
      "name" : "Tenant02",
      "description" : "This is the updated description for Tenant02",
      "urlName" : "Tenant02",
      "contactEmail" : "test.user@tenant02.local",
      "id" : "Tenant02",
      "defaultTenant" : false,
      "password" : ""
    }
    "@
    $JSON | Set-vRATenant
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$ContactEmail,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$ID,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
    
    }
    
    process {
    
        # --- Set Body for REST request depending on ParameterSet
        if ($PSBoundParameters.ContainsKey("JSON")){
        
            $Data = ($JSON | ConvertFrom-Json)
            
            $Body = $JSON
            $ID =  $Data.id
            $Name = $Data.name
            
            # --- Check for existing Tenant
            try {

                $Tenant = Get-vRATenant -Id $ID
            }
            catch [Exception]{

                throw
            }   
        }
        else {

            # --- Check for existing Tenant
            try {

                $Tenant = Get-vRATenant -Id $ID
            }
            catch [Exception]{

                throw
            }

            
            # --- Set any properties not specified at function invocation
            if (-not($PSBoundParameters.ContainsKey("Description"))){

                if ($Tenant.Description){

                    $Description = $Tenant.Description
                }
            }
            if (-not($PSBoundParameters.ContainsKey("ContactEmail"))){

                if ($Tenant.ContactEmail){

                    $ContactEmail = $Tenant.ContactEmail
                }
            }
        
            $Body = @"
                {
                    "name" : "$($Name)",
                    "description" : "$($Description)",
                    "urlName" : "$($Tenant.URLName)",
                    "contactEmail" : "$($ContactEmail)",
                    "id" : "$($ID)",
                    "defaultTenant" : false,
                    "password" : ""
                }
"@
        }
        
        # --- Update existing Tenant 
        try {
            if ($PSCmdlet.ShouldProcess($Name)){

                $URI = "/identity/api/tenants/$($ID)"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body -Verbose:$VerbosePreferences | Out-Null

                # --- Output the Successful Result
                Get-vRATenant -Id $ID
            }
        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: Set-vRATenantDirectory
#>

function Set-vRATenantDirectory {
<#
    .SYNOPSIS
    Update a vRA Tenant Directory
    
    .DESCRIPTION
    Update a vRA Tenant Directory
    
    .PARAMETER ID
    Tenant ID
    
    .PARAMETER Name
    Tenant Directory Name

    .PARAMETER Description
    A description for the directory

    .PARAMETER Alias
    Tenant Directory Alias

    .PARAMETER Type
    Tenant Directory Type

    .PARAMETER Domain
    Tenant Directory Domain

    .PARAMETER UserNameDN
    DN of the Username to authenticate the Tenant Directory with
    
    .PARAMETER Password
    Password of the Username to authenticate the Tenant Directory with

    .PARAMETER URL
    Tenant Directory URL, e.g. ldap://dc01.vrademo.local:389

    .PARAMETER GroupBaseSearchDN
    Tenant Directory GroupBaseSearchDN

    .PARAMETER UserBaseSearchDN
    Tenant Directory UserBaseSearchDN

    .PARAMETER Subdomains
    Tenant Directory Subdomains

    .PARAMETER GroupBaseSearchDNs
    Tenant Directory GroupBaseSearchDNs

    .PARAMETER UserBaseSearchDNs
    Tenant Directory UserBaseSearchDNs

    .PARAMETER DomainAdminUserName
    Tenant Directory DomainAdminUserName

    .PARAMETER DomainAdminPassword
    Tenant Directory DomainAdminPassword

    .PARAMETER Certificate
    Tenant Directory Certificate

    .PARAMETER TrustAll
    Tenant Directory TrustAll

    .PARAMETER UseGlobalCatalog
    Tenant Directory UseGlobalCatalog

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String
    System.SecureString

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    $SecurePassword = ConvertTo-SecureString “P@ssword” -AsPlainText -Force
    Set-vRATenantDirectory -ID Tenant01 -Domain vrademo.local -GroupBaseSearchDNs "OU=Groups,OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" -userBaseSearchDNs "OU=Users,OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" -Password $SecurePassword -Confirm:$false
    
    .EXAMPLE
    $JSON = @"
    {
      "name" : "Tenant01",
      "description" : "Tenant01",
      "alias" : "",
      "type" : "AD",
      "userNameDn" : "CN=vrasvc,OU=Service Accounts,OU=HQ,DC=vrademo,DC=local",
      "groupBaseSearchDn" : "OU=Groups,OU=Tenant01,OU=Tenants,DC=vrademo,DC=local",
      "password" : "P@ssword!",
      "url" : "ldap://dc01.vrademo.local:389",
      "userBaseSearchDn" : "OU=Users,OU=Tenant01,OU=Tenants,DC=vrademo,DC=local",
      "domain" : "vrademo.local",
      "domainAdminUsername" : "",
      "domainAdminPassword" : "",
      "subdomains" : [ "" ],
      "groupBaseSearchDns" : [ "OU=Groups,OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" ],
      "userBaseSearchDns" : [ "OU=Users,OU=Tenant01,OU=Tenants,DC=vrademo,DC=local" ],
      "certificate" : "",
      "trustAll" : true,
      "useGlobalCatalog" : false
    }
    "@
    $JSON | Set-vRATenantDirectory -ID Tenant01 -Domain vrademo.local
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ID,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Alias,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Domain,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$UserNameDN,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [SecureString]$Password,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$URL,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$GroupBaseSearchDN,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$UserBaseSearchDN,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Subdomains,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$GroupBaseSearchDNs,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$UserBaseSearchDNs,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$DomainAdminUsername,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [SecureString]$DomainAdminPassword,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Certificate,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [Switch]$TrustAll,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [Switch]$UseGlobalCatalog,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0

        if ($PSBoundParameters.ContainsKey("Password")){

            $JSONPassword = (New-Object System.Management.Automation.PSCredential("username", $Password)).GetNetworkCredential().Password
        }
        if ($PSBoundParameters.ContainsKey("DomainAdminPassword")){

            $JSONDomainAdminPassword = (New-Object System.Management.Automation.PSCredential("username", $DomainAdminPassword)).GetNetworkCredential().Password
        }
        if ($PSBoundParameters.ContainsKey("GroupBaseSearchDNs")){

            $GroupBaseSearchDNsJSON = ($GroupBaseSearchDNs | ForEach-Object {'"' + $_ + '"'}) -join ','
        }
        if ($PSBoundParameters.ContainsKey("UserBaseSearchDNs")){

            $UserBaseSearchDNsJSON = ($UserBaseSearchDNs | ForEach-Object {'"' + $_ + '"'}) -join ','
        }
        if ($PSBoundParameters.ContainsKey("$TrustAll")){

            $TrustAllText = "true"
        }
        else {

            $TrustAllText = "false"
        }
        if ($PSBoundParameters.ContainsKey("$UseGlobalCatalog")){

            $UseGlobalCatalogText = "true"
        }
        else {

            $UseGlobalCatalogText = "false"
        }
    }
    
    process {
    
        # --- Set Body for REST request depending on ParameterSet
        if ($PSBoundParameters.ContainsKey("JSON")){
        
            $Data = ($JSON | ConvertFrom-Json)
            
            $Body = $JSON
            $Name = $Data.name
            
            # --- Check for existing Tenant
            try {

                $TenantDirectory = Get-vRATenantDirectory -Id $ID | Where-Object {$_.Domain -eq $Domain}
            }
            catch [Exception]{

                throw
            }   
        }
        else {

            # --- Check for existing Tenant
            try {

                $TenantDirectory = Get-vRATenantDirectory -Id $ID | Where-Object {$_.Domain -eq $Domain}
            }
            catch [Exception]{

                throw
            }

            
            # --- Set any properties not specified at function invocation
            if (-not($PSBoundParameters.ContainsKey("Name"))){

                if ($TenantDirectory.Name){

                    $Name = $TenantDirectory.Name
                }
            }            
            if (-not($PSBoundParameters.ContainsKey("Description"))){

                if ($TenantDirectory.Description){

                    $Description = $TenantDirectory.Description
                }
            }
            if (-not($PSBoundParameters.ContainsKey("Alias"))){

                if ($TenantDirectory.Alias){

                    $Alias = $TenantDirectory.Alias
                }
            }
            if (-not($PSBoundParameters.ContainsKey("Type"))){

                if ($TenantDirectory.Type){

                    $Type = $TenantDirectory.Type
                }
            }
            if (-not($PSBoundParameters.ContainsKey("UserNameDN"))){

                if ($TenantDirectory.UserNameDN){

                    $UserNameDN = $TenantDirectory.UserNameDN
                }
            }
            if (-not($PSBoundParameters.ContainsKey("Password"))){

                if ($TenantDirectory.Password){

                    $JSONPassword = $TenantDirectory.Password
                }
            }
            if (-not($PSBoundParameters.ContainsKey("URL"))){

                if ($TenantDirectory.URL){

                    $URL = $TenantDirectory.URL
                }
            }
            if (-not($PSBoundParameters.ContainsKey("GroupBaseSearchDN"))){

                if ($TenantDirectory.GroupBaseSearchDN){

                    $GroupBaseSearchDN = $TenantDirectory.GroupBaseSearchDN
                }
            }
            if (-not($PSBoundParameters.ContainsKey("UserBaseSearchDN"))){

                if ($TenantDirectory.UserBaseSearchDN){

                    $UserBaseSearchDN = $TenantDirectory.UserBaseSearchDN
                }
            }
            if (-not($PSBoundParameters.ContainsKey("Subdomains"))){

                if ($TenantDirectory.Subdomains){

                    $Subdomains = $TenantDirectory.Subdomains
                }
            }
            if (-not($PSBoundParameters.ContainsKey("GroupBaseSearchDNs"))){

               if ($TenantDirectory.GroupBaseSearchDNs){

                    $GroupBaseSearchDNs = $TenantDirectory.GroupBaseSearchDNs
                    $GroupBaseSearchDNsJSON = ($GroupBaseSearchDNs | ForEach-Object {'"' + $_ + '"'}) -join ','
                }
            }
            if (-not($PSBoundParameters.ContainsKey("UserBaseSearchDNs"))){

                if ($TenantDirectory.UserBaseSearchDNs){

                    $UserBaseSearchDNs = $TenantDirectory.UserBaseSearchDNs
                    $UserBaseSearchDNsJSON = ($UserBaseSearchDNs | ForEach-Object {'"' + $_ + '"'}) -join ','
                }
            }
            if (-not($PSBoundParameters.ContainsKey("DomainAdminUsername"))){

                if ($TenantDirectory.DomainAdminUsername){

                    $DomainAdminUsername = $TenantDirectory.DomainAdminUsername
                }
            }
            if (-not($PSBoundParameters.ContainsKey("DomainAdminPassword"))){

                if ($TenantDirectory.DomainAdminPassword){

                    $JSONDomainAdminPassword = $TenantDirectory.DomainAdminPassword
                }
            }
            if (-not($PSBoundParameters.ContainsKey("Certificate"))){

                if ($TenantDirectory.Certificate){

                    $Certificate = $TenantDirectory.Certificate
                }
            }
            if (-not($PSBoundParameters.ContainsKey("TrustAll"))){

                if ($TenantDirectory.TrustAll){

                    $TrustAll = $TenantDirectory.TrustAll
                }
            }
            if (-not($PSBoundParameters.ContainsKey("UseGlobalCatalog"))){

                if ($TenantDirectory.UseGlobalCatalog){

                    $UseGlobalCatalog = $TenantDirectory.UseGlobalCatalog
                }
            }

        
            $Body = @"
                {
                  "name" : "$($Name)",
                  "description" : "$($Description)",
                  "alias" : "$($Alias)",
                  "type" : "$($Type)",
                  "userNameDn" : "$($UserNameDN)",
                  "groupBaseSearchDn" : "$($GroupBaseSearchDN)",
                  "password" : "$($JSONPassword)",
                  "url" : "$($URL)",
                  "userBaseSearchDn" : "$($UserBaseSearchDN)",
                  "domain" : "$($Domain)",
                  "domainAdminUsername" : "$($DomainAdminUsername)",
                  "domainAdminPassword" : "$($JSONDomainAdminPassword)",
                  "subdomains" : [ "$($Subdomains)" ],
                  "groupBaseSearchDns" : [ $($GroupBaseSearchDNsJSON) ],
                  "userBaseSearchDns" : [ $($UserBaseSearchDNsJSON) ],
                  "certificate" : "$($Certificate)",
                  "trustAll" : $($TrustAllText),
                  "useGlobalCatalog" : $($UseGlobalCatalogText)
                }
"@
        }
        
        # --- Update existing Tenant 
        try {
            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/identity/api/tenants/$($ID)/directories/$($Domain)"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRATenantDirectory -Id $ID | Where-Object {$_.Domain -eq $Domain}
            }
        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: Set-vRAUserPrincipal
#>

function Set-vRAUserPrincipal {
<#
    .SYNOPSIS
    Update a vRA local user principal
    
    .DESCRIPTION
    Update a vRA Principal (user)

    .PARAMETER Id
    The principal id of the user
    
    .PARAMETER Tenant
    The tenant of the user
    
    .PARAMETER FirstName
    First Name

    .PARAMETER LastName
    Last Name

    .PARAMETER EmailAddress
    Email Address

    .PARAMETER Description
    Users text description

    .PARAMETER Password
    Users password
    
    .PARAMETER DisableAccount
    Disable the user principal
    
    .PARAMETER EnableAccount
    Enable or unlock the user principal

    .INPUTS
    System.String
    System.SecureString
    System.Diagnostics.Switch

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Set-vRAUserPrincipal -Id user@vsphere.local -FirstName FirstName-Updated -LastName LastName-Updated -EmailAddress userupdated@vsphere.local -Description Description-Updated
    
    .EXAMPLE
    Set-vRAUserPrincipal -Id user@vsphere.local -EnableAccount
    
    .EXAMPLE
    Set-vRAUserPrincipal -Id user@vsphere.local -DisableAccount
    
    .EXAMPLE
    $SecurePassword = ConvertTo-SecureString “P@ssword” -AsPlainText -Force
    Set-vRAUserPrincipal -Id user@vsphere.local -Password SecurePassword   
#> 
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Alias("PrincipalId")]
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Tenant = $Global:vRAConnection.Tenant,      
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$FirstName,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$LastName,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$EmailAddress,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$Password,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Alias("LockAccount")]
        [Switch]$DisableAccount,
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [Alias("UnlockAccount")]
        [Switch]$EnableAccount   

    )    

    Begin {
        # --- Test for vRA API version
        xRequires -Version 7.0

        # --- Fix for bug found in 7.1 and 7.2 where the PUT will fail if the password attribute is sent back NULL
        # --- If the API version is 7.1 or 7.2 and the Password parameter is not passed Remove unsupported parameters from $PSBoundParameters
        # --- This will ensure that they are not evaluated below
        if (($Global:vRAConnection.APIVersion -eq "7.1") -or ($Global:vRAConnection.APIVersion -eq "7.2") -and (!$PSBoundParameters.ContainsKey("Password"))) {

            Write-Verbose -Message "API Version $($Global:vRAConnection.APIVersion) detected and Password parameter not passed. Removing unsupported parameters."

            $PSBoundParameters.Remove("FirstName") | Out-Null
            $PSBoundParameters.Remove("LastName") | Out-Null
            $PSBoundParameters.Remove("EmailAddress") | Out-Null
            $PSBoundParameters.Remove("Description") | Out-Null
            $PSBoundParameters.Remove("DisableAccount") | Out-Null
            $PSBoundParameters.Remove("EnableAccount") | Out-Null

        }

    }
    
    Process {

        try {
            
            foreach ($PrincipalId in $Id) {
                
                $URI = "/identity/api/tenants/$($Tenant)/principals/$($PrincipalId)"
                $PrincipalObject = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                # --- Should update will be set to true if a property is updated
                # --- This will stop PUT operations where password is null
                $ShouldUpdate = $false
                
                if ($PSBoundParameters.ContainsKey("FirstName")) {
                    
                    Write-Verbose -Message "Updating FirstName: $($PrincipalObject.FirstName) >> $($FirstName)"
                    $PrincipalObject.FirstName = $FirstName
                    $ShouldUpdate = $true
                                                
                }                
                
                if ($PSBoundParameters.ContainsKey("LastName")) {
                    
                    Write-Verbose -Message "Updating LastName: $($PrincipalObject.LastName) >> $($LastName)"
                    $PrincipalObject.LastName = $LastName   
                    $ShouldUpdate = $true
                                                         
                }                   
                
                if ($PSBoundParameters.ContainsKey("EmailAddress")) {
                    
                    Write-Verbose -Message "Updating EmailAddress: $($PrincipalObject.EmailAddress) >> $($EmailAddress)"
                    $PrincipalObject.EmailAddress = $EmailAddress                    
                    $ShouldUpdate = $true
                                        
                }     
                
                if ($PSBoundParameters.ContainsKey("Description")) {
                    
                    Write-Verbose -Message "Updating Description: $($PrincipalObject.Description) >> $($Description)"
                    $PrincipalObject.Description = $Description
                    $ShouldUpdate = $true                   
                                        
                } 
                
                if ($PSBoundParameters.ContainsKey("Password")) {

                    $InsecurePassword = (New-Object System.Management.Automation.PSCredential("username", $Password)).GetNetworkCredential().Password

                    Write-Verbose -Message "Updating Password"
                    $PrincipalObject.Password = $InsecurePassword
                    $ShouldUpdate = $true
                                                       
                }                                                     
                
                if ($PSBoundParameters.ContainsKey("DisableAccount")) {
     
                    Write-Verbose -Message "Disabling Account"
                    $PrincipalObject.Disabled = $true           
                    $ShouldUpdate = $true       
                                        
                }
                
                if ($PSBoundParameters.ContainsKey("EnableAccount")) {
                                           
                    Write-Verbose -Message "Enabling Account"
                    $PrincipalObject.Disabled = $false      
                    $PrincipalObject.Locked = $false      
                    $ShouldUpdate = $true                             
                                        
                }                                              
                
                $Body = $PrincipalObject | ConvertTo-Json -Compress
                
                if ($ShouldUpdate){

                    Write-Verbose -Message "ShouldUpdate is true. Proceeding with Update."

                    if ($PSCmdlet.ShouldProcess($PrincipalId)){

                        # --- Run vRA REST Request           
                        Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null
                        
                        Get-vRAUserPrincipal -Tenant $Tenant -Id $PrincipalId -Verbose:$VerbosePrefernce
                        
                    }

                }                           
                
            }

        }
        catch [Exception]{

            throw
            
        }
        
    }
    End {
        
    }
}

<#
    - Function: Get-vRAResourceMetric
#>

function Get-vRAResourceMetric {
<#
    .SYNOPSIS
    Retrieve metrics for a deployed resource

    .DESCRIPTION
    Retrieve metrics for a deployed resource

    .PARAMETER Id
    The id of the catalog resource

    .PARAMETER Name
    The name of the catalog resource

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAResourceMetric

    .EXAMPLE
    Get-vRAConsumerCatalogItem -Name vm01 | Get-vRAResourceMetric

    .EXAMPLE
    Get-vRAResourceMetric -Id "448fcd09-b8c0-482c-abbc-b3ab818c2e31"

    .EXAMPLE
    Get-vRAResourceMetric -Name vm01

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$false, ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [parameter(Mandatory=$false, ValueFromPipelineByPropertyName, ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100"

    )

    # --- Test for vRA API version
    xRequires -Version 7.0

    try {

        switch ($PsCmdlet.ParameterSetName) {

            # --- Get metrics by resource id
            'ById'{

                foreach ($ResoureId in $Id ) {

                    $Resource = Get-vRAResource -Id $ResoureId

                    $MachineId = $Resource.Data.machineId

                    Write-Verbose -Message "Found machineid $($MachineId) for resource $($Resource.name)"

                    # --- Using $filter param here because GET method doesn't return stats
                    $URI = "/management-service/api/management/metrics"

                    Write-Verbose -Message "Preparing GET to $($URI)"

                    $Response = Invoke-vRARestMethod -Method PUT -URI $URI -Body "{}"

                    $Metric = $Response.Content | Where-Object {$_.iaasUuid -eq $MachineId}

                    Write-Verbose -Message "SUCCESS"

                    [pscustomobject] @{

                        Moref = $Metric.moref
                        vCOPSUuid = $Metric.vcopsUuid
                        IaasUuid = $Metric.iaasUuid
                        ServerGuid = $Metric.serverGuid
                        PendingRequest = $Metric.pendingRequest
                        DailyCost = $Metric.dailyCost
                        ExpirationDate = $Metric.expirationDate
                        Health = $Metric.health
                        Stats = $Metric.stats
                        Strings = $Metric.strings

                    }

                }

                break

            }

            # --- Get metrics by resource name
            'ByName' {

                foreach ($ResourceName in $Name) {

                    $Resource = Get-vRAResource -Name $ResourceName

                    $MachineId = $Resource.Data.machineId

                    Write-Verbose -Message "Found machineid $($MachineId) for resource $($ResourceName)"

                    # --- Using $filter param here because GET method doesn't return stats
                    $URI = "/management-service/api/management/metrics"

                    Write-Verbose -Message "Preparing GET to $($URI)"

                    $Response = Invoke-vRARestMethod -Method PUT -URI $URI -Body "{}"

                    $Metric = $Response.Content | Where-Object {$_.iaasUuid -eq $MachineId}

                    Write-Verbose -Message "SUCCESS"

                    [pscustomobject] @{

                        Moref = $Metric.moref
                        vCOPSUuid = $Metric.vcopsUuid
                        IaasUuid = $Metric.iaasUuid
                        ServerGuid = $Metric.serverGuid
                        PendingRequest = $Metric.pendingRequest
                        DailyCost = $Metric.dailyCost
                        ExpirationDate = $Metric.expirationDate
                        Health = $Metric.health
                        Stats = $Metric.stats
                        Strings = $Metric.strings

                    }

                }

                break

            }

            # --- No parameters passed so return all metrics
            'Standard' {

                $URI = "/management-service/api/management/metrics"

                Write-Verbose -Message "Preparing PUT to $($URI)"

                $Response = Invoke-vRARestMethod -Method PUT -URI $URI -Body "{}"

                Write-Verbose -Message "SUCCESS"

                foreach ($ResourceMetric in $Response.content) {

                    [pscustomobject] @{

                        Moref = $ResourceMetric.moref
                        vCOPSUuid = $ResourceMetric.vcopsUuid
                        IaasUuid = $ResourceMetric.iaasUuid
                        ServerGuid = $ResourceMetric.serverGuid
                        PendingRequest = $ResourceMetric.pendingRequest
                        DailyCost = $ResourceMetric.dailyCost
                        ExpirationDate = $ResourceMetric.expirationDate
                        Health = $ResourceMetric.health
                        Stats = $ResourceMetric.stats
                        Strings = $ResourceMetric.strings

                    }

                }

                break

            }

        }

    }
    catch [Exception]{

        throw
    }

}

<#
    - Function: Invoke-vRADataCollection
#>

function Invoke-vRADataCollection {
<#
    .SYNOPSIS
    Force a data collection run

    .DESCRIPTION
    Force a data collection run via the o11n-gateway-service provided by vRA. The command assumes that the
    embedded vRO is being used for extensibility and that there is only one IaaS host configured.

    .INPUTS
    None

    .OUTPUTS
    None

    .EXAMPLE
    Invoke-vRADataCollection

#>
[CmdletBinding()]

    Param ()

    try {

        # --- Function requires at least 7.1
        xRequires -Version 7.1

        # --- Get metadata for the request
        $Tenant = $Global:vRAConnection.Tenant
        $RequestedBy = $Global:vRAConnection.Username
        $DataCollectionWorkflowId = "9ef7fdb1-2385-4fe5-adc7-5527ca124da7"

        # --- Retrive the vRO inventory Id of the associated IaaS host (vCAC:vCACHost)
        Write-Verbose -Message "Retrieving the registered vCACHost id"
        $vCACHostId = (Invoke-vRARestMethod -Method GET -URI "/o11n-gateway-service/api/tenants/$($Tenant)/inventory/vCAC:vCACHost").Id

        if (!$vCACHostId) {
            throw "Could not find a registered entity for type vCAC:vCACHost"
        }

        Write-Verbose -Message "Found vCAC:vCACHost entity with id $($vCACHostId)"

        # --- Build the request data
        $RequestData = [PSCustomObject]@{
            entries = @(
                @{
                    key = "host"
                    value = [PSCustomObject]@{
                        type = "string"
                        value = $vCACHostId
                    }
                }
            )
        }

        # --- Build the body of the request and add the RequestData object
        $Body = [PSCustomObject]@{
            requestHeader = $null
            requestData = $RequestData
            correlation = $null
            requestedBy = $RequestedBy
            description = $null
            callbackServiceId = $null
        }

        # --- Submit the request
        Invoke-vRARestMethod -Method POST -URI "/o11n-gateway-service/api/tenants/$($Tenant)/workflows/$($DataCollectionWorkflowId)" -Body ($Body | ConvertTo-Json -Depth 50) -Verbose:$VerbosePreference    
    }
    catch {

        throw $_
    }
}

<#
    - Function: Get-vRAPropertyDefinition
#>

function Get-vRAPropertyDefinition {
<#
    .SYNOPSIS
    Get a property that the user is allowed to review.
    
    .DESCRIPTION
    API for property definitions that a system administrator can interact with. It allows the user to interact 
    with property definitions that the user is permitted to review.

    .PARAMETER Id
    The id of the property definition

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAPropertyDefinition
    
    .EXAMPLE
    Get-vRAPropertyDefinition -Limit 200

    .EXAMPLE
    Get-vRAPropertyDefinition -Id Hostname
    
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (
    
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get property definition by id
                'ById' {

                    foreach ($PropertyDefinitionId in $Id) {
                
                        $URI = "/properties-service/api/propertydefinitions/$($PropertyDefinitionId)"

                        $PropertyDefinition = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        [PSCustomObject] @{

                            Id = $PropertyDefinition.id
                            Label = $PropertyDefinition.label
                            Description = $PropertyDefinition.description
                            Type = $PropertyDefinition.dataType.typeId
                            IsMultivalued = $PropertyDefinition.isMultiValued
                            Display = $PropertyDefinition.displayAdvice
                            TenantId = $PropertyDefinition.tenantId
                            DisplayIndex = $PropertyDefinition.orderIndex
                            PermittedValues = $PropertyDefinition.permissibleValues
                            Options = $PropertyDefinition.facets
                            Version = $PropertyDefinition.version
                            DateCreated = $PropertyDefinition.createdDate
                            LastUpdatedDate = $PropertyDefinition.lastUpdated      

                        }

                    }

                    break

                }

                # --- No parameters passed so return all property definitions
                'Standard' {

                    $URI = "/properties-service/api/propertydefinitions?limit=$($Limit)&page=$($Page)&`$orderby=id asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($PropertyDefinition in $Response.content) {

                        [PSCustomObject] @{

                            Id = $PropertyDefinition.id
                            Label = $PropertyDefinition.label
                            Description = $PropertyDefinition.description
                            Type = $PropertyDefinition.dataType.typeId
                            IsMultivalued = $PropertyDefinition.isMultiValued
                            Display = $PropertyDefinition.displayAdvice
                            TenantId = $PropertyDefinition.tenantId
                            DisplayIndex = $PropertyDefinition.orderIndex
                            PermittedValues = $PropertyDefinition.permissibleValues
                            Options = $PropertyDefinition.facets
                            Version = $PropertyDefinition.version
                            DateCreated = $PropertyDefinition.createdDate
                            LastUpdatedDate = $PropertyDefinition.lastUpdated     

                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }
    }

    End {

    }
}

<#
    - Function: Get-vRAPropertyGroup
#>

function Get-vRAPropertyGroup {
<#
    .SYNOPSIS
    Get a property group that the user is allowed to review.
    
    .DESCRIPTION
    API for property groups that a system administrator can interact with. It allows the user to interact 
    with property groups that the user is permitted to review.

    .PARAMETER Id
    The id of the property group

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100

    .PARAMETER Page
    The index of the page to display.

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAPropertyGroup
    
    .EXAMPLE
    Get-vRAPropertyGroup -Limit 200

    .EXAMPLE
    Get-vRAPropertyGroup -Id Hostname
    
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (
    
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
        [ValidateNotNullOrEmpty()]
        [String[]]$Id,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Page = 1,

        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [Int]$Limit = 100

    )

    Begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }

    Process {

        try {

            switch ($PsCmdlet.ParameterSetName) {

                # --- Get property Group by id
                'ById' {
                    
                    foreach ($PropertyGroupId in $Id) {
                
                        $URI = "/properties-service/api/propertygroups/$($PropertyGroupId)"

                        $PropertyGroup = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

                        $props = @{}
                        foreach($vRAProp in $PropertyGroup.properties.PSObject.Properties) {
                            $facets = @{}
                            foreach($facetkey in $vRAProp.Value.facets.PSObject.Properties) {
                                $facets.Add($facetkey.Name, $facetKey.Value.value.value)
                            }

                            # add to props grouping now
                            $props.Add($vRAProp.Name, $facets)
                        }

                        [PSCustomObject] @{

                            Id = $PropertyGroup.id
                            Label = $PropertyGroup.label
                            Description = $PropertyGroup.description
                            TenantId = $PropertyGroup.tenantId
                            DateCreated = $PropertyGroup.createdDate
                            LastUpdatedDate = $PropertyGroup.lastUpdated
                            Properties = $props
                        }
                    }

                    break

                }

                # --- No parameters passed so return all property Groups
                'Standard' {

                    $URI = "/properties-service/api/propertygroups?limit=$($Limit)&page=$($Page)&`$orderby=id asc"

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    $Response = Invoke-vRARestMethod -Method GET -URI $EscapedURI -Verbose:$VerbosePreference

                    foreach ($PropertyGroup in $Response.content) {
                        $props = @{}
                        foreach($vRAProp in $PropertyGroup.properties.PSObject.Properties) {
                            $facets = @{}
                            foreach($facetkey in $vRAProp.Value.facets.PSObject.Properties) {
                                $facets.Add($facetkey.Name, $facetKey.Value.value.value)
                            }

                            # add to props grouping now
                            $props.Add($vRAProp.Name, $facets)
                        }

                        [PSCustomObject] @{

                            Id = $PropertyGroup.id
                            Label = $PropertyGroup.label
                            Description = $PropertyGroup.description
                            TenantId = $PropertyGroup.tenantId
                            DateCreated = $PropertyGroup.createdDate
                            LastUpdatedDate = $PropertyGroup.lastUpdated
                            Properties = $props
                        }

                    }

                    Write-Verbose -Message "Total: $($Response.metadata.totalElements) | Page: $($Response.metadata.number) of $($Response.metadata.totalPages) | Size: $($Response.metadata.size)"

                    break

                }

            }

        }
        catch [Exception]{

            throw

        }
    }

    End {

    }
}

<#
    - Function: New-vRAPropertyDefinition
#>

function New-vRAPropertyDefinition {
<#
    .SYNOPSIS
    Create a custom Property Definition
    
    .DESCRIPTION
    Create a custom Property Definition

    .PARAMETER Name
    The unique name (ID) of the Property
    
    .PARAMETER Label
    The text to display in forms for the Property

    .PARAMETER Description
    Description of the Property

    .PARAMETER Tenant
    The tenant in which to create the Property Definition (Defaults to the connection tenant )

    .PARAMETER Index
    The display index of the Property

    .PARAMETER Required
    Switch to flag the Property as required

    .PARAMETER Encrypted
    Switch to flag the Property as Encrypted
    
    .PARAMETER String
    Switch to flag the Property type as String

    .PARAMETER StringDisplay
    The form display option for the Property

    .PARAMETER Boolean
    Switch to flag the Property type as Boolean

    .PARAMETER BooleanDisplay
    The form display option for the Property

    .PARAMETER Integer
    Switch to flag the Property type as Integer

    .PARAMETER IntegerDisplay
    The form display option for Integer

    .PARAMETER Decimal
    Switch to flag the Property type as Decimal

    .PARAMETER DecimalDisplay
    The form display option for Decimal

    .PARAMETER Datetime
    Switch to flag the Property type as Datetime

    .PARAMETER DatetimeDisplay
    The form display option for Datetime
    
    .PARAMETER JSON
    Property Definition to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Create a string dropdown with defined values
    New-vRAPropertyDefinition -Name one -String -StringDisplay DROPDOWN -ValueType Static -Values @{Name1="Value1";Name2="Value2"}
    
    .EXAMPLE
    # Create an integer slider with min, max and increment
    New-vRAPropertyDefinition -Name IntegerName -Label "Select an Integer" -Integer -IntegerDisplay SLIDER -MinimumValue 1 -MaximumValue 10 -Increment 1

    .EXAMPLE
    # Create a boolean checkbox
    New-vRAPropertyDefinition -Name BooleanName -Label "Check this box" -Boolean -BooleanDisplay CHECKBOX

    .EXAMPLE
    # Create a new decimal slider with min, max and increment
    New-vRAPropertyDefinition -Name DecimalTest -Decimal -DecimalDisplay SLIDER -MinimumValue 0 -MaximumValue 10 -Increment 0.5

#> 
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [parameter(Mandatory=$false)]    
        [ValidateNotNullOrEmpty()]
        [String]$Label = $Name,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [parameter(Mandatory=$false)]    
        [ValidateNotNullOrEmpty()]
        [String]$Tenant = $Global:vRAConnection.Tenant,
        
        [parameter(Mandatory=$false)]    
        [ValidateNotNullOrEmpty()]
        [Int]$Index,

        [parameter(Mandatory=$false)] 
        [ValidateNotNullOrEmpty()]
        [Switch]$Required,

        [parameter(Mandatory=$false)] 
        [ValidateNotNullOrEmpty()]
        [Switch]$Encrypted,

        [parameter(Mandatory=$false,ParameterSetName="String")] 
        [ValidateNotNullOrEmpty()]
        [Switch]$String,

        [parameter(Mandatory=$true,ParameterSetName="String")] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("DROPDOWN","TEXTBOX","EMAIL","HYPERLINK","TEXTAREA")]
        [String]$StringDisplay,

        [parameter(Mandatory=$false,ParameterSetName="Boolean")] 
        [ValidateNotNullOrEmpty()]
        [Switch]$Boolean,

        [parameter(Mandatory=$true,ParameterSetName="Boolean")] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("CHECKBOX","YES_NO")]
        [String]$BooleanDisplay,

        [parameter(Mandatory=$false,ParameterSetName="Integer")] 
        [ValidateNotNullOrEmpty()]
        [Switch]$Integer,

        [parameter(Mandatory=$true,ParameterSetName="Integer")] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("DROPDOWN","SLIDER","TEXTBOX")]
        [String]$IntegerDisplay,

        [parameter(Mandatory=$false,ParameterSetName="Decimal")] 
        [ValidateNotNullOrEmpty()]
        [Switch]$Decimal,

        [parameter(Mandatory=$true,ParameterSetName="Decimal")] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("DROPDOWN","SLIDER","TEXTBOX")]
        [String]$DecimalDisplay,

        [parameter(Mandatory=$false,ParameterSetName="Datetime")] 
        [ValidateNotNullOrEmpty()]
        [Switch]$Datetime,

        [parameter(Mandatory=$true,ParameterSetName="Datetime")] 
        [ValidateNotNullOrEmpty()]
        [ValidateSet("DATE_TIME_PICKER")]
        [String]$DatetimeDisplay, # This is redundant, only one option

        [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
        [ValidateNotNullOrEmpty()]
        [String]$JSON

    )

    DynamicParam {
        if ($PSBoundParameters.ContainsKey("JSON")){
                # Do not evaluate dynamic parameters for JSON input
                return;
        } else {
            $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            if($StringDisplay -eq "DROPDOWN") {
                $ValueTypes = "Static","Dynamic"
                NewDynamicParam -Name "EnableCustomValues" -Type switch -ParameterSet "String" -DPDictionary $Dictionary
                NewDynamicParam -Name "ValueType" -Mandatory -ValidateSet $ValueTypes -ParameterSet "String" -DPDictionary $Dictionary
                NewDynamicParam -Name "Values" -Type hashtable -Mandatory -ParameterSet "String" -DPDictionary $Dictionary
            }

            if($Integer) {
                if($IntegerDisplay -eq "DROPDOWN") {
                    # Dropdown should have value type (static or dynamic) and a hashtable of values
                    $ValueTypes = "Static","Dynamic"
                    NewDynamicParam -Name "EnableCustomValues" -Type switch -ParameterSet "Integer" -DPDictionary $Dictionary
                    NewDynamicParam -Name "ValueType" -Mandatory -ValidateSet $ValueTypes -ParameterSet "Integer" -DPDictionary $Dictionary
                    NewDynamicParam -Name "Values" -Type hashtable -Mandatory -ParameterSet "Integer" -DPDictionary $Dictionary
                } elseif($IntegerDisplay -eq "SLIDER") {
                    # Min/Max value are mandatory for a slider
                    NewDynamicParam -Name "MinimumValue" -Mandatory -Type int -ParameterSet "Integer" -DPDictionary $Dictionary
                    NewDynamicParam -Name "MaximumValue" -Mandatory -Type int -ParameterSet "Integer" -DPDictionary $Dictionary
                    NewDynamicParam -Name "Increment" -Type decimal -ParameterSet "Integer" -DPDictionary $Dictionary
                } else { 
                    # Otherwise add some optional for Integers
                    NewDynamicParam -Name "MinimumValue" -Type int -ParameterSet "Integer" -DPDictionary $Dictionary
                    NewDynamicParam -Name "MaximumValue" -Type int -ParameterSet "Integer" -DPDictionary $Dictionary
                    NewDynamicParam -Name "Increment" -Type decimal -ParameterSet "Integer" -DPDictionary $Dictionary
                }
            }

            if($Decimal) {
                if($DecimalDisplay -eq "DROPDOWN") {
                    # Dropdown should have value type (static or dynamic) and a hashtable of values
                    $ValueTypes = "Static","Dynamic"
                    NewDynamicParam -Name "EnableCustomValues" -Type switch -ParameterSet "Decimal" -DPDictionary $Dictionary
                    NewDynamicParam -Name "ValueType" -Mandatory -ValidateSet $ValueTypes -ParameterSet "Decimal" -DPDictionary $Dictionary
                    NewDynamicParam -Name "Values" -Type hashtable -Mandatory -ParameterSet "Decimal" -DPDictionary $Dictionary
                } elseif($IntegerDisplay -eq "SLIDER") {
                    # Min/Max value are mandatory for a slider
                    NewDynamicParam -Name "MinimumValue" -Mandatory -Type decimal -ParameterSet "Decimal" -DPDictionary $Dictionary
                    NewDynamicParam -Name "MaximumValue" -Mandatory -Type decimal -ParameterSet "Decimal" -DPDictionary $Dictionary
                    NewDynamicParam -Name "Increment" -Type decimal -ParameterSet "Decimal" -DPDictionary $Dictionary
                } else { 
                    # Otherwise add some optional for Decimal
                    NewDynamicParam -Name "MinimumValue" -Type decimal -ParameterSet "Decimal" -DPDictionary $Dictionary
                    NewDynamicParam -Name "MaximumValue" -Type decimal -ParameterSet "Decimal" -DPDictionary $Dictionary
                    NewDynamicParam -Name "Increment" -Type decimal -ParameterSet "Decimal" -DPDictionary $Dictionary
                }
            }
            if($Datetime) {
                # TODO - Datetime needs to be a string as UniversalSortableDateTimePattern
                NewDynamicParam -Name "MinimumValue" -Type DateTime -ParameterSet "Datetime" -DPDictionary $Dictionary
                NewDynamicParam -Name "MaximumValue" -Type DateTime -ParameterSet "Datetime" -DPDictionary $Dictionary
            }
            return $Dictionary
        }
    } 

    begin {

        # --- Test for vRA API version
        xRequires -Version 7.0

        #Get common parameters, pick out bound parameters not in that set
        Function intTemp { [cmdletbinding()] param() }
        $BoundKeys = $PSBoundParameters.keys | Where-Object { (get-command intTemp | Select-Object -ExpandProperty parameters).Keys -notcontains $_}
        foreach($param in $BoundKeys) {
            if (-not ( Get-Variable -name $param -scope 0 -ErrorAction SilentlyContinue ) ) {
                New-Variable -Name $Param -Value $PSBoundParameters.$param
                Write-Verbose "Adding variable for dynamic parameter '$param' with value '$($PSBoundParameters.$param)'"
            }
        }
    }
    
    process {

        try {
            # --- Set Body for REST request depending on ParameterSet
            if ($PSBoundParameters.ContainsKey("JSON")){
                $Body = $JSON
            }
            else {
                $MultiValued = if($IsMultiValued) { "true" } else { "false" }
                $Mandatory = if($Required) { "true" } else { "false" }
                $CustomValues = if($AllowCustomValues) { "true" } else { "false" }
                if($Index -eq 0) {
                    $IndexString = "null"
                } else {
                    $IndexString = $Index.ToString()
                }
                if($String) { 
                    $DataType = "STRING"
                    $Display = $StringDisplay
                }
                if($Boolean) {
                    $DataType = "BOOLEAN"
                    $Display = $BooleanDisplay
                }
                if($Integer) { 
                    $DataType = "INTEGER"
                    $Display = $IntegerDisplay
                }
                if($Decimal) {
                    $DataType = "DECIMAL"
                    $Display = $DecimalDisplay
                }
                if($Datetime) { 
                    $DataType = "DATETIME"
                    $Display = $DatetimeDisplay
                }

                # $DataType BOOLEAN cannot be Required
                $facets = ""
                if($DataType -ne "BOOLEAN") {
                    $facets = @"
                        "mandatory": {
                            "type": "constant",
                            "value": {
                                "type": "boolean",
                                "value": $($Mandatory)
                            }
                        },
"@
                }
                     $facets += @"
                        "encrypted": {
                            "type": "constant",
                            "value": {
                                "type": "boolean",
                                "value": $($Encrypted.ToString().ToLower())
                            }
                        },
"@
               if($MinimumValue) {
                    $facets += @"
                        "minValue": {
                            "type": "constant",
                            "value": {
                                "type": "integer",
                                "value": $($MinimumValue)
                            }
                        },
"@
               }
               if($MaximumValue) {
                    $facets += @"
                        "maxValue": {
                            "type": "constant",
                            "value": {
                                "type": "integer",
                                "value": $($MaximumValue)
                            }
                        },
"@
               }
               if($Increment) {
                    $facets += @"
                        "increment": {
                            "type": "constant",
                            "value": {
                                "type": "decimal",
                                "value": $($Increment)
                            }
                        },
"@
               }

                # Build permissible values
                if($ValueTypes -eq "Static") {
                    $ValueJSON = ""
                    foreach($Value in $Values.GetEnumerator()) {
                        $ValueJSON += @"
                        {
                            "underlyingValue": {
                                "type": "$($DataType.ToLower())",
                                "value": "$($Value.Value)"
                            },
                            "label": "$($Value.Name)"
                        },
"@
                    }
                    $PermissibleValues = @"
                    "permissibleValues": {
                        "type": "static",
                        "customAllowed": $($CustomValues),
                        "values": [
$($ValueJSON.Trim(","))
                        ]
                    },
"@
            } elseif($ValueTypes -eq "Dynamic") {
                # Not implemented yet!!
                $PermissibleValues = @"
                    "permissibleValues": {
                        "type": "dynamic",
                        "customAllowed": false,
                        "dependencies": [],
                        "context": {
                            "providerEntityId": "com.vmware.library.vc.storage/listDatastores",
                            "parameterMappings": {
                                "params": [
                                    {
                                    "key": "host",
                                        "value": {
                                            "type": "constant",
                                            "value": {
                                                "type": "string",
                                                "value": ""
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    },
"@
                } else {
                    $PermissibleValues = @"
                    "permissibleValues": null,
"@
                }


                $Body = @"
                {
                    "id" : "$($Name)",
                    "label" : "$($Label)",
                    "description" : "$($Description)",
                    "dataType" : {
                        "type" : "primitive",
                        "typeId" : "$($DataType)"
                    },
                    "isMultiValued" : $($MultiValued),
                    "displayAdvice" : "$($Display)",
                    "tenantId" : "$($Tenant)",
                    "orderIndex": $($IndexString),
$($PermissibleValues)
                    "facets": {
$($facets.Trim(","))
                    }
                }
"@

            }

            $URI = "/properties-service/api/propertydefinitions"  

            Write-Verbose -Message "Preparing POST to $($URI)"     

            # --- Run vRA REST Request  
            if ($PSCmdlet.ShouldProcess($Id)) {

                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body | Out-Null
                Get-vRAPropertyDefinition -Id $Name
            }
        }
        catch [Exception]{

            throw            
        }        
    }
    end {
        
    }    
}

<#
    - Function: New-vRAPropertyGroup
#>

function New-vRAPropertyGroup {
    <#
    .SYNOPSIS
    Create a custom Property Group
    
    .DESCRIPTION
    Create a custom Property Group

    .PARAMETER Name
    The unique name (ID) of the Property
    
    .PARAMETER Label
    The text to display in forms for the Property

    .PARAMETER Description
    Description of the Property

    .PARAMETER Tenant
    The tenant in which to create the Property Group (Defaults to the connection tenant )

    .PARAMETER Properties
    A hashtable representing the properties you would like to build into this new property group
   
    .PARAMETER JSON
    Property Group to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Create a simple property group with no properties addded
    New-vRAPropertyGroup -Name one 
    
    .EXAMPLE
    # Create a property group with a description and label
    New-vRAPropertyGroup -Name OneWithDescription -Label "On With Description" -Description "This is one with a label and description"

    .EXAMPLE
    # Create a property group with some properties added in simple form
    New-vRAPropertyGroup -Name OneWithPropetiesSimple -Label "One With Properties" -Properties @{"com.org.bool"=$false; "com.org.string"="string1"}

    .EXAMPLE
    # Create a property group with some properties added in the extended form
    New-vRAPropertyGroup -Name OneWithPropertiesExt -Label "One With Properties" -Properties @{"com.org.bool"=@{"mandatory"=$true; "defaultValue"=$false;}; "com.org.encryptedandshowonform"=@{"encrypted"=$true; "visibility"=$true; "defaultValue"="Un-encrypted string";};}

#> 
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "Low",DefaultParameterSetName = 'Default')][OutputType('System.Management.Automation.PSObject')]

    Param (
        [parameter(Mandatory = $true, ParameterSetName = "Default")]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        
        [parameter(Mandatory = $false)]    
        [ValidateNotNullOrEmpty()]
        [String]$Label = $Name,

        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [String]$Description,

        [parameter(Mandatory = $false)]    
        [ValidateNotNullOrEmpty()]
        [String]$Tenant = $Global:vRAConnection.Tenant,
        
        [parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "Properties")]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Properties,

        [parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "JSON")]
        [ValidateNotNullOrEmpty()]
        [String]$JSON

    )

    begin {

        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    process {

        try {
            # --- Set Body for REST request depending on ParameterSet
            if ($PSBoundParameters.ContainsKey("JSON")) {
                $Body = $JSON
            }
            else {
                $propertiesRaw = ""
                
                # process properties sent in
                foreach ($propKey in $Properties.Keys) {
                    $prop = $Properties[$propKey]
                    switch ($prop.GetType()) {
                        "Hashtable" {
                            $facets = ""
                            foreach ($fKey in $prop.Keys) {
                                $f = $prop[$fKey]
                                switch ($fKey) {
                                    "visibility" {
                                        $facets += @"
                                        "visibility": {
                                            "type": "constant",
                                            "value": {
                                                "type": "boolean",
                                                "value": $($f.toString().toLower())
                                            }
                                },
"@
                                    }
                                    "encrypted" {
                                        $facets += @"
                                        "encrypted": {
                                            "type": "constant",
                                            "value": {
                                                "type": "boolean",
                                                "value": $($f.toString().toLower())
                                            }
                                },
"@
                                    }
                                    "mandatory" {
                                        $facets += @"
                                        "mandatory": {
                                            "type": "constant",
                                            "value": {
                                                "type": "boolean",
                                                "value": $($f.toString().toLower())
                                            }
                                },
"@
                                    }
                                    "defaultValue" {
                                        $facets += @"
                                        "defaultValue": {
                                            "type": "constant",
                                            "value": {
                                                "type": "string",
                                                "value": "$($f)"
                                            }
                                },
"@
                                    }
                                }
                            }
                            $propertiesRaw += @"
                            "$($propKey)": {
                                "facets": { $($facets.Trim(',')) }
                            },
"@
                            break
                        }
                        default {
                            $propertiesRaw += @"
                            "$($propKey)": {
                                "facets": {
                                    "defaultValue": {
                                        "type": "constant",
                                        "value": {
                                            "type": "string",
                                            "value": "$($prop)"
                                        }
                                    }
                                }
                            },
"@
                            break
                        }
                    }
                }
                # logic to build input
                $Body = @"
                {
                    "id" : "$($Name)",
                    "label" : "$($Label)",
                    "description" : "$($Description)",
                    "tenantId" : "$($Tenant)",
                    "version": 0,
                    "properties": { $($propertiesRaw.Trim(',')) }
                }
"@
            }

            $URI = "/properties-service/api/propertygroups"  

            Write-Verbose -Message "Preparing POST to $($URI)"   

            Write-Verbose -Message "Posting Body: $($Body)"  

            # --- Run vRA REST Request  
            if ($PSCmdlet.ShouldProcess($Id)) {
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body | Out-Null
                Get-vRAPropertyGroup -Id $Name
            }
        }
        catch [Exception] {

            throw            
        }        
    }
    end {
        
    }    
}

<#
    - Function: Remove-vRAPropertyDefinition
#>

function Remove-vRAPropertyDefinition {
<#
    .SYNOPSIS
    Removes a Property Definiton from the specified tenant
    
    .DESCRIPTION
    Uses the REST API to delete a property definiton based on the Id supplied. If the Tenant is supplied it will delete the property for that tenant only.

    .PARAMETER Id
    The id of the property definition to delete

    .PARAMETER Tenant
    The tenant of the property definition to delete

    .INPUTS
    System.String

    .OUTPUTS
    None

    .EXAMPLE
    # Remove the property "Hostname"
    Remove-vRAPropertyDefinition -Id Hostname

    .EXAMPLE
    # Remove the property "Hostname" using the pipeline
    Get-vRAPropertyDefinition -Id Hostname | Remove-vRAPropertyDefinition -Confirm:$false
    
    .EXAMPLE
    # Remove the property "Hostname" from the tenant "Development"
    Remove-vRAPropertyDefinition -Id "Hostname" -Tenant Development

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [parameter(Mandatory=$false)]    
        [ValidateNotNullOrEmpty()]
        [String]$Tenant

    )

    Begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }

    Process {

        try {
            # Get-vRAPropertyDefinition will throw a 404 error if it doesn't exist
            if(Get-vRAPropertyDefinition -Id $Id) {
                
                if ($PSCmdlet.ShouldProcess($Id)){

                    $URI = "/properties-service/api/propertydefinitions/$($Id)"

                    if($Tenant) { 
                        $URI += "?tenantId=$($Tenant)"
                    }

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    Invoke-vRARestMethod -Method DELETE -URI $EscapedURI -Verbose:$VerbosePreference
                }

            }

        }
        catch [Exception]{

            throw

        }
    }

    End {

    }
}

<#
    - Function: Remove-vRAPropertyGroup
#>

function Remove-vRAPropertyGroup {
<#
    .SYNOPSIS
    Removes a Property Group from the specified tenant
    
    .DESCRIPTION
    Uses the REST API to delete a property Group based on the Id supplied. If the Tenant is supplied it will delete the property group for that tenant only.

    .PARAMETER Id
    The id of the property Group to delete

    .PARAMETER Tenant
    The tenant of the property Group to delete

    .INPUTS
    System.String

    .OUTPUTS
    None

    .EXAMPLE
    # Remove the property group "Hostname"
    Remove-vRAPropertyGroup -Id Hostname

    .EXAMPLE
    # Remove the property group "Hostname" using the pipeline
    Get-vRAPropertyGroup -Id Hostname | Remove-vRAPropertyGroup -Confirm:$false
    
    .EXAMPLE
    # Remove the property group "Hostname" from the tenant "Development"
    Remove-vRAPropertyGroup -Id "Hostname" -Tenant Development

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [parameter(Mandatory=$false)]    
        [ValidateNotNullOrEmpty()]
        [String]$Tenant

    )

    Begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }

    Process {

        try {
            # Get-vRAPropertyGroup will throw a 404 error if it doesn't exist
            if(Get-vRAPropertyGroup -Id $Id) {
                
                if ($PSCmdlet.ShouldProcess($Id)){

                    $URI = "/properties-service/api/propertygroups/$($Id)"

                    if($Tenant) { 
                        $URI += "?tenantId=$($Tenant)"
                    }

                    $EscapedURI = [uri]::EscapeUriString($URI)

                    Invoke-vRARestMethod -Method DELETE -URI $EscapedURI -Verbose:$VerbosePreference
                }

            }

        }
        catch [Exception]{

            throw

        }
    }

    End {

    }
}

<#
    - Function: Add-vRAReservationNetwork
#>

function Add-vRAReservationNetwork {
<#
    .SYNOPSIS
    Add a network to an existing vRA reservation

    .DESCRIPTION
    This cmdlet enables the user to add a new network to a reservation. Only one new network path can be added at a time.
    If a duplicate network path is detected, the API will throw an error.

    .PARAMETER Id
    The Id of the reservation

    .PARAMETER NetworkPath
    The network path
    
    .PARAMETER NetworkProfile
    The network profile

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAReservation -Name Reservation01 | Add-vRAReservationNetwork -NetworkPath "DMZ" -NetworkProfile "DMZ-Profile"

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [String]$Id,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$NetworkPath,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$NetworkProfile

    )
 
    begin {
    
    }
    
    process {

        try {

            # --- Get the reservation

            $URI = "/reservation-service/api/reservations/$($id)"

            $Reservation = Invoke-vRARestMethod -Method GET -URI $URI

            $ReservationTypeName = (Get-vRAReservationType -Id $Reservation.reservationTypeId).name

            $ComputeResourceId = ($Reservation.extensionData.entries | Where-Object {$_.key -eq "computeResource"}).value.id            

            # ---
            # --- Add Network
            # ---

            Write-Verbose -Message "Creating New Network Definition"


            if ($PSBoundParameters.ContainsKey("NetworkProfile")) {

                $NetworkDefinition = New-vRAReservationNetworkDefinition -Type $ReservationTypeName -ComputeResourceId $ComputeResourceId -NetworkPath $NetworkPath -NetworkProfile $NetworkProfile

            }
            else {

                $NetworkDefinition = New-vRAReservationNetworkDefinition -Type $ReservationTypeName -ComputeResourceId $ComputeResourceId -NetworkPath $NetworkPath

            }

            $ReservatonNetworks = $Reservation.extensionData.entries | Where-Object {$_.key -eq "reservationNetworks"}

            Write-Verbose -Message "Adding Network To Reservation"

            $ReservatonNetworks.value.items += $NetworkDefinition         
    
            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/reservation-service/api/reservations/$($Id)"
                
                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Reservation | ConvertTo-Json -Depth 100) -Verbose:$VerbosePreference | Out-Null

            }

        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: Add-vRAReservationStorage
#>

function Add-vRAReservationStorage {
<#
    .SYNOPSIS
    Add storage to an existing vRA reservation

    .DESCRIPTION
    This cmdlet enables the user to add new storage to a reservation. Only one new storage path can be added at a time.
    If a duplicate storage path is detected, the API will throw an error.

    .PARAMETER Id
    The Id of the reservation

    .PARAMETER Path
    The storage path
    
    .PARAMETER ReservedSizeGB
    The size in GB of this reservation
    
    .PARAMETER Priority
    The priority of storage 

    .INPUTS
    System.String.
    System.Int.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAReservation -Name Reservation01 | Add-vRAReservationStorage -Path "Datastore01" -ReservedSizeGB 500 -Priority 1

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [String]$Id,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Path,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [Int]$ReservedSizeGB,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$Priority = 0

    )
 
    begin {
    
    }
    
    process {

        try {

            # --- Get the reservation

            $URI = "/reservation-service/api/reservations/$($id)"

            $Reservation = Invoke-vRARestMethod -Method GET -URI $URI

            $ReservationTypeName = (Get-vRAReservationType -Id $Reservation.reservationTypeId).name

            $ComputeResourceId = ($Reservation.extensionData.entries | Where-Object {$_.key -eq "computeResource"}).value.id            

            # ---
            # --- Add Storage
            # ---

            Write-Verbose -Message "Creating New Storage Definition"

            $StorageDefinition = New-vRAReservationStorageDefinition -Type $ReservationTypeName -ComputeResourceId $ComputeResourceId -Path $Path -ReservedSizeGB $ReservedSizeGB -Priority $Priority

            $ReservatonStorages = $Reservation.extensionData.entries | Where-Object {$_.key -eq "reservationStorages"}

            Write-Verbose -Message "Adding Storage To Reservation"

            $ReservatonStorages.value.items += $StorageDefinition         
    
            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/reservation-service/api/reservations/$($Id)"
                
                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Reservation | ConvertTo-Json -Depth 100) -Verbose:$VerbosePreference | Out-Null

            }

        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: Get-vRAReservation
#>

function Get-vRAReservation {
<#
    .SYNOPSIS
    Get a reservation
    
    .DESCRIPTION
    Get a reservation

    .PARAMETER Id
    The id of the reservation
    
    .PARAMETER Name
    The name of the reservation

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. All pages are retuend by default

    .INPUTS
    System.String
    System.Int

    .OUTPUTS
    System.Management.Automation.PSObject
    System.Object[]

    .EXAMPLE
    Get-vRAReservation -Id 75ae3400-beb5-4b0b-895a-0484413c93b1

    .EXAMPLE
    Get-vRAReservation -Name Reservation1

    .EXAMPLE
    Get-vRAReservation 

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject', 'System.Object[]')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,
    
    [parameter(Mandatory=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name,    
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Limit = "100",
 
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Page = "1"
       
    )    

    try {

        switch ($PsCmdlet.ParameterSetName) {

            'ById' { 

                foreach ($ReservationId in $Id) {

                    $URI = "/reservation-service/api/reservations/$($ReservationId)"
            
                    Write-Verbose -Message "Preparing GET to $($URI)"

                    $Response = Invoke-vRARestMethod -Method GET -URI "$($URI)"

                    Write-Verbose -Message "SUCCESS"

                    if ($Response.Count -eq 0) {

                        throw "Could not find reservation $($ReservationId)"

                    }

                    [pscustomobject] @{

                        CreatedDate = $Response.createdDate
                        LastUpdated = $Response.lastUpdated
                        Version = $Response.version
                        Id = $Response.id
                        Name = $Response.name
                        ReservationTypeId = $Response.reservationTypeId
                        TenantId = $Response.tenantId
                        SubTenantId = $Response.subtenantId
                        Enabled = $Response.enabled
                        Priority = $Response.Priority
                        ReservationPolicyId = $Response.reservationPolicyId
                        AlertPolicy = $Response.alertPolicy
                        ExtensionData = $Response.extensionData

                    }

                }

                break

            }

            'ByName' {

                foreach ($ReservationName in $Name) {
            
                    $URI = "/reservation-service/api/reservations?`$filter=name%20eq%20'$($ReservationName)'"
            
                    Write-Verbose -Message "Preparing GET to $($URI)"

                    $Response = Invoke-vRARestMethod -Method GET -URI "$($URI)"

                    Write-Verbose -Message "SUCCESS"

                    if ($Response.content.Count -eq 0) {

                        throw "Could not find reservation $($ReservationName)"

                    }

                    [pscustomobject] @{

                        CreatedDate = $Response.content.createdDate
                        LastUpdated = $Response.content.lastUpdated
                        Version = $Response.content.version
                        Id = $Response.content.id
                        Name = $Response.content.name
                        ReservationTypeId = $Response.content.reservationTypeId
                        TenantId = $Response.content.tenantId
                        SubTenantId = $Response.content.subtenantId
                        Enabled = $Response.content.enabled
                        Priority = $Response.content.Priority
                        ReservationPolicyId = $Response.content.reservationPolicyId
                        AlertPolicy = $Response.content.alertPolicy
                        ExtensionData = $Response.content.extensionData

                    }
                                      
                }
                
                break                                          
        
            }

            'Standard' {

                $URI = "/reservation-service/api/reservations?limit=$($Limit)"

                # --- Make the first request to determine the size of the request
                $Response = Invoke-vRARestMethod -Method GET -URI $URI

                if (!$PSBoundParameters.ContainsKey("Page")){

                    # --- Get every page back
                    $TotalPages = $Response.metadata.totalPages.ToInt32($null)

                }
                else {

                    # --- Set TotalPages to 1
                    $TotalPages = 1

                }

                # --- Initialise an empty array
                $ResponseObject = @()

                while ($true){

                    Write-Verbose -Message "Getting response for page $($Page) of $($Response.metadata.totalPages)"

                    $PagedUri = "$($URI)&page=$($Page)&`$orderby=name%20asc"

                    Write-Verbose -Message "GET : $($PagedUri)"

                    $Response = Invoke-vRARestMethod -Method GET -URI $PagedUri
            
                    Write-Verbose -Message "Paged Response contains $($Response.content.Count) records"

                    foreach ($Reservation in $Response.content) {

                        $Object = [pscustomobject] @{

                            CreatedDate = $Reservation.createdDate
                            LastUpdated = $Reservation.lastUpdated
                            Version = $Reservation.version
                            Id = $Reservation.id
                            Name = $Reservation.name
                            ReservationTypeId = $Reservation.reservationTypeId
                            TenantId = $Reservation.tenantId
                            SubTenantId = $Reservation.subtenantId
                            Enabled = $Reservation.enabled
                            Priority = $Reservation.Priority
                            ReservationPolicyId = $Reservation.reservationPolicyId
                            AlertPolicy = $Reservation.alertPolicy
                            ExtensionData = $Reservation.extensionData

                        }

                        $ResponseObject += $Object

                    }

                    # --- Break loop
                    if ($Page -ge $TotalPages) {

                        break

                    }

                    # --- Increment the current page by 1
                    $Page++

                }         

                # --- Return reservations
                $ResponseObject

                break
    
            }

        }
           
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRAReservationComputeResource
#>

function Get-vRAReservationComputeResource {
<#
    .SYNOPSIS
    Get a compute resource for a reservation type
    
    .DESCRIPTION
    Get a compute resource for a reservation type

    .PARAMETER Type
    The resource type
    Valid types vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere,XenServer
    Valid types vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer

    .PARAMETER Id
    The id of the compute resource
    
    .PARAMETER Name
    The name of the compute resource

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Retrieve a list of compatible reservation types
    Get-vRAReservationType | Select Name

    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere'

    .EXAMPLE
    # Retrieve a list of compatible reservation types
    Get-vRAReservationType | Select Name

    # Retrieve associated compute resources for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResource -Type 'vSphere (vCenter)'

    .EXAMPLE
    # Retrieve associated compute resources for the vSphere reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Id 75ae3400-beb5-4b0b-895a-0484413c93b1

    .EXAMPLE
    # Retrieve associated compute resources for the vSphere reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Id 75ae3400-beb5-4b0b-895a-0484413c93b1

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Name "Cluster01 (vCenter)"

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Name "Cluster01 (vCenter)"
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,
    
    [parameter(Mandatory=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name
       
    ) 
      
    begin {}
    
    process {   

        try {

            $SchemaClassId = (Get-vRAReservationType -Name $Type).schemaClassId

            switch ($PsCmdlet.ParameterSetName) {

                'ById' { 

                    foreach ($ComputeResourceId in $Id) {

                        $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/computeResource/values"
            
                        Write-Verbose -Message "Preparing POST to $($URI)"

                        $Response = Invoke-vRARestMethod -Method POST -URI "$($URI)" -Body "{}"

                        Write-Verbose -Message "SUCCESS"

                        # --- Get the compute resource by id
                        $ComputeResource = $Response.values | Where-Object {$_.underlyingValue.id -eq $ComputeResourceId}

                        if(!$ComputeResource) {

                            throw "Could not find compute resource with id $($ComputeResourceId)"

                        }

                        [pscustomobject] @{

                            type = $ComputeResource.underlyingValue.type
                            componentId = $ComputeResource.underlyingValue.componentId
                            classId = $ComputeResource.underlyingValue.classId
                            id = $ComputeResource.underlyingValue.id
                            label = $ComputeResource.underlyingValue.label

                        }

                    }

                    break

                }

                'ByName' {

                    foreach ($ComputeResourceName in $Name) {

                        $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/computeResource/values"
            
                        Write-Verbose -Message "Preparing POST to $($URI)"

                        $Response = Invoke-vRARestMethod -Method POST -URI "$($URI)" -Body "{}"

                        Write-Verbose -Message "SUCCESS"

                        # --- Get the compute resource by name
                        $ComputeResource = $Response.values | Where-Object {$_.underlyingValue.label -eq $ComputeResourceName}

                        if(!$ComputeResource) {

                            throw "Could not find compute resource with name $($ComputeResourceName)"

                        }

                        [pscustomobject] @{

                            type = $ComputeResource.underlyingValue.type
                            componentId = $ComputeResource.underlyingValue.componentId
                            classId = $ComputeResource.underlyingValue.classId
                            id = $ComputeResource.underlyingValue.id
                            label = $ComputeResource.underlyingValue.label

                        }

                    }

                    break                                          
        
                }

                'Standard' {

                    $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/computeResource/values"

                    Write-Verbose -Message "Preparing GET to $($URI)"

                    $Response = Invoke-vRARestMethod -Method POST -URI $URI -Body "{}"

                    # --- Return all compute resources
                    foreach ($ComputeResource in $Response.values) {

                        [pscustomobject] @{

                            type = $ComputeResource.underlyingValue.type
                            componentId = $ComputeResource.underlyingValue.componentId
                            classId = $ComputeResource.underlyingValue.classId
                            id = $ComputeResource.underlyingValue.id
                            label = $ComputeResource.underlyingValue.label

                        }                
                
                    }            

                    break
    
                }

            }
           
        }
        catch [Exception]{
        
            throw

        }
        
    }   
     
}

<#
    - Function: Get-vRAReservationComputeResourceMemory
#>

function Get-vRAReservationComputeResourceMemory {
<#
    .SYNOPSIS
    Get available memory for a compute resource
    
    .DESCRIPTION
    Get available memory for a compute resource

    .PARAMETER Type
    The reservation type
    Valid types vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere, XenServer
    Valid types vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer

    .PARAMETER ComputeResourceId
    The id of the compute resource

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve associated compute resource memory for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResourceMemory -Type 'vSphere' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve associated compute resource memory for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResourceMemory -Type 'vSphere (vCenter)' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ComputeResourceId
       
    )
    
    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    process {         

        try {

            $SchemaClassId = (Get-vRAReservationType -Name $Type).schemaClassId

            # --- Set the body for the POST
            $Body = @"

            {
              "text": "",
              "dependencyValues": {
                "entries": [{
                  "key": "computeResource",
                  "value": {
                    "type": "entityRef",
                    "componentId": null,
                    "classId": "ComputeResource",
                    "id": "$($ComputeResourceId)"
                  }
                }]
              }
            }
"@        
 
            $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/reservationMemory/values"

            Write-Verbose -Message "Preparing POST to $($URI)"

            $Response = Invoke-vRARestMethod -Method POST -URI $URI -Body $Body

            Write-Verbose -Message "SUCCESS"

            if ($Response.values.Count -eq 0) {

                throw "Could not find memory for compute resource $($ComputeResourceId)"

            }

            forEach ($Memory in $Response.values) {

                [pscustomobject] @{

                    Type = $Memory.underlyingValue.type
                    ComponentTypeId = $Memory.underlyingValue.componentTypeId
                    ComponentId = $Memory.underlyingValue.componentId
                    ClassId = $Memory.underlyingValue.classId
                    TypeFilter = $Memory.underlyingValue.typeFilter
                    Values = $Memory.underlyingValue.values

                }

            }
           
        }
        catch [Exception]{
        
            throw

        }
        
    }   
     
}

<#
    - Function: Get-vRAReservationComputeResourceNetwork
#>

function Get-vRAReservationComputeResourceNetwork {
<#
    .SYNOPSIS
    Get available networks for a compute resource
    
    .DESCRIPTION
    Get available network for a compute resource

    .PARAMETER Type
    The reservation type
    Valid types vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere, XenServer
    Valid types vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer

    .PARAMETER ComputeResourceId
    The id of the compute resource
    
    .PARAMETER Name
    The name of the network

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve all associated compute resource networks for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResourceNetwork -Type 'vSphere' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve associated compute resource network for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResourceNetwork -Type 'vSphere' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d -Name VMNetwork

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve associated compute resource network for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResourceNetwork -Type 'vSphere (vCenter)' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d -Name VMNetwork
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ComputeResourceId,
    
    [parameter(Mandatory=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name
       
    )
    
    begin {}
    
    process {        

        try {

            $SchemaClassId = (Get-vRAReservationType -Name $Type).schemaClassId

            # --- Set the body for the POST
            $Body = @"

            {
              "text": "",
              "dependencyValues": {
                "entries": [{
                  "key": "computeResource",
                  "value": {
                    "type": "entityRef",
                    "componentId": null,
                    "classId": "ComputeResource",
                    "id": "$($ComputeResourceId)"
                  }
                }]
              }
            }
"@
        
            switch ($PsCmdlet.ParameterSetName) {

                'ByName' { 

                    foreach ($NetworkName in $Name) {

                        $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/reservationNetworks/values"
            
                        Write-Verbose -Message "Preparing POST to $($URI)"

                        $Response = Invoke-vRARestMethod -Method POST -URI "$($URI)" -Body $Body

                        Write-Verbose -Message "SUCCESS"

                        # --- Get the network resource by name
                        $Network = $Response.values | Where-Object {$_.label -eq $NetworkName}

                        if(!$Network) {

                            throw "Could not find network with name $($NetworkName)"

                        }

                        [pscustomobject] @{

                            Type = $Network.underlyingValue.type
                            ComponentTypeId = $Network.underlyingValue.componentTypeId
                            ComponentId = $Network.underlyingValue.componentId
                            ClassId = $Network.underlyingValue.classId
                            TypeFilter = $Network.underlyingValue.TypeFilter
                            Values = $Network.underlyingValue.values

                        }

                    }

                    break

                }

                'Standard' {

                    $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/reservationNetworks/values"

                    Write-Verbose -Message "Preparing POST to $($URI)"

                    $Response = Invoke-vRARestMethod -Method POST -URI $URI -Body $Body

                    Write-Verbose -Message "SUCCESS"

                    # --- Return all networks 
                    foreach ($Network in $Response.values) {

                        [pscustomobject] @{
                        
                            Type = $Network.underlyingValue.type
                            Name = $Network.label
                            ComponentTypeId = $Network.underlyingValue.componentTypeId
                            ComponentId = $Network.underlyingValue.componentId
                            ClassId = $Network.underlyingValue.classId
                            TypeFilter = $Network.underlyingValue.TypeFilter
                            Values = $Network.underlyingValue.values

                        }                
                
                    }            

                    break
    
                }

            }
           
        }
        catch [Exception]{
        
            throw

        }
        
    }   
     
}

<#
    - Function: Get-vRAReservationComputeResourceResourcePool
#>

function Get-vRAReservationComputeResourceResourcePool {
<#
    .SYNOPSIS
    Get available resource pools for a compute resource
    
    .DESCRIPTION
    Get available resource pools for a compute resource

    .PARAMETER Type
    The reservation type
    Valid types vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere, XenServer
    Valid types vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer

    .PARAMETER ComputeResourceId
    The id of the compute resource

    .PARAMETER Name
    The name of the resource pool

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve all associated compute resource resource pools for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResourceResourcePool -Type vSphere -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve associated compute resource resource pool for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResourceResourcePool -Type 'vSphere' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d -Name ResourcePool1

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve associated compute resource resource pool for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResourceResourcePool -Type 'vSphere (vCenter)' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d -Name ResourcePool1
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ComputeResourceId,
    
    [parameter(Mandatory=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name
       
    )
    
    begin {}
    
    process {        

        try {

            $SchemaClassId = (Get-vRAReservationType -Name $Type).schemaClassId

            # --- Set the body for the POST
            $Body = @"

            {
              "text": "",
              "dependencyValues": {
                "entries": [{
                  "key": "computeResource",
                  "value": {
                    "type": "entityRef",
                    "componentId": null,
                    "classId": "ComputeResource",
                    "id": "$($ComputeResourceId)"
                  }
                }]
              }
            }
"@
        
            switch ($PsCmdlet.ParameterSetName) {

                'ByName' { 

                    foreach ($ResourcePoolName in $Name) {

                        $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/resourcePool/values"
            
                        Write-Verbose -Message "Preparing POST to $($URI)"

                        $Response = Invoke-vRARestMethod -Method POST -URI "$($URI)" -Body $Body

                        Write-Verbose -Message "SUCCESS"

                        # --- Get the resource pool by name
                        $ResourcePool = $Response.values | Where-Object {$_.label -eq $ResourcePoolName}

                        if(!$ResourcePool) {

                            throw "Could not find resource pool with name $($ResourcePoolName)"

                        }

                        [pscustomobject] @{

                            Type = $ResourcePool.underlyingValue.type
                            ComponentId = $ResourcePool.underlyingValue.componentId
                            ClassId = $ResourcePool.underlyingValue.classId
                            Id = $ResourcePool.underlyingValue.id
                            Label = $ResourcePool.underlyingValue.label

                        }

                    }

                    break

                }

                'Standard' {

                    $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/resourcePool/values"

                    Write-Verbose -Message "Preparing POST to $($URI)"

                    $Response = Invoke-vRARestMethod -Method POST -URI $URI -Body $Body

                    Write-Verbose -Message "SUCCESS"

                    # --- Return all resource pools
                    foreach ($ResourcePool in $Response.values) {

                        [pscustomobject] @{
                        
                            Type = $ResourcePool.underlyingValue.type
                            ComponentId = $ResourcePool.underlyingValue.componentId
                            ClassId = $ResourcePool.underlyingValue.classId
                            Id = $ResourcePool.underlyingValue.id
                            Label = $ResourcePool.underlyingValue.label

                        }                
                
                    }            

                    break
    
                }

            }
           
        }
        catch [Exception]{
        
            throw

        }  
        
    } 
     
}

<#
    - Function: Get-vRAReservationComputeResourceStorage
#>

function Get-vRAReservationComputeResourceStorage {
<#
    .SYNOPSIS
    Get available storage for a compute resource
    
    .DESCRIPTION
    Get available storage for a compute resource

    .PARAMETER Type
    The reservation type
    Valid types vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere, XenServer
    Valid types vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer
    
    .PARAMETER ComputeResourceId
    The id of the compute resource
    
    .PARAMETER Name
    The name of the storage

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve all associated compute resource storage for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResourceStorage -Type 'vSphere' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResource -Type 'vSphere' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve associated compute resource storage for the desired reservation type in vRA 7.1
    Get-vRAReservationComputeResourceStorage -Type 'vSphere' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d -Name DataStore01

    .EXAMPLE
    # Retrieve associated compute resources for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Name 'Cluster01 (vCenter)' | Select-Object -ExpandProperty Id

    # Retrieve associated compute resource storage for the desired reservation type in vRA 7.2 and later
    Get-vRAReservationComputeResourceStorage -Type 'vSphere (vCenter)' -ComputeResourceId 0c0a6d46-4c37-4b82-b427-c47d026bf71d -Name DataStore01
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ComputeResourceId,
    
    [parameter(Mandatory=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name
       
    )

    begin {}

    process {

        try {

            $SchemaClassId = (Get-vRAReservationType -Name $Type).schemaClassid

            # --- Set the body for the POST
            $Body = @"

            {
              "text": "",
              "dependencyValues": {
                "entries": [{
                  "key": "computeResource",
                  "value": {
                    "type": "entityRef",
                    "componentId": null,
                    "classId": "ComputeResource",
                    "id": "$($ComputeResourceId)"
                  }
                }]
              }
            }
"@
        
            switch ($PsCmdlet.ParameterSetName) {

                'ByName' { 

                    foreach ($StorageName in $Name) {

                        $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/reservationStorages/values"
            
                        Write-Verbose -Message "Preparing POST to $($URI)"

                        $Response = Invoke-vRARestMethod -Method POST -URI "$($URI)" -Body $Body

                        Write-Verbose -Message "SUCCESS"

                        # --- Get the storage resource by name
                        $Storage = $Response.values | Where-Object {$_.label -eq $StorageName}

                        if(!$Storage) {

                            throw "Could not find storage with name $($StorageName)"

                        }

                        [pscustomobject] @{

                            Type = $Storage.underlyingValue.type
                            ComponentTypeId = $Storage.underlyingValue.componentTypeId
                            ComponentId = $Storage.underlyingValue.componentId
                            ClassId = $Storage.underlyingValue.classId
                            TypeFilter = $Storage.underlyingValue.TypeFilter
                            Values = $Storage.underlyingValue.values

                        }

                    }

                    break

                }

                'Standard' {

                    $URI = "/reservation-service/api/data-service/schema/$($SchemaClassId)/default/reservationStorages/values"

                    Write-Verbose -Message "Preparing POST to $($URI)"

                    $Response = Invoke-vRARestMethod -Method POST -URI $URI -Body $Body

                    Write-Verbose -Message "SUCCESS"

                    # --- Return all storage 
                    foreach ($Storage in $Response.values) {

                        [pscustomobject] @{
                        
                            Type = $Storage.underlyingValue.type
                            Name = $Storage.label
                            ComponentTypeId = $Storage.underlyingValue.componentTypeId
                            ComponentId = $Storage.underlyingValue.componentId
                            ClassId = $Storage.underlyingValue.classId
                            TypeFilter = $Storage.underlyingValue.TypeFilter
                            Values = $Storage.underlyingValue.values

                        }                
                
                    }            

                    break
    
                }

            }
           
        }
        catch [Exception]{
        
            throw

        }
        
    }   
     
}

<#
    - Function: Get-vRAReservationPolicy
#>

function Get-vRAReservationPolicy {
<#
    .SYNOPSIS
    Retrieve vRA Reservation Policies
    
    .DESCRIPTION
    Retrieve vRA Reservation Policies
    
    .PARAMETER Id
    Specify the ID of a Reservation Policy

    .PARAMETER Name
    Specify the Name of a Reservation Policy

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAReservationPolicy
    
    .EXAMPLE
    Get-vRAReservationPolicy -Id "068afd10-560f-4360-aa52-786a28573fdc"

    .EXAMPLE
    Get-vRAReservationPolicy -Name "ReservationPolicy01","ReservationPolicy02"
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,         

    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name, 
    
    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100" 
    )

    try {                
        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  {                
                
                foreach ($ReservationPolicyId in $Id){

                    $URI = "/reservation-service/api/reservations/policies/$($ReservationPolicyId)"

                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI

                    [pscustomobject]@{

                        Name = $Response.name
                        Id = $Response.id                
                        Description = $Response.description
                        CreatedDate = $Response.createdDate
                        LastUpdated = $Response.lastUpdated
                        ReservationPolicyTypeId = $Response.reservationPolicyTypeId
                    }
                }                              
            
                break
            }

            "ByName"  {                

                foreach ($ReservationPolicyName in $Name){

                    $URI = "/reservation-service/api/reservations/policies?`$filter=name%20eq%20'$($ReservationPolicyName)'&reservationPolicyTypeId%20eq%20'Infrastructure.Reservation.Policy.ComputeResource'"

                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI

                    foreach ($ReservationPolicy in $Response.content){

                        [pscustomobject]@{

                            Name = $ReservationPolicy.name
                            Id = $ReservationPolicy.id                
                            Description = $ReservationPolicy.description
                            CreatedDate = $ReservationPolicy.createdDate
                            LastUpdated = $ReservationPolicy.lastUpdated
                            ReservationPolicyTypeId = $ReservationPolicy.reservationPolicyTypeId
                        }
                    }
                }
                
                break
            }

            "Standard"  {

                $URI = "/reservation-service/api/reservations/policies?`$filter=reservationPolicyTypeId%20eq%20'Infrastructure.Reservation.Policy.ComputeResource'&limit=$($Limit)"

                # --- Run vRA REST Request
                $Response = Invoke-vRARestMethod -Method GET -URI $URI

                foreach ($ReservationPolicy in $Response.content){

                    [pscustomobject]@{

                        Name = $ReservationPolicy.name
                        Id = $ReservationPolicy.id                
                        Description = $ReservationPolicy.description
                        CreatedDate = $ReservationPolicy.createdDate
                        LastUpdated = $ReservationPolicy.lastUpdated
                        ReservationPolicyTypeId = $ReservationPolicy.reservationPolicyTypeId
                    }
                }
                
                break
            }
        }
    }
    catch [Exception]{

        throw
    }
}

<#
    - Function: Get-vRAReservationTemplate
#>

function Get-vRAReservationTemplate {
<#
    .SYNOPSIS
    Get a reservation json template
    
    .DESCRIPTION
    Get a reservation json template. This template can then be used to create a new reservation with the same properties
    
    .PARAMETER Id
    The id of the reservation
    
    .PARAMETER OutFile
    The path to an output file

    .INPUTS
    System.String

    .OUTPUTS
    System.String

    .EXAMPLE
    Get-vRAReservationTemplate -Id 75ae3400-beb5-4b0b-895a-0484413c93b1 -OutFile C:\Reservation.json

    .EXAMPLE
    Get-vRAReservation -Name Reservation1 | Get-vRAReservationTemplate -OutFile C:\Reservation.json

    .EXAMPLE
    Get-vRAReservation -Name Reservation1 | Get-vRAReservationTemplate

#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.String')]

    Param (

    [parameter(Mandatory=$true, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [String]$Id,
    
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$OutFile
       
    )    

    try {


        $URI = "/reservation-service/api/reservations/$($Id)"
            
        Write-Verbose -Message "Preparing GET to $($URI)"

        $Response = Invoke-vRARestMethod -Method GET -URI "$($URI)"

        Write-Verbose -Message "SUCCESS"

        # --- Remove the id from the response
        $Response.PSObject.Properties.Remove("id")

        if ($PSBoundParameters.ContainsKey("OutFile")) {

            Write-Verbose -Message "Outputting response to $($OutFile)"

            # --- Output the response to file
            $Response | ConvertTo-Json -Depth 100 | Out-File -FilePath $OutFile -Force

        }
        else {

            # --- Return the response
            $Response | ConvertTo-Json -Depth 100

        }
           
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRAReservationType
#>

function Get-vRAReservationType {
<#
    .SYNOPSIS
    Get supported Reservation Types
    
    .DESCRIPTION
    Get supported Reservation Types

    .PARAMETER Id
    The id of the Reservation Type
    
    .PARAMETER Name
    The name of the Reservation Type
    Valid names vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere,XenServer
    Valid names vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .PARAMETER Page
    The page of response to return. All pages are retuend by default.

    .INPUTS
    System.String.
    System.Int.

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    # Get all available Reservation Types
    Get-vRAReservationType

    .EXAMPLE
    # Get the vSphere Reservation Type in vRA 7.1
    Get-vRAReservationType -Name "vSphere"

    .EXAMPLE
    # Get the vSphere Reservation Type in vRA 7.2 and later
    Get-vRAReservationType -Name "vSphere (vCenter)"

    .EXAMPLE
    Get-vRAReservationType -Name "vCloud Director"

    .EXAMPLE
    Get-vRAReservationType -Id "Infrastructure.Reservation.Cloud.vCloud"
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject' , 'System.Object[]')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,
    
    [parameter(Mandatory=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name,    
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Limit = "100",
 
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Page = 1
       
    )    

    try {

        switch ($PsCmdlet.ParameterSetName) {

            'ById' { 

                foreach ($ReservationTypeId in $Id) {

                    $URI = "/reservation-service/api/reservations/types/$($ReservationTypeId)"
            
                    Write-Verbose -Message "Preparing GET to $($URI)"

                    $Response = Invoke-vRARestMethod -Method GET -URI "$($URI)"

                    Write-Verbose -Message "SUCCESS"

                    if ($Response.Count -eq 0) {

                        throw "Could not find reservationType $($ReservationTypeId)"

                    }

                    [pscustomobject] @{

                        CreatedDate = $Response.createdDate
                        LastUpdated = $Response.LastUpdated
                        Version = $Response.version
                        Id = $Response.id
                        Name = $Response.name
                        Description = $Response.description
                        Category = $Response.category
                        ServiceTypeId = $Response.serviceTypeId
                        TenantId = $Response.tenantId
                        FormReference = $Response.formReference
                        SchemaClassId = $Response.schemaClassId
                        AlertTypes = $Response.alertTypes

                    }

                }

                break

            }

            'ByName' {

                foreach ($ReservationTypeName in $Name) {
            
                    $URI = "/reservation-service/api/reservations/types?`$filter=name%20eq%20'$($ReservationTypeName)'"
            
                    Write-Verbose -Message "Preparing GET to $($URI)"

                    $Response = Invoke-vRARestMethod -Method GET -URI "$($URI)"

                    Write-Verbose -Message "SUCCESS"

                    if ($Response.content.Count -eq 0) {

                        throw "Could not find reservation type $($ReservationTypeName)"

                    }

                    [pscustomobject] @{

                        CreatedDate = $Response.content.createdDate
                        LastUpdated = $Response.content.LastUpdated
                        Version = $Response.content.version
                        Id = $Response.content.id
                        Name = $Response.content.name
                        Description = $Response.content.description
                        Category = $Response.content.category
                        ServiceTypeId = $Response.content.serviceTypeId
                        TenantId = $Response.content.tenantId
                        FormReference = $Response.content.formReference
                        SchemaClassId = $Response.content.schemaClassId
                        AlertTypes = $Response.content.alertTypes

                    }
                                      
                }
                
                break                                          
        
            }

            'Standard' {

                $URI = "/reservation-service/api/reservations/types?limit=$($Limit)"

                # --- Make the first request to determine the size of the request
                $Response = Invoke-vRARestMethod -Method GET -URI $URI

                if (!$PSBoundParameters.ContainsKey("Page")){

                    # --- Get every page back
                    $TotalPages = $Response.metadata.totalPages.ToInt32($null)

                }
                else {

                    # --- Set TotalPages to 1
                    $TotalPages = 1

                }

                # --- Initialise an empty array
                $ResponseObject = @()

                while ($true){

                    Write-Verbose -Message "Getting response for page $($Page) of $($Response.metadata.totalPages)"

                    $PagedUri = "$($URI)&page=$($Page)&`$orderby=name%20asc"

                    Write-Verbose -Message "GET : $($PagedUri)"

                    $Response = Invoke-vRARestMethod -Method GET -URI $PagedUri
            
                    Write-Verbose -Message "Paged Response contains $($Response.content.Count) records"

                    foreach ($ReservationType in $Response.content) {

                        [pscustomobject] @{

                            CreatedDate = $ReservationType.createdDate
                            LastUpdated = $ReservationType.LastUpdated
                            Version = $ReservationType.version
                            Id = $ReservationType.id
                            Name = $ReservationType.name
                            Description = $ReservationType.description
                            Category = $ReservationType.category
                            ServiceTypeId = $ReservationType.serviceTypeId
                            TenantId = $ReservationType.tenantId
                            FormReference = $ReservationType.formReference
                            SchemaClassId = $ReservationType.schemaClassId
                            AlertTypes = $ReservationType.alertTypes

                        }

                        $ResponseObject += $Object

                    }

                    # --- Break loop
                    if ($Page -ge $TotalPages) {

                        break

                    }

                    # --- Increment the current page by 1
                    $Page++

                }         

                # --- Return reservation types
                $ResponseObject

                break
    
            }

        }
           
    }
    catch [Exception]{
        
        throw

    }   
     
}

<#
    - Function: Get-vRAStorageReservationPolicy
#>

function Get-vRAStorageReservationPolicy {
<#
    .SYNOPSIS
    Retrieve vRA Storage Reservation Policies
    
    .DESCRIPTION
    Retrieve vRA Storage Reservation Policies
    
    .PARAMETER Id
    Specify the ID of a Storage Reservation Policy

    .PARAMETER Name
    Specify the Name of a Storage Reservation Policy

    .PARAMETER Limit
    The number of entries returned per page from the API. This has a default value of 100.

    .INPUTS
    System.String

    .OUTPUTS
    System.Management.Automation.PSObject.

    .EXAMPLE
    Get-vRAStorageReservationPolicy
    
    .EXAMPLE
    Get-vRAStorageReservationPolicy -Id "068afd10-560f-4360-aa52-786a28573fdc"

    .EXAMPLE
    Get-vRAStorageReservationPolicy -Name "StorageReservationPolicy01","StorageReservationPolicy02"
#>
[CmdletBinding(DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,         

    [parameter(Mandatory=$true,ValueFromPipeline=$false,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name, 
    
    [parameter(Mandatory=$false,ValueFromPipeline=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$Limit = "100" 
    )

    try {                
        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  {                
                
                foreach ($StorageReservationPolicyId in $Id){

                    $URI = "/reservation-service/api/reservations/policies/$($StorageReservationPolicyId)"

                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI

                    [pscustomobject]@{

                        Name = $Response.name
                        Id = $Response.id                
                        Description = $Response.description
                        CreatedDate = $Response.createdDate
                        LastUpdated = $Response.lastUpdated
                        ReservationPolicyTypeId = $Response.reservationPolicyTypeId
                    }
                }                              
            
                break
            }

            "ByName"  {                

                foreach ($StorageReservationPolicyName in $Name){

                    $URI = "/reservation-service/api/reservations/policies?`$filter=name%20eq%20'$($StorageReservationPolicyName)'&reservationPolicyTypeId%20eq%20'Infrastructure.Reservation.Policy.Storage'"

                    # --- Run vRA REST Request
                    $Response = Invoke-vRARestMethod -Method GET -URI $URI

                    foreach ($StorageReservationPolicy in $Response.content){

                        [pscustomobject]@{

                            Name = $StorageReservationPolicy.name
                            Id = $StorageReservationPolicy.id                
                            Description = $StorageReservationPolicy.description
                            CreatedDate = $StorageReservationPolicy.createdDate
                            LastUpdated = $StorageReservationPolicy.lastUpdated
                            ReservationPolicyTypeId = $StorageReservationPolicy.reservationPolicyTypeId
                        }
                    }
                }
                
                break
            }

            "Standard"  {

                $URI = "/reservation-service/api/reservations/policies?`$filter=reservationPolicyTypeId%20eq%20'Infrastructure.Reservation.Policy.Storage'&limit=$($Limit)"

                # --- Run vRA REST Request
                $Response = Invoke-vRARestMethod -Method GET -URI $URI

                foreach ($StorageReservationPolicy in $Response.content){

                    [pscustomobject]@{

                        Name = $StorageReservationPolicy.name
                        Id = $StorageReservationPolicy.id                
                        Description = $StorageReservationPolicy.description
                        CreatedDate = $StorageReservationPolicy.createdDate
                        LastUpdated = $StorageReservationPolicy.lastUpdated
                        ReservationPolicyTypeId = $StorageReservationPolicy.reservationPolicyTypeId
                    }
                }
                
                break
            }
        }
    }
    catch [Exception]{

        throw
    }
}

<#
    - Function: New-vRAReservation
#>

function New-vRAReservation {
<#
    .SYNOPSIS
    Create a new reservation

    .DESCRIPTION
    Create a new reservation

    .PARAMETER Type
    The reservation type
    Valid types vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere, XenServer
    Valid types vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer

    .PARAMETER Name
    The name of the reservation

    .PARAMETER Tenant
    The tenant that will own the reservation

    .PARAMETER BusinessGroup
    The business group that will be associated with the reservation

    .PARAMETER ReservationPolicy
    The reservation policy that will be associated with the reservation

    .PARAMETER Priority
    The priority of the reservation

    .PARAMETER ComputeResourceId
    The compute resource that will be associated with the reservation

    .PARAMETER Quota
    The number of machines that can be provisioned in the reservation

    .PARAMETER MemoryGB
    The amount of memory available to this reservation

    .PARAMETER Storage
    The storage that will be associated with the reservation

    .PARAMETER Network
    The network that will be associated with this reservation

    .PARAMETER ResourcePool
    The resource pool that will be associated with this reservation

    .PARAMETER EnableAlerts
    Enable alerts

    .PARAMETER EmailBusinessGroupManager
    Email the alerts to the business group manager

    .PARAMETER AlertRecipients
    The recipients that will recieve email alerts

    .PARAMETER StorageAlertPercentageLevel
    The threshold for storage alerts

    .PARAMETER MemoryAlertPercentageLevel
    The threshold for memory alerts

    .PARAMETER CPUAlertPercentageLevel
    The threshold for cpu alerts

    .PARAMETER MachineAlertPercentageLevel
    The threshold for machine alerts

    .PARAMETER AlertReminderFrequency
    Alert frequency in days

    .PARAMETER JSON
    Body text to send in JSON format

    .PARAMETER NewName
    If passing a JSON payload NewName can be used to set the reservation name

    .INPUTS
    System.String
    System.Int
    System.Management.Automation.SwitchParameter
    System.Management.Automation.PSObject

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # --- Create a new Reservation in vRA 7.1
    # --- Get the compute resource id
    $ComputeResource = Get-vRAReservationComputeResource -Type 'vSphere' -Name 'Cluster01 (vCenter)'

    # --- Get the network definition
    $NetworkDefinitionArray = @()
    $Network1 = New-vRAReservationNetworkDefinition -Type 'vSphere' -ComputeResourceId $ComputeResource.Id -NetworkPath 'VM Network' -NetworkProfile 'Test-Profile'
    $NetworkDefinitionArray += $Network1

    # --- Get the storage definition
    $StorageDefinitionArray = @()
    $Storage1 = New-vRAReservationStorageDefinition -Type 'vSphere' -ComputeResourceId $ComputeResource.Id -Path 'Datastore1' -ReservedSizeGB 10 -Priority 0 
    $StorageDefinitionArray += $Storage1

    # --- Set the parameters and create the reservation
    $Param = @{

        Type = 'vSphere'
        Name = 'Reservation01'
        Tenant = 'Tenant01'
        BusinessGroup = 'Default Business Group[Tenant01]'
        ReservationPolicy = 'ReservationPolicy1'
        Priority = 0
        ComputeResourceId = $ComputeResource.Id
        Quota = 0
        MemoryGB = 2048
        Storage = $StorageDefinitionArray
        ResourcePool = 'Resources'
        Network = $NetworkDefinitionArray
        EnableAlerts = $false

    }

    New-vRAReservation @Param -Verbose

    .EXAMPLE
    # --- Create a new Reservation in vRA 7.2 and later
    # --- Get the compute resource id
    $ComputeResource = Get-vRAReservationComputeResource -Type 'vSphere (vCenter)' -Name 'Cluster01 (vCenter)'

    # --- Get the network definition
    $NetworkDefinitionArray = @()
    $Network1 = New-vRAReservationNetworkDefinition -Type 'vSphere (vCenter)' -ComputeResourceId $ComputeResource.Id -NetworkPath 'VM Network' -NetworkProfile 'Test-Profile'
    $NetworkDefinitionArray += $Network1

    # --- Get the storage definition
    $StorageDefinitionArray = @()
    $Storage1 = New-vRAReservationStorageDefinition -Type 'vSphere (vCenter)' -ComputeResourceId $ComputeResource.Id -Path 'Datastore1' -ReservedSizeGB 10 -Priority 0 
    $StorageDefinitionArray += $Storage1

    # --- Set the parameters and create the reservation
    $Param = @{

        Type = 'vSphere (vCenter)'
        Name = 'Reservation01'
        Tenant = 'Tenant01'
        BusinessGroup = 'Default Business Group[Tenant01]'
        ReservationPolicy = 'ReservationPolicy1'
        Priority = 0
        ComputeResourceId = $ComputeResource.Id
        Quota = 0
        MemoryGB = 2048
        Storage = $StorageDefinitionArray
        ResourcePool = 'Resources'
        Network = $NetworkDefinitionArray
        EnableAlerts = $false

    }

    New-vRAReservation @Param -Verbose
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Tenant = $Global:vRAConnection.Tenant,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$BusinessGroup,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$ReservationPolicy,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Priority = 0,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$ComputeResourceId,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Quota = 0,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$MemoryGB,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Storage,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [PSObject[]]$Network,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$ResourcePool,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Switch]$EnableAlerts = $False,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Switch]$EmailBusinessGroupManager = $False,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$AlertRecipients,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$StorageAlertPercentageLevel = 80,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$MemoryAlertPercentageLevel = 80,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$CPUAlertPercentageLevel = 80,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$MachineAlertPercentageLevel = 80,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$AlertReminderFrequency = 20,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON,

    [parameter(Mandatory=$false,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$NewName

    )
 
    begin {
        # --- Test for vRA API version
        xRequires -Version 7.0
    }
    
    process {

        try {

            switch ($PSCmdlet.ParameterSetName){

                'JSON' {

                    # --- Handle JSON PARAM
                    $Body = $JSON
                    $Data = ($JSON | ConvertFrom-Json)      
                    $Name = $Data.name

                    # --- if a new name has been passed set it
                    if ($PSBoundParameters.ContainsKey("NewName")){

                        Write-Verbose -Message "Setting reservaiton name to $($NewName)"

                        $Data.name = $NewName

                        $Body = $Data | ConvertTo-Json -Depth 100 -Compress

                    }

                    break

                }

                'Standard' {

                    Write-Verbose -Message "Preparing reservation payload"
                  
                    $ReservationTypeId = (Get-vRAReservationType -Name $Type).id

                    $BusinessGroupId = (Get-vRABusinessGroup -TenantId $Tenant -Name $BusinessGroup).id

                    # --- Enable alerts
                    # --- Convert boolean to a string value for the payload
                    if ($EnableAlerts) {

                        $EnableAlertsAsString = "true"

                    }
                    else {

                        $EnableAlertsAsString = "false"

                    }

                    # --- Email business group manager
                    # --- Convert boolean to a string value for the payload
                    if ($EmailBusinessGroupManager) {

                        $EmailBusinessGroupManagerAsString = "true"

                    }
                    else {

                        $EmailBusinessGroupManagerAsString = "false"

                    }


                    Write-Verbose -Message "Reservation name is $($Name)"
                    Write-Verbose -Message "ReservationTypeId for $($Type) is $($ReservationTypeId)"
                    Write-Verbose -Message "Tenant is $($Tenant)"
                    Write-Verbose -Message "BusinessGroupId for $($BusinessGroup) is $($BusinessGroupId)"
                    Write-Verbose -Message "Priority is $($Priority)"
                    Write-Verbose -Message "Alerts enabled: $($EnableAlertsAsString)"
                    Write-Verbose -Message "Email business group manager: $($EmailBusinessGroupManagerAsString)"

                    $Template = @"
                        {
                          "name": "$($Name)",
                          "reservationTypeId": "$($ReservationTypeId)",
                          "tenantId": "$($Tenant)",
                          "subTenantId": "$($BusinessGroupId)",
                          "enabled": true,
                          "priority": $($Priority),
                          "reservationPolicyId": null,
                          "alertPolicy": {
                            "enabled": $($EnableAlertsAsString),
                            "frequencyReminder": $($AlertReminderFrequency),
                            "emailBgMgr": $($EmailBusinessGroupManagerAsString),
                            "recipients": [],
                            "alerts": []
                          },
                          "extensionData": {
                            "entries": []
                          }
                        }
"@

                    # --- Convert the body to an object and begin adding extensionData
                    $ReservationObject = $Template | ConvertFrom-Json

                    if ($PSBoundParameters.ContainsKey("ReservationPolicy")){

                        $ReservationPolicyId = (Get-vRAReservationPolicy -Name $ReservationPolicy).id
                        $ReservationObject.reservationPolicyId = $ReservationPolicyId      
                        Write-Verbose -Message "ReservationPolicyId for $($ReservationPolicy) is $($ReservationPolicyId)"

                    }

                    if ($EnableAlerts -eq "TRUE" -and $PSBoundParameters.ContainsKey("AlertRecipients")) {

                        foreach ($Recipient in $AlertRecipients) {

                            $ReservationObject.alertPolicy.recipients += $Recipient

                        }

                    }

                    switch ($PSBoundParameters.Type) {

                        {$_ -in 'vSphere','vSphere (vCenter)'} {
                            
                            # ---
                            # --- Alert Policy
                            # ---

                            $AlertsTemplate = @"

                                [

                                    {
                                        "alertPercentLevel": $($StorageAlertPercentageLevel),
                                        "referenceResourceId": "storage",
                                        "id": "storage"
                                    },
                                    {
                                        "alertPercentLevel": $($MemoryAlertPercentageLevel),
                                        "referenceResourceId": "memory",
                                        "id": "memory"
                                    },
                                    {
                                        "alertPercentLevel": $($CPUAlertPercentageLevel),
                                        "referenceResourceId": "cpu",
                                        "id": "cpu"
                                    },
                                    {
                                       "alertPercentLevel": $($MachineAlertPercentageLevel),
                                        "referenceResourceId": "machine",
                                        "id": "machine"
                                    }

                                ]
"@
                            
                            $ReservationObject.alertPolicy.alerts += $AlertsTemplate | ConvertFrom-Json                            

                            # --- 
                            # --- Compute Resource
                            # ---

                            Write-Verbose -Message "Adding extensionData for type $($Type)"

                            $ComputeResourceObject = Get-vRAReservationComputeResource -Type $Type -Id $ComputeResourceId

                            Write-Verbose -Message "Found compute resource $($ComputeResourceObject.label) with id $($ComputeResourceId)"

                            $ComputeResourceTemplate = @"

                                {
                                    "key": "computeResource",
                                    "value": {
                                        "type" : "entityRef",
                                        "componentId" : null,
                                        "classId" : "ComputeResource",
                                        "id" : "$($ComputeResourceId)",
                                        "label" : "$($ComputeResourceObject.label)"                  
                            
                                    }

                                }
"@
                    
                            $ReservationObject.extensionData.entries += ($ComputeResourceTemplate | ConvertFrom-Json)

                            # --- 
                            # --- Machine Quota
                            # ---

                            Write-Verbose -Message "Setting machine quota to $($Quota)"

                            $MachineQuotaTemplate = @"
                   
                                {
                                    "key": "machineQuota",
                                    "value": {
                                        "type": "integer",
                                        "value": $($Quota)
                                    }  
                                } 
"@
                                                                 
                            $ReservationObject.extensionData.entries += ($MachineQuotaTemplate | ConvertFrom-Json)

                            # --- 
                            # --- Reservation Networks
                            # ---
                            
                            Write-Verbose -Message "Setting reservation networks"

                            $ReservationNetworksTemplate = @"
                    
                                {
                                    "key": "reservationNetworks",
                                    "value": {
                                        "type": "multiple",
                                        "elementTypeId": "COMPLEX",
                                        "items": []
                                    }
                                }
"@

                            $ReservationNetworks = $ReservationNetworksTemplate | ConvertFrom-Json

                            foreach ($NetworkDefinition in $Network) {

                                $ReservationNetworks.value.items += $NetworkDefinition

                            }

                            $ReservationObject.extensionData.entries += $ReservationNetworks

                            # ---
                            # --- Reservation Storages
                            # ---

                            Write-Verbose -Message "Setting reservation storage"

                            $ReservationStoragesTemplate = @"

                                {
                                    "key":  "reservationStorages",
                                    "value":  {
                                        "type":  "multiple",
                                        "elementTypeId":  "COMPLEX",
                                        "items":  []

                                    }
                                }
"@

                            $ReservationStorages = $ReservationStoragesTemplate | ConvertFrom-Json

                            foreach ($StorageDefinition in $Storage) {

                                $ReservationStorages.value.items += $StorageDefinition

                            }

                            $ReservationObject.extensionData.entries += $ReservationStorages
                   
                            # ---
                            # --- Reservation Memory
                            # ---

                            Write-Verbose -Message "Setting reservation memory"

                            # --- Calculate the memory value in MB

                            $MemoryMB = [Math]::Round(($MemoryGB * 1024 * 1024 * 1024 / 1MB),4,[MidPointRounding]::AwayFromZero)  

                            $ReservationMemoryTemplate = @"

                                {
                                    "key":  "reservationMemory",
                                    "value":  {
                                        "type":  "complex",
                                        "componentTypeId":  "com.vmware.csp.iaas.blueprint.service",
                                        "componentId":  null,
                                        "classId":  "Infrastructure.Reservation.Memory",
                                        "typeFilter":  null,
                                        "values":  {
                                             "entries":  [
                                                {
                                                    "key":  "memoryReservedSizeMb",
                                                    "value":  {
                                                        "type":  "integer",
                                                        "value":  $($MemoryMB)
                                                    }
                                                }
                                            ]
                                        }
                                    }

                                }
"@

                            $ReservationObject.extensionData.entries += ($ReservationMemoryTemplate | ConvertFrom-Json)

                            # --- 
                            # --- Resource Pool
                            # ---

                            if ($PSBoundParameters.ContainsKey("ResourcePool")){

                                Write-Verbose "Setting resource pool"

                                $ResourcePoolObject = Get-vRAReservationComputeResourceResourcePool -Type $Type -ComputeResourceId $ComputeResourceId -Name $Resourcepool

                                $ResourcePoolTemplate = @"
                    
                                    {
                                        "key": "resourcePool",
                                        "value": {
                                            "type": "entityRef",
                                            "componentId": null,
                                            "classId": "ResourcePools",
                                            "id": "$($ResourcePoolObject.Id)",
                                            "label": "$($ResourcePoolObject.Label)"
                                        }
                                    }                     
"@
                    
                                $ReservationObject.extensionData.entries += ($ResourcePoolTemplate | ConvertFrom-Json)                
                                    
                            }


                            break

                        }

                        'vCloud Air' {

                            # ---
                            # --- Alert Policy
                            # ---

                            $AlertsTemplate = @"

                                [

                                    {
                                        "alertPercentLevel": $($StorageAlertPercentageLevel),
                                        "referenceResourceId": "storage",
                                        "id": "storage"
                                    },
                                    {
                                        "alertPercentLevel": $($MemoryAlertPercentageLevel),
                                        "referenceResourceId": "memory",
                                        "id": "memory"
                                    },
                                    {
                                        "alertPercentLevel": $($CPUAlertPercentageLevel),
                                        "referenceResourceId": "cpu",
                                        "id": "cpu"
                                    },
                                    {
                                       "alertPercentLevel": $($MachineAlertPercentageLevel),
                                        "referenceResourceId": "machine",
                                        "id": "machine"
                                    }

                                ]
"@
                            
                            $ReservationObject.alertPolicy.alerts += $AlertsTemplate | ConvertFrom-Json                            

                            # --- 
                            # --- Compute Resource
                            # ---

                            Write-Verbose -Message "Adding extensionData for type $($Type)"

                            $ComputeResourceObject = Get-vRAReservationComputeResource -Type $Type -Id $ComputeResourceId

                            Write-Verbose -Message "Found compute resource $($ComputeResourceObject.label) with id $($ComputeResourceId)"

                            $ComputeResourceTemplate = @"

                                {
                                    "key": "computeResource",
                                    "value": {
                                        "type" : "entityRef",
                                        "componentId" : null,
                                        "classId" : "ComputeResource",
                                        "id" : "$($ComputeResourceId)",
                                        "label" : "$($ComputeResourceObject.label)"                  
                            
                                    }

                                }
"@
                    
                            $ReservationObject.extensionData.entries += ($ComputeResourceTemplate | ConvertFrom-Json)

                            # --- 
                            # --- Machine Quota
                            # ---

                            Write-Verbose -Message "Setting machine quota to $($Quota)"

                            $MachineQuotaTemplate = @"
                   
                                {
                                    "key": "machineQuota",
                                    "value": {
                                        "type": "integer",
                                        "value": $($Quota)
                                    }  
                                } 
"@
                                                                 
                            $ReservationObject.extensionData.entries += ($MachineQuotaTemplate | ConvertFrom-Json)

                            # --- 
                            # --- Reservation Networks
                            # ---
                            
                            Write-Verbose -Message "Setting reservation networks"

                            $ReservationNetworksTemplate = @"
                    
                                {
                                    "key": "reservationNetworks",
                                    "value": {
                                        "type": "multiple",
                                        "elementTypeId": "COMPLEX",
                                        "items": []
                                    }
                                }
"@

                            $ReservationNetworks = $ReservationNetworksTemplate | ConvertFrom-Json

                            foreach ($NetworkDefinition in $Network) {

                                $ReservationNetworks.value.items += $NetworkDefinition

                            }

                            $ReservationObject.extensionData.entries += $ReservationNetworks

                            # ---
                            # --- Reservation Storages
                            # ---

                            Write-Verbose -Message "Setting reservation storage"

                            $ReservationStoragesTemplate = @"

                                {
                                    "key":  "reservationStorages",
                                    "value":  {
                                        "type":  "multiple",
                                        "elementTypeId":  "COMPLEX",
                                        "items":  []

                                    }
                                }
"@

                            $ReservationStorages = $ReservationStoragesTemplate | ConvertFrom-Json

                            foreach ($StorageDefinition in $Storage) {

                                $ReservationStorages.value.items += $StorageDefinition

                            }

                            $ReservationObject.extensionData.entries += $ReservationStorages
                   
                            # ---
                            # --- Reservation Memory
                            # ---

                            Write-Verbose -Message "Setting reservation memory"

                            # --- Calculate the memory value in MB

                            $MemoryMB = [Math]::Round(($MemoryGB * 1024 * 1024 * 1024 / 1MB),4,[MidPointRounding]::AwayFromZero)  

                            $ReservationMemoryTemplate = @"

                                {
                                    "key":  "reservationMemory",
                                    "value":  {
                                        "type":  "complex",
                                        "componentTypeId":  "com.vmware.csp.iaas.blueprint.service",
                                        "componentId":  null,
                                        "classId":  "Infrastructure.Reservation.Memory",
                                        "typeFilter":  null,
                                        "values":  {
                                             "entries":  [
                                                {
                                                    "key":  "memoryReservedSizeMb",
                                                    "value":  {
                                                        "type":  "integer",
                                                        "value":  $($MemoryMB)
                                                    }
                                                }
                                            ]
                                        }
                                    }

                                }
"@

                            $ReservationObject.extensionData.entries += ($ReservationMemoryTemplate | ConvertFrom-Json)

                            break

                        }

                        {$_ -in 'Amazon','Amazon EC2'} {
                        
                            Write-Verbose -Message "Support for this reservation type has not been added"
                            break

                        }

                        'OpenStack' {
                        
                            Write-Verbose -Message "Support for this reservation type has not been added"
                            break

                        }

                        'vCloud Director' {
                        
                            Write-Verbose -Message "Support for this reservation type has not been added"
                            break                        
                        
                        }

                        {$_ -in 'Hyper-V','Hyper-V (Standalone)'} {
                        
                            Write-Verbose -Message "Support for this reservation type has not been added"
                            break                        
                        
                        }

                        {$_ -in 'KVM','KVM (RHEV)'} {
                        
                            Write-Verbose -Message "Support for this reservation type has not been added"
                            break                        
                        
                        }

                        {$_ -in 'SCVMM','Hyper-V (SCVMM)'} {
                        
                            Write-Verbose -Message "Support for this reservation type has not been added"
                            break                        
                        
                        }

                        'XenServer' {
                        
                            Write-Verbose -Message "Support for this reservation type has not been added"
                            break                        
                        
                        }                           

                    }


                    $Body = $ReservationObject | ConvertTo-Json -Depth 100

                }

            }
    
            if ($PSCmdlet.ShouldProcess($Name)){

                $URI = "/reservation-service/api/reservations"
                
                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRAReservation -Name $Name
            }

        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: New-vRAReservationNetworkDefinition
#>

function New-vRAReservationNetworkDefinition {
<#
    .SYNOPSIS
    Creates a new network definition for a reservation.
    
    .DESCRIPTION
    Creates a new network definition for a reservation. This cmdlet is used to create a custom
    complex network object. One or more of these can be added to an array and passed to New-vRAReservation.

    .PARAMETER Type
    The reservation type
    Valid types vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere, XenServer
    Valid types vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer
        
    .PARAMETER ComputeResourceId
    The id of the compute resource

    .PARAMETER NetworkPath
    The network path
    
    .PARAMETER NetworkProfile
    The network profile

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Create a network definition for type vSphere in vRA 7.1
    $NetworkDefinitionArray = @()
    $Network1 = New-vRAReservationNetworkDefinition -Type 'vSphere' -ComputeResourceId 75ae3400-beb5-4b0b-895a-0484413c93b1 -NetworkPath 'VM Network' -NetworkProfile 'Test'
    $NetworkDefinitionArray += $Network1

    .EXAMPLE
    # Create a network definition for type vSphere in vRA 7.2 and later
    $NetworkDefinitionArray = @()
    $Network1 = New-vRAReservationNetworkDefinition -Type 'vSphere (vCenter)' -ComputeResourceId 75ae3400-beb5-4b0b-895a-0484413c93b1 -NetworkPath 'VM Network' -NetworkProfile 'Test'
    $NetworkDefinitionArray += $Network1
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Type,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$ComputeResourceId,

        [Parameter(Mandatory=$true,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$NetworkPath,
        
        [Parameter(Mandatory=$false,ParameterSetName="Standard")]
        [ValidateNotNullOrEmpty()]
        [String]$NetworkProfile

    )    

    begin {
    
    }
    
    process {

        try {

            if ($PSCmdlet.ShouldProcess("ReservationNetworkDefinition")) {

                # --- Define object
                $NetworkDefinitionJSON = @"
        
                    {
                        "type": "complex",
                        "componentTypeId": "com.vmware.csp.iaas.blueprint.service",
                        "componentId": null,
                        "classId": "Infrastructure.Reservation.Network",
                        "typeFilter": null,
                        "values": {
                            "entries": []

                        }

                    }
"@
        
                # --- Convert the networkDefinition json to an object
                $NetworkDefinition = $NetworkDefinitionJSON | ConvertFrom-Json

                # --- Get network information
                $Network = Get-vRAReservationComputeResourceNetwork -Type $Type -ComputeResourceId $ComputeResourceId -Name $NetworkPath

                $Path = ($Network.values.entries | Where-Object {$_.key -eq "networkPath"})

                # --- Add the network path to the network definition
                $NetworkDefinition.values.entries += $Path

                if ($NetworkProfile) {

                    $Response = Invoke-vRARestMethod -Method GET -URI "/iaas-proxy-provider/api/network/profiles?`$filter=name%20eq%20'$($NetworkProfile)'"

                    if ($Response.content.Count -eq 0) {

                        throw "Could not find network profile with name $($NetworkProfile)"

                    }

                    $Profile = $Response.content[0]

                    $NetworkProfileJSON = @"

                        {
                            "key":  "networkProfile",
                            "value":  {
                                        "type":  "entityRef",
                                        "componentId":  null,
                                        "classId":  "Network",
                                        "id":  "$($Profile.id)",
                                        "label":  "$($Profile.name)"
                                    }
                        }
"@

                    $Profile = $NetworkProfileJSON | ConvertFrom-Json 

                    # --- Add the network profile to the network definition
                    $NetworkDefinition.values.entries += $Profile

                }

                $NetworkDefinition

            }

        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}


<#
    - Function: New-vRAReservationPolicy
#>

function New-vRAReservationPolicy {
<#
    .SYNOPSIS
    Create a vRA Reservation Policy
    
    .DESCRIPTION
    Create a vRA Reservation Policy
    
    .PARAMETER Name
    Reservation Policy Name
    
    .PARAMETER Description
    Reservation Policy Description

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRAReservationPolicy -Name ReservationPolicy01 -Description "This is Reservation Policy 01"
    
    .EXAMPLE
    $JSON = @"
    {
      "name": "ReservationPolicy01",
      "description": "This is Reservation Policy 01",
      "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.ComputeResource"
    }
    "@
    $JSON | New-vRAReservationPolicy
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
    
    }
    
    process {
    
        # --- Set Body for REST request depending on ParameterSet
        if ($PSBoundParameters.ContainsKey("JSON")){
        
            $Data = ($JSON | ConvertFrom-Json)
            
            $Body = $JSON
            $Name = $Data.name     
        }
        else {
        
            $Body = @"
            {
                "name": "$($Name)",
                "description": "$($Description)",
                "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.ComputeResource"
            }
"@
        }   
           
        try {
            if ($PSCmdlet.ShouldProcess($Name)){

                $URI = "/reservation-service/api/reservations/policies"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRAReservationPolicy -Name $Name
            }
        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: New-vRAReservationStorageDefinition
#>

function New-vRAReservationStorageDefinition {
<#
    .SYNOPSIS
    Creates a new storage definition for a reservation
    
    .DESCRIPTION
    Creates a new storage definition for a reservation. This cmdlet is used to create a custom
    complex storage object. One or more of these can be added to an array and passed to New-vRAReservation.

    .PARAMETER Type
    The reservation type
    Valid types vRA 7.1 and earlier: Amazon, Hyper-V, KVM, OpenStack, SCVMM, vCloud Air, vCloud Director, vSphere, XenServer
    Valid types vRA 7.2 and later: Amazon EC2, Azure, Hyper-V (SCVMM), Hyper-V (Standalone), KVM (RHEV), OpenStack, vCloud Air, vCloud Director, vSphere (vCenter), XenServer

    .PARAMETER ComputeResourceId
    The id of the compute resource

    .PARAMETER Path
    The storage path
    
    .PARAMETER ReservedSizeGB
    The size in GB of this reservation
    
    .PARAMETER Priority
    The priority of storage 

    .INPUTS
    System.String.
    System.Int.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    # Create a storage definition for type vSphere in vRA 7.1
    $StorageDefinitionArray = @()
    $Storage1 = New-vRAReservationStorageDefinition -Type 'vSphere' -ComputeResourceId 75ae3400-beb5-4b0b-895a-0484413c93b1 -Path 'Datastore01' -ReservedSizeGB 10 -Priority 0 
    $StorageDefinitionArray += $Storage1

    .EXAMPLE
    # Create a storage definition for type vSphere in vRA 7.2 or later
    $StorageDefinitionArray = @()
    $Storage1 = New-vRAReservationStorageDefinition -Type 'vSphere (vCenter)' -ComputeResourceId 75ae3400-beb5-4b0b-895a-0484413c93b1 -Path 'Datastore01' -ReservedSizeGB 10 -Priority 0 
    $StorageDefinitionArray += $Storage1
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Type,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$ComputeResourceId,

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Path,
    
    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$ReservedSizeGB,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Priority = 0

    )
   
    begin {
    
    }
    
    process {

        try {

            if ($PSCmdlet.ShouldProcess("ReservationStorageDefinition")) {

                # --- Get storage information
                $Storage = Get-vRAReservationComputeResourceStorage -Type $Type -ComputeResourceId $ComputeResourceId -Name $Path

                $StoragePath = ($Storage.values.entries | Where-Object {$_.key -eq "storagePath"}).value

                $StorageTotalSize = ($Storage.values.entries | Where-Object {$_.key -eq "computeResourceStorageTotalSizeGB"}).value.value.ToInt32($null)

                # --- Validate the requested reservation size
                if ($ReservedSizeGB -gt $StorageTotalSize) {

                throw "Reserved size is greater than the total size of the storage ($($ReservedSizeGB) -> $($StorageTotalSize))"

                }

                $StorageDefinitionJSON = @"
        
                    {
                        "type": "complex",
                        "componentTypeId": "com.vmware.csp.iaas.blueprint.service",
                        "componentId": null,
                        "classId": "Infrastructure.Reservation.Storage",
                        "typeFilter": null,
                        "values": {
                            "entries": [
                                {
                                    "key": "storageReservationPriority",
                                    "value": {
                                        "type": "integer",
                                        "value": $($Priority)
                                    }
                                },
                                {
                                    "key": "storageReservedSizeGB",
                                    "value": {
                                        "type": "integer",
                                        "value": $($ReservedSizeGB)
                                    }
                                },
                                {
                                    "key": "storagePath",
                                    "value": {
                                        "type": "entityRef",
                                        "componentId": null,
                                        "classId": "Storage",
                                        "id": "$($StoragePath.id)",
                                        "label": "$($StoragePath.label)"
                                    }
                                },
                                {
                                    "key": "storageEnabled",
                                    "value": {
                                        "type": "boolean",
                                        "value": true
                                    }
                                }
                            ]

                        }

                    }

"@

                # --- Return the reservation storage definition
                $StorageDefinitionJSON | ConvertFrom-Json
            }

        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}


<#
    - Function: New-vRAStorageReservationPolicy
#>

function New-vRAStorageReservationPolicy {
<#
    .SYNOPSIS
    Create a vRA Storage Reservation Policy
    
    .DESCRIPTION
    Create a vRA Storage Reservation Policy
    
    .PARAMETER Name
    Storage Reservation Policy Name
    
    .PARAMETER Description
    Storage Reservation Policy Description

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    New-vRAStorageReservationPolicy -Name StorageReservationPolicy01 -Description "This is Storage Reservation Policy 01"
    
    .EXAMPLE
    $JSON = @"
    {
      "name": "StorageReservationPolicy01",
      "description": "This is Storage Reservation Policy 01",
      "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.Storage"
    }
    "@
    $JSON | New-vRAStorageReservationPolicy
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="Low",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
    
    }
    
    process {
    
        # --- Set Body for REST request depending on ParameterSet
        if ($PSBoundParameters.ContainsKey("JSON")){
        
            $Data = ($JSON | ConvertFrom-Json)
            
            $Body = $JSON
            $Name = $Data.name     
        }
        else {
        
            $Body = @"
            {
                "name": "$($Name)",
                "description": "$($Description)",
                "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.Storage"
            }
"@
        }   
           
        try {
            if ($PSCmdlet.ShouldProcess($Name)){

                $URI = "/reservation-service/api/reservations/policies"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method POST -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                # --- Output the Successful Result
                Get-vRAStorageReservationPolicy -Name $Name
            }
        }
        catch [Exception]{

            throw
        }
    }
    end {
        
    }
}

<#
    - Function: Remove-vRAReservation
#>

function Remove-vRAReservation {
<#
    .SYNOPSIS
    Remove a reservation
    
    .DESCRIPTION
    Remove a reservation
    
    .PARAMETER Id
    The id of the reservation

    .PARAMETER Name
    The name of the reservation

    .INPUTS
    System.String

    .EXAMPLE
    Remove-vRAReservation -Name Reservation1

    .EXAMPLE
    Remove-vRAReservation -Id 75ae3400-beb5-4b0b-895a-0484413c93b1

    .EXAMPLE
    Get-vRAReservation -Name Reservation1 | Remove-vRAReservation

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="ById")]

    Param (

    [parameter(Mandatory=$true, ValueFromPipelineByPropertyName, ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [parameter(Mandatory=$true, ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name   
       
    )
    
    begin {}
    
    process {    

        try {

            switch ($PSCmdlet.ParameterSetName) {

                'ById' {

                    foreach ($ReservationId in $Id) {

                        if ($PSCmdlet.ShouldProcess($ReservationId)){

                            $URI = "/reservation-service/api/reservations/$($ReservationId)"
            
                            Invoke-vRARestMethod -Method DELETE -URI "$($URI)" -Verbose:$VerbosePreference | Out-Null
                            
                        }

                    }

                    break

                }

                'ByName' {

                    foreach ($ReservationName in $Name) {

                        if ($PSCmdlet.ShouldProcess($ReservationName)){

                            $ReservationId = (Get-vRAReservation -Name $ReservationName).id

                            $URI = "/reservation-service/api/reservations/$($ReservationId)"
            
                            Invoke-vRARestMethod -Method DELETE -URI "$($URI)"  -Verbose:$VerbosePreference | Out-Null

                        }

                    }

                    break

                }
  
            }
    
        }
        catch [Exception]{
        
            throw

        }
        
    }   
     
}

<#
    - Function: Remove-vRAReservationNetwork
#>

function Remove-vRAReservationNetwork {
<#
    .SYNOPSIS
    Remove a network from a reservation
    
    .DESCRIPTION
    Remove a network from a reservation
    
    .PARAMETER Id
    The id of the reservation

    .PARAMETER NetworkPath
    The network path

    .INPUTS
    System.String

    .EXAMPLE
    Get-vRAReservation -Name Reservation01 | Remove-vRAReservationNetwork -NetworkPath "DMZ"

    .EXAMPLE
    Remove-vRAReservationNetwork -Id 8731ceb3-01cd-4dd6-834e-49a9aa8057d8 -NetworkPath

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$NetworkPath          
    )
    
    Begin {}
    
    Process {    

        try {
            # --- Retrieve the reservation
            $URI = "/reservation-service/api/reservations/$($Id)"
            $Reservation = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

            # --- Loop through the reservation object and attempt to find and remove the network path
            :outer foreach ($Entry in $Reservation.extensionData.entries) {
                if ($Entry.key -eq "reservationNetworks") {
                    foreach ($Item in $Entry.value.items) {
                        foreach ($Key in $Item.values.entries){
                            if ($Key.key -eq "networkPath") {
                                if ($Key.value.label -eq $NetworkPath) {
                                    Write-Verbose -Message "Found network path $($NetworkPath) in reservation $($Reservation.name)"
                                    $List = [System.Collections.ArrayList]$Entry.value.items
                                    $List.Remove($Item)
                                    $Entry.value.items = $List
                                    if ($Entry.value.items.Count -eq 0) {
                                        throw "A reservation must have at least one network path selected. Cannot remove $($NetworkPath)"
                                    }
                                    break outer
                                }
                            }
                        }
                    }
                    throw "Could not find network path with name $($NetworkPath)"                                            
                }
            }

            if ($PSCmdlet.ShouldProcess($Id)){

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Reservation | ConvertTo-Json -Depth 100) -Verbose:$VerbosePreference | Out-Null
            }            
        }
        catch [Exception]{
        
            throw $_
        } 
    }

    End{}       
}

<#
    - Function: Remove-vRAReservationPolicy
#>

function Remove-vRAReservationPolicy {
<#
    .SYNOPSIS
    Remove a vRA Reservation Policy
    
    .DESCRIPTION
    Remove a vRA Reservation Policy
    
    .PARAMETER Id
    Reservation Policy ID

    .PARAMETER Name
    Reservation Policy Name

    .INPUTS
    System.String.

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRAReservationPolicy -Id "34ae1d6c-9972-4736-acdb-7ee109ad1dbd"

    .EXAMPLE
    Remove-vRAReservationPolicy -Name "ReservationPolicy01"
    
    .EXAMPLE
    Get-vRAReservationPolicy -Name "ReservationPolicy01" | Remove-vRAReservationPolicy -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="ById")]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name
    )    

    begin {
    
    }
    
    process {    

        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  {

                foreach ($ReservationPolicyId in $Id){
                
                    try {
                        if ($PSCmdlet.ShouldProcess($ReservationPolicyId)){

                            $URI = "/reservation-service/api/reservations/policies/$($ReservationPolicyId)"  

                            # --- Run vRA REST Request
                            Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
                        }
                    }
                    catch [Exception]{

                        throw
                    }
                }
            }
            "ByName"  {

                foreach ($ReservationPolicyName in $Name){
                
                    try {
                        if ($PSCmdlet.ShouldProcess($ReservationPolicyName)){

                            $ReservationPolicy = Get-vRAReservationPolicy -Name $Name

                            if (-not $ReservationPolicy){

                                throw "Reservation Policy with name $($Name) does not exist"
                            }

                            $Id = $ReservationPolicy.Id

                            $URI = "/reservation-service/api/reservations/policies/$($Id)"  

                            # --- Run vRA REST Request
                            Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
                        }
                    }
                    catch [Exception]{

                        throw
                    }
                }
            }            
        }
    }
    end {
        
    }
}

<#
    - Function: Remove-vRAReservationStorage
#>

function Remove-vRAReservationStorage {
<#
    .SYNOPSIS
    Remove a storage from a reservation
    
    .DESCRIPTION
    Remove a storage from a reservation
    
    .PARAMETER Id
    The id of the reservation

    .PARAMETER StoragePath
    The storage path

    .INPUTS
    System.String

    .EXAMPLE
    Get-vRAReservation -Name Reservation01 | Remove-vRAReservationStorage -StoragePath Datastore01

    .EXAMPLE
    Remove-vRAReservationStorage -Id 8731ceb3-01cd-4dd6-834e-49a9aa8057d8 -StoragePath Datastore01

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")]

    Param (

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$StoragePath          
    )
    
    Begin {}
    
    Process {    

        try {
            # --- Retrieve the reservation
            $URI = "/reservation-service/api/reservations/$($Id)"
            $Reservation = Invoke-vRARestMethod -Method GET -URI $URI -Verbose:$VerbosePreference

            # --- Loop through the reservation object and attempt to find and remove the storage path
            :outer foreach ($Entry in $Reservation.extensionData.entries) {
                if ($Entry.key -eq "reservationStorages") {
                    foreach ($Item in $Entry.value.items) {
                        foreach ($Key in $Item.values.entries){
                            if ($Key.key -eq "storagePath") {
                                if ($Key.value.label -eq $StoragePath) {
                                    Write-Verbose -Message "Found storage path $($StoragePath) in reservation $($Reservation.name)"
                                    $List = [System.Collections.ArrayList]$Entry.value.items
                                    $List.Remove($Item)
                                    $Entry.value.items = $List
                                    if ($Entry.value.items.Count -eq 0) {
                                        throw "A reservation must have at least one storage path selected. Cannot remove $($StoragePath)"
                                    }
                                    break outer
                                }
                            }
                        }
                    }
                    throw "Could not find storage path with name $($StoragePath)"                                            
                }
            }

            if ($PSCmdlet.ShouldProcess($Id)){

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Reservation | ConvertTo-Json -Depth 100) -Verbose:$VerbosePreference | Out-Null
            }            
        }
        catch [Exception]{
        
            throw $_
        } 
    }

    End{}       
}

<#
    - Function: Remove-vRAStorageReservationPolicy
#>

function Remove-vRAStorageReservationPolicy {
<#
    .SYNOPSIS
    Remove a vRA Storage Reservation Policy
    
    .DESCRIPTION
    Remove a vRA Storage Reservation Policy
    
    .PARAMETER Id
    Storage Reservation Policy ID

    .PARAMETER Name
    Storage Reservation Policy Name

    .INPUTS
    System.String.

    .OUTPUTS
    None

    .EXAMPLE
    Remove-vRAStorageReservationPolicy -Id "34ae1d6c-9972-4736-acdb-7ee109ad1dbd"

    .EXAMPLE
    Remove-vRAStorageReservationPolicy -Name "StorageReservationPolicy01"
    
    .EXAMPLE
    Get-vRAStorageReservationPolicy -Name "StorageReservationPolicy01" | Remove-vRAStorageReservationPolicy -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="ById")]

    Param (

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Id,

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String[]]$Name
    )    

    begin {
    
    }
    
    process {    

        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  {

                foreach ($StorageReservationPolicyId in $Id){
                
                    try {
                        if ($PSCmdlet.ShouldProcess($StorageReservationPolicyId)){

                            $URI = "/reservation-service/api/reservations/policies/$($StorageReservationPolicyId)"  

                            # --- Run vRA REST Request
                            Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
                        }
                    }
                    catch [Exception]{

                        throw
                    }
                }
            }
            "ByName"  {

                foreach ($StorageReservationPolicyName in $Name){
                
                    try {
                        if ($PSCmdlet.ShouldProcess($StorageReservationPolicyName)){

                            $StorageReservationPolicy = Get-vRAStorageReservationPolicy -Name $Name

                            if (-not $StorageReservationPolicy){

                                throw "Storage Reservation Policy with name $($Name) does not exist"
                            }

                            $Id = $StorageReservationPolicy.Id

                            $URI = "/reservation-service/api/reservations/policies/$($Id)"  

                            # --- Run vRA REST Request
                            Invoke-vRARestMethod -Method DELETE -URI $URI -Verbose:$VerbosePreference | Out-Null
                        }
                    }
                    catch [Exception]{

                        throw
                    }
                }
            }            
        }
    }
    end {
        
    }
}

<#
    - Function: Set-vRAReservation
#>

function Set-vRAReservation {
<#
    .SYNOPSIS
    Set a vRA reservation

    .DESCRIPTION
    Set a vRA reservation

    .PARAMETER Id
    The Id of the reservation

    .PARAMETER Name
    The name of the reservation

    .PARAMETER ReservationPolicy
    The reservation policy that will be associated with the reservation

    .PARAMETER Priority
    The priority of the reservation

    .PARAMETER Enabled
    Enable or disable the reservation

    .PARAMETER Quota
    The number of machines that can be provisioned in the reservation

    .PARAMETER MemoryGB
    The amount of memory available to this reservation

    .PARAMETER ResourcePool
    The resource pool that will be associated with this reservation

    .PARAMETER EnableAlerts
    Enable alerts

    .PARAMETER EmailBusinessGroupManager
    Email the alerts to the business group manager

    .PARAMETER AlertRecipients
    The recipients that will recieve email alerts

    .PARAMETER StorageAlertPercentageLevel
    The threshold for storage alerts

    .PARAMETER MemoryAlertPercentageLevel
    The threshold for memory alerts

    .PARAMETER CPUAlertPercentageLevel
    The threshold for cpu alerts

    .PARAMETER MachineAlertPercentageLevel
    The threshold for machine alerts

    .PARAMETER AlertReminderFrequency
    Alert frequency in days

    .INPUTS
    System.String
    System.Int
    System.Management.Automation.SwitchParameter
    System.Management.Automation.PSObject

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAReservation -Name Reservation01 | Set-vRAReservation -Name Reservation01-Updated

    .EXAMPLE
    Set-vRAReservation -Id 75ae3400-beb5-4b0b-895a-0484413c93b1 -ReservationPolicy "ReservationPolicy01"

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="Standard")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Id,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String]$ReservationPolicy,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Priority = 0,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Switch]$Enabled,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$Quota = 0,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$MemoryGB,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNull()]
    [String]$ResourcePool,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Switch]$EnableAlerts,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Switch]$EmailBusinessGroupManager,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [String[]]$AlertRecipients,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$StorageAlertPercentageLevel,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$MemoryAlertPercentageLevel,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$CPUAlertPercentageLevel,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$MachineAlertPercentageLevel,

    [parameter(Mandatory=$false,ParameterSetName="Standard")]
    [ValidateNotNullOrEmpty()]
    [Int]$AlertReminderFrequency

    )

    begin {

    }

    process {

        try {

            # --- Get the reservation

            $URI = "/reservation-service/api/reservations/$($id)"

            $Reservation = Invoke-vRARestMethod -Method GET -URI $URI

            $ReservationTypeName = (Get-vRAReservationType -Id $Reservation.reservationTypeId).name

            $ComputeResourceId = ($Reservation.extensionData.entries | Where-Object {$_.key -eq "computeResource"}).value.id

            # --- Set generic reservation properties

            if ($PSBoundParameters.ContainsKey("Name")) {

                Write-Verbose -Message "Updating Name: $($Reservation.name) >> $($Name)"

                $Reservation.name = $Name

            }

            if ($PSBoundParameters.ContainsKey("ReservationPolicy")) {

                Write-Verbose -Message "Updating Reservation Policy: $($ReservationPolicy)"

                $ReservationPolicyId = (Get-vRAReservationPolicy -Name $ReservationPolicy).id

                $Reservation.reservationPolicyId = $ReservationPolicyId

            }

            if ($PSBoundParameters.ContainsKey("Priority")) {

                Write-Verbose -Message "Updating Priority: $($Reservation.priority) >> $($Priority)"

                $Reservation.priority = $Priority

            }

            if ($PSBoundParameters.ContainsKey("Enabled")) {

                if ($Enabled) {

                    $BoolAsString = "true"

                }
                else {

                    $BoolAsString = "false"

                }

                Write-Verbose -Message "Updating Reservation Status: $($Reservation.enabled) >> $($BoolAsString)"

                $Reservation.enabled = $BoolAsString

            }

            if ($PSBoundParameters.ContainsKey("EnableAlerts")) {

                if ($EnableAlerts) {

                    $BoolAsString = "true"

                }
                else {

                    $BoolAsString = "false"

                }

                Write-Verbose -Message "Updating Alert Policy Status: $($Reservation.alertPolicy.enabled) >> $($BoolAsString)"

                $Reservation.alertPolicy.enabled = $BoolAsString

            }

            if ($PSBoundParameters.ContainsKey("AlertReminderFrequency")){

                Write-Verbose "Updating Alert Policy Reminder Frequency: $($Reservation.alertPolicy.frequencyReminder) >> $($AlertReminderFrequency)"

                $Reservation.alertPolicy.frequencyReminder = $AlertReminderFrequency

            }

            if ($PSBoundParameters.ContainsKey("AlertRecipients")){

                Write-Verbose -Message "Updating recipients list with $($AlertRecipients.Count) new contact(s)"

                foreach ($Recipient in $AlertRecipients) {

                    $Reservation.alertPolicy.recipients += $Recipient

                }

            }

            if ($PSBoundParameters.ContainsKey("EmailBusinessGroupManager")) {

                if ($EmailBusinessGroupManager) {

                    $BoolAsString = "true"

                }
                else {

                    $BoolAsString = "false"

                }

                Write-Verbose "Updating Email Business Group Manager Status: $($Reservation.alertPolicy.emailBgMgr) >> $($BoolAsString)"

                $Reservation.alertPolicy.emailBgMgr = $BoolAsString

            }

            # --- Set type specific properties

            switch ($ReservationTypeName) {

                {$_ -in 'vSphere','vSphere (vCenter)'} {

                    # ---
                    # --- Alert Policy
                    # ---

                    if ($PSBoundParameters.ContainsKey("StorageAlertPercentageLevel")) {

                        Write-Verbose -Message "Setting Storage Alert Threshold To $($StorageAlertPercentageLevel)"

                        $AlertPolicy = $Reservation.alertPolicy

                        $StorageAlert = $AlertPolicy.alerts |  Where-Object {$_.referenceResourceId -eq "storage"}

                        $StorageAlert.alertPercentLevel = $StorageAlertPercentageLevel

                    }

                    if ($PSBoundParameters.ContainsKey("MemoryAlertPercentageLevel")){

                        Write-Verbose -Message "Setting Memory Alert Threshold To $($MemoryAlertPercentageLevel)"

                        $AlertPolicy = $Reservation.alertPolicy

                        $MemoryAlert = $AlertPolicy.alerts |  Where-Object {$_.referenceResourceId -eq "memory"}

                        $MemoryAlert.alertPercentLevel = $MemoryAlertPercentageLevel

                    }

                    if ($PSBoundParameters.ContainsKey("CPUAlertPercentageLevel")){

                        Write-Verbose -Message "Setting CPU Alert Threshold To $($CPUAlertPercentageLevel)"

                        $AlertPolicy = $Reservation.alertPolicy

                        $CPUAlert = $AlertPolicy.alerts |  Where-Object {$_.referenceResourceId -eq "cpu"}

                        $CPUAlert.alertPercentLevel = $CPUAlertPercentageLevel

                    }

                    if ($PSBoundParameters.ContainsKey("MachineAlertPercentageLevel")){

                        Write-Verbose -Message "Setting Machine Alert Threshold To $($MachineAlertPercentageLevel)"

                        $AlertPolicy = $Reservation.alertPolicy

                        $MachineAlert = $AlertPolicy.alerts |  Where-Object {$_.referenceResourceId -eq "machine"}

                        $MachineAlert.alertPercentLevel = $MachineAlertPercentageLevel

                    }

                    # ---
                    # --- Machine Quota
                    # ---

                    if ($PSBoundParameters.ContainsKey("Quota")) {

                        $MachineQuota = $Reservation.extensionData.entries | Where-Object {$_.key -eq "machineQuota"}

                        Write-Verbose "Updating Machine Quota: $($MachineQuota.value.value) >> $($Quota)"

                        $MachineQuota.value.value = $Quota

                    }

                    # ---
                    # --- Reservation Memory
                    # ---

                    if ($PSBoundParameters.ContainsKey("MemoryGB")) {

                        # --- Calculate the memory value in MB

                        $MemoryMB = [Math]::Round(($MemoryGB * 1024 * 1024 * 1024 / 1MB),4,[MidPointRounding]::AwayFromZero)

                        $ReservationMemory = $Reservation.extensionData.entries | Where-Object {$_.key -eq "reservationMemory"}

                        $MemoryReservedSizeMb = $ReservationMemory.value.values.entries | Where-Object {$_.key -eq "memoryReservedSizeMb"}

                        Write-Verbose "Updating Machine allocated Memory: $($MemoryReservedSizeMb.value.value) >> $($MemoryMB)"

                        $MemoryReservedSizeMb.value.value = $MemoryMB

                    }

                    # ---
                    # --- ResourcPool
                    # ---

                    if ($PSBoundParameters.ContainsKey("ResourcePool")) {

                        # --- Test to see if a resource pool currently exists

                        $ResourcePoolObject = $Reservation.extensionData.entries | Where-Object {$_.key -eq "resourcePool"}

                        if ($ResourcePoolObject) {

                            if ($ResourcePool -eq '') {

                                # --- Remove the resource pool from the reservation

                                Write-Verbose "Removing resource pool"

                                $Reservation.extensionData.entries = $Reservation.extensionData.entries | Where-Object {$_.key -ne "resourcePool"}


                            }
                            else {

                                # --- Update the existing resource pool

                                $NewResourcePool = Get-vRAReservationComputeResourceResourcePool -Type $ReservationTypeName -ComputeResourceId $ComputeResourceId -Name $ResourcePool

                                $ResourcePoolId = $NewResourcePool.id

                                $ResourcePoolLabel = $NewResourcePool.label

                                Write-Verbose "Updating Resource Pool: $($ResourcePoolObject.value.label) >> $($ResourcePool)"

                                $ResourcePoolObject.value.id = $ResourcePoolId

                                $ResourcePoolObject.value.label = $ResourcePoolLabel

                            }

                        }
                        else {

                            Write-Verbose -Message "Setting Resource Pool To $($ResourcePool)"

                            $NewResourcePool = Get-vRAReservationComputeResourceResourcePool -Type $ReservationTypeName -ComputeResourceId $ComputeResourceId -Name $ResourcePool

                            $ResourcePoolTemplate = @"

                                {
                                    "key": "resourcePool",
                                    "value": {
                                        "type": "entityRef",
                                        "componentId": null,
                                        "classId": "ResourcePools",
                                        "id": "$($NewResourcePool.Id)",
                                        "label": "$($NewResourcePool.Label)"
                                    }
                                }
"@

                            $Reservation.extensionData.entries += ($ResourcePoolTemplate | ConvertFrom-Json)

                        }

                    }

                    break
                }

                'vCloud Air' {

                    # ---
                    # --- Alert Policy
                    # ---

                    if ($PSBoundParameters.ContainsKey("StorageAlertPercentageLevel")) {

                        Write-Verbose -Message "Setting Storage Alert Threshold To $($StorageAlertPercentageLevel)"

                        $AlertPolicy = $Reservation.alertPolicy

                        $StorageAlert = $AlertPolicy.alerts |  Where-Object {$_.referenceResourceId -eq "storage"}

                        $StorageAlert.alertPercentLevel = $StorageAlertPercentageLevel

                    }

                    if ($PSBoundParameters.ContainsKey("MemoryAlertPercentageLevel")){

                        Write-Verbose -Message "Setting Memory Alert Threshold To $($MemoryAlertPercentageLevel)"

                        $AlertPolicy = $Reservation.alertPolicy

                        $MemoryAlert = $AlertPolicy.alerts |  Where-Object {$_.referenceResourceId -eq "memory"}

                        $MemoryAlert.alertPercentLevel = $MemoryAlertPercentageLevel

                    }

                    if ($PSBoundParameters.ContainsKey("CPUAlertPercentageLevel")){

                        Write-Verbose -Message "Setting CPU Alert Threshold To $($CPUAlertPercentageLevel)"

                        $AlertPolicy = $Reservation.alertPolicy

                        $CPUAlert = $AlertPolicy.alerts |  Where-Object {$_.referenceResourceId -eq "cpu"}

                        $CPUAlert.alertPercentLevel = $CPUAlertPercentageLevel

                    }

                    if ($PSBoundParameters.ContainsKey("MachineAlertPercentageLevel")){

                        Write-Verbose -Message "Setting Machine Alert Threshold To $($MachineAlertPercentageLevel)"

                        $AlertPolicy = $Reservation.alertPolicy

                        $MachineAlert = $AlertPolicy.alerts |  Where-Object {$_.referenceResourceId -eq "machine"}

                        $MachineAlert.alertPercentLevel = $MachineAlertPercentageLevel

                    }

                    # ---
                    # --- Machine Quota
                    # ---

                    if ($PSBoundParameters.ContainsKey("Quota")) {

                        $MachineQuota = $Reservation.extensionData.entries | Where-Object {$_.key -eq "machineQuota"}

                        Write-Verbose "Updating Machine Quota: $($MachineQuota.value.value) >> $($Quota)"

                        $MachineQuota.value.value = $Quota

                    }

                    # ---
                    # --- Reservation Memory
                    # ---

                    if ($PSBoundParameters.ContainsKey("MemoryGB")) {

                        # --- Calculate the memory value in MB

                        $MemoryMB = [Math]::Round(($MemoryGB * 1024 * 1024 * 1024 / 1MB),4,[MidPointRounding]::AwayFromZero)

                        $ReservationMemory = $Reservation.extensionData.entries | Where-Object {$_.key -eq "reservationMemory"}

                        $MemoryReservedSizeMb = $ReservationMemory.value.values.entries | Where-Object {$_.key -eq "memoryReservedSizeMb"}

                        Write-Verbose "Updating Machine allocated Memory: $($MemoryReservedSizeMb.value.value) >> $($MemoryMB)"

                        $MemoryReservedSizeMb.value.value = $MemoryMB

                    }

                    break

                }

                'Amazon' {

                    Write-Warning -Message "Support for Reservation type $ReservationTypeName has not been added"
                    break

                }

                'OpenStack' {

                    Write-Warning -Message "Support for Reservation type $ReservationTypeName has not been added"
                    break

                }

                'vCloud' {

                    Write-Warning -Message "Support for Reservation type $ReservationTypeName has not been added"
                    break

                }

                'HyperV' {

                    Write-Warning -Message "Support for Reservation type $ReservationTypeName has not been added"
                    break

                }

                'KVM' {

                    Write-Warning -Message "Support for Reservation type $ReservationTypeName has not been added"
                    break

                }

                'SCVMM' {

                    Write-Warning -Message "Support for Reservation type $ReservationTypeName has not been added"
                    break

                }

                'XenServer' {

                    Write-Warning -Message "Support for Reservation type $ReservationTypeName has not been added"
                    break

                }

                default {

                    Write-Warning -Message  "Reservation type $ReservationTypeName for Reservation $($Reservation.name) for Reservation $($Reservation.name) did not match a known type"
                    break
                }

            }

            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/reservation-service/api/reservations/$($Id)"

                Write-Verbose -Message "Preparing PUT to $($URI)"

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Reservation | ConvertTo-Json -Depth 100) -Verbose:$VerbosePreference | Out-Null

                Write-Verbose -Message "SUCCESS"

                # --- Output the Successful Result
                Get-vRAReservation -Id $Id
            }

        }
        catch [Exception]{

            throw
        }
    }
    end {

    }
}

<#
    - Function: Set-vRAReservationNetwork
#>

function Set-vRAReservationNetwork {
<#
    .SYNOPSIS
    Set vRA reservation network properties

    .DESCRIPTION
    Set vRA reservation network properties.

    This function enables you to:

    - Add a new network path to a reservation
    - Add a new network path to a reservation and assign a network profile
    - Update the network profile of an existing network path

    If the network path you supply is already selected in the reservation and no network profile is supplied, no action will be taken.

    .PARAMETER Id
    The Id of the reservation

    .PARAMETER NetworkPath
    The network path
    
    .PARAMETER NetworkProfile
    The network profile

    .INPUTS
    System.String

    .OUTPUTS
    None

    .EXAMPLE
    Get-vRAReservation -Name "Reservation01" | Set-vRAReservationNetwork -NetworkPath "VM Network" -NetworkProfile "Test Profile 1"

    .EXAMPLE
    Get-vRAReservation -Name "Reservation01" | Set-vRAReservationNetwork -NetworkPath "VM Network" -NetworkProfile "Test Profile 2"

    .EXAMPLE
    Get-vRAReservation -Name "Reservation01" | Set-vRAReservationNetwork -NetworkPath "Test Network"

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType()]

    Param (

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Id,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$NetworkPath,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [String]$NetworkProfile

    )
 
    begin {
    
        function intGetNetworkProfileByName($Network) {
        <#

            Internal helper fucntion to retrieve a network profile by it's name

        #>
            $Response = (Invoke-vRARestMethod -Method GET -URI "/iaas-proxy-provider/api/network/profiles?`$filter=name%20eq%20'$($NetworkProfile)'").content
            if (!$Response) {
                throw "Could not find Network Profile with name $($NetworkProfile)"
            }
            return $Response
        }

        function intGetNetworkByPath ($ReservationNetworks, $NetworkPath) {
        <#

            Internal helper function to retrieve an existing network path

        #>
            foreach ($ReservationNetwork in $ReservationNetworks) {
                $ExistingNetworkPath = $ReservationNetwork.values.entries | Where-Object  {$_.key -eq "networkPath"} 
                if ($ExistingNetworkPath.value.label -eq $NetworkPath) {
                    return $ReservationNetwork
                }
            }
        }

    }
    
    process {

        try {

            # --- Get the reservation

            $Reservation = Invoke-vRARestMethod -Method GET -URI "/reservation-service/api/reservations/$($id)" -Verbose:$VerbosePreference
            
            $ReservationTypeName = (Get-vRAReservationType -Id $Reservation.reservationTypeId -Verbose:$VerbosePreference).name

            $ComputeResourceId = ($Reservation.extensionData.entries | Where-Object {$_.key -eq "computeResource"}).value.id                         

            # ---
            # --- Set Network Properties
            # ---

            $NetworkPathId = ((Get-vRAReservationComputeResourceNetwork -Type $ReservationTypeName -ComputeResourceId $ComputeResourceId -Name $NetworkPath -Verbose:$VerbosePreference).values.entries | Where-Object {$_.key -eq "networkPath"}).value.id

            # --- Check to see if the provided network path is available for the reservation
            If(!$NetworkPathId) {

                throw "Could not find network path $($NetworkPath) in Compute Resource $($ComputeResourceId)"

            }

            # --- Get a list of networks currently selected by the reservation
            $SelectedReservationNetworks = ($Reservation.extensionData.entries | Where-Object {$_.key -eq "reservationNetworks"}).value.items

            # --- Check to see if the provided networkpath is currently selected in the reservation
            $ExistingReservationNetwork = intGetNetworkByPath $SelectedReservationNetworks $NetworkPath

            if ($ExistingReservationNetwork) {

                # --- If the network path exists and network profile is passed update otherwise exit with nothing to do
                if ($PSBoundParameters.ContainsKey("NetworkProfile")) {

                    Write-Verbose -Message "Network path exists in reservation and Network Profile has been specified"
                
                    $NetworkProfileObject = intGetNetworkProfileByName $NetworkProfile

                    # --- Check to see if the network path already has a profile assigned, if one exists, update it, if not add it
                    $ExistingReservationNetworkProfile = $ExistingReservationNetwork | Where-Object{$_.key -eq "networkProfile"}

                    if ($ExistingReservationNetworkProfile) {

                        Write-Verbose -Message "Updating existing Network Profile"

                        $ExistingReservationNetworkProfile.value.id = $NetworkProfileObject.id
                        $ExistingReservationNetworkProfile.value.label = $NetworkProfileObject.name

                    } else {

                        Write-Verbose -Message "Adding new Network Profile"

                        $ReservationNetworkProfileTemplate = @"

                            {
                                "key": "networkProfile",
                                "value": {
                                    "type": "entityRef",
                                    "componentId": null,
                                    "classId": "networkProfile",
                                    "id": "$($NetworkProfileObject.id)",
                                    "label": "$($NetworkProfileObject.name)"
                                }
                            }

"@

                            $ExistingReservationNetwork.values.entries += ($ReservationNetworkProfileTemplate | ConvertFrom-Json)

                    }

                } else {

                    # --- It would be nice to exit cleanly here
                    Write-Verbose -Message "Network path exists in reservation but no Network profile has been specified"
                    Write-Verbose -Message "Exiting gracefully"
                    return

                }

            } else {

                # --- If the network path doesn't exist add it and also a network profile if passed

                Write-Verbose -Message "Adding new Network Path to reservation"

                $ReservationNetworkTemplate = @"

                    {
                        "type": "complex",
                        "componentTypeId": "com.vmware.csp.iaas.blueprint.service",
                        "componentId": null,
                        "classId": "Infrastructure.Reservation.Network",
                        "typeFilter": null,
                        "values": {
                            "entries": [
                                {
                                    "key": "networkPath",
                                    "value": {
                                        "type": "entityRef",
                                        "componentId": null,
                                        "classId": "Network",
                                        "id": "$($NetworkPathId)",
                                        "label": "$($NetworkPath)"
                                    }
                                }
                            ]
                        }
                    }

"@

                $ReservationNetworkObject = $ReservationNetworkTemplate | ConvertFrom-Json

                if ($PSBoundParameters.ContainsKey("NetworkProfile")) {

                    Write-Verbose -Message "Assigning a Network Profile to new Network Path"

                    $NetworkProfileObject = intGetNetworkProfileByName $NetworkProfile

                    $ReservationNetworkProfileTemplate = @"

                        {
                            "key": "networkProfile",
                            "value": {
                                "type": "entityRef",
                                "componentId": null,
                                "classId": "networkProfile",
                                "id": "$($NetworkProfileObject.id)",
                                "label": "$($NetworkProfileObject.name)"
                            }
                        }

"@

                        $ReservationNetworkObject.values.entries += $ReservationNetworkProfileTemplate | ConvertFrom-Json

                }

                $ReservationNetworks = $Reservation.extensionData.entries | Where-Object {$_.key -eq "reservationNetworks"}

                $ReservationNetworks.value.items += $ReservationNetworkObject

            }

            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/reservation-service/api/reservations/$($Id)"
                
                Write-Verbose -Message "Preparing PUT to $($URI)"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Reservation | ConvertTo-Json -Depth 100) -Verbose:$VerbosePreference | Out-Null

            }

        }
        catch [Exception]{

            throw

        }
    }
    end {
        
    }
}

<#
    - Function: Set-vRAReservationPolicy
#>

function Set-vRAReservationPolicy {
<#
    .SYNOPSIS
    Update a vRA Reservation Policy
    
    .DESCRIPTION
    Update a vRA Reservation Policy

    .PARAMETER Id
    Reservation Policy Id
    
    .PARAMETER Name
    Reservation Policy Name

    .PARAMETER NewName
    Reservation Policy NewName
    
    .PARAMETER Description
    Reservation Policy Description

    .PARAMETER JSON
    Body text to send in JSON format

    .INPUTS
    System.String.

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Set-vRAReservationPolicy -Id "34ae1d6c-9972-4736-acdb-7ee109ad1dbd" -NewName "NewName" -Description "This is the New Name"

    .EXAMPLE
    Set-vRAReservationPolicy -Name ReservationPolicy01 -NewName "NewName" -Description "This is the New Name"
    
    .EXAMPLE
    $JSON = @"
    {
      "id": "34ae1d6c-9972-4736-acdb-7ee109ad1dbd",
      "name": "ReservationPolicy01",
      "description": "This is Reservation Policy 01",
      "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.ComputeResource"
    }
    "@
    $JSON | Set-vRAReservationPolicy -Confirm:$false
#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High",DefaultParameterSetName="ById")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String]$Id,

    [parameter(Mandatory=$true,ParameterSetName="ByName")]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [parameter(Mandatory=$false,ParameterSetName="ByName")]
    [parameter(Mandatory=$false,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String]$NewName,
    
    [parameter(Mandatory=$false,ParameterSetName="ByName")]
    [parameter(Mandatory=$false,ParameterSetName="ById")]
    [ValidateNotNullOrEmpty()]
    [String]$Description,

    [parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="JSON")]
    [ValidateNotNullOrEmpty()]
    [String]$JSON
    )    

    begin {
    
    }
    
    process {

        switch ($PsCmdlet.ParameterSetName) 
        { 
            "ById"  {                
            
            # --- Check for existing Reservation Policy
            try {

                $ReservationPolicy = Get-vRAReservationPolicy -Id $Id
                
                if (-not $ReservationPolicy){

                    throw "Reservation Policy with id $($Id) does not exist"
                }
            }
            catch [Exception]{

                throw
            }
            
            # --- Set any properties not specified at function invocation
            if (-not($PSBoundParameters.ContainsKey("NewName"))){

                if ($ReservationPolicy.Name){

                    $Name = $ReservationPolicy.Name
                }
            }
            else {

                $Name = $NewName
            }
            if (-not($PSBoundParameters.ContainsKey("Description"))){

                if ($ReservationPolicy.Description){

                    $Description = $ReservationPolicy.Description
                }
            }
        
            $Body = @"
                {
                    "id": "$($Id)",
                    "name": "$($Name)",
                    "description": "$($Description)",
                    "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.ComputeResource"
                }
"@                                
            # --- Update existing Reservation Policy
            try {
                if ($PSCmdlet.ShouldProcess($Id)){

                    $URI = "/reservation-service/api/reservations/policies/$($Id)"  

                    # --- Run vRA REST Request
                    $null = Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body

                    # --- Output the Successful Result
                    Get-vRAReservationPolicy -Id $Id
                }
            }
            catch [Exception]{

                throw
            }
                break
            }

            "ByName"  {                

            # --- Check for existing Reservation Policy
            try {

                $ReservationPolicy = Get-vRAReservationPolicy -Name $Name

                if (-not $ReservationPolicy){

                    throw "Reservation Policy with name $($Name) does not exist"
                }

                $Id = $ReservationPolicy.Id
            }
            catch [Exception]{

                throw
            }
            
            # --- Set any properties not specified at function invocation
            if (-not($PSBoundParameters.ContainsKey("NewName"))){

                if ($ReservationPolicy.Name){

                    $Name = $ReservationPolicy.Name
                }
            }
            else {

                $Name = $NewName
            }
            if (-not($PSBoundParameters.ContainsKey("Description"))){

                if ($ReservationPolicy.Description){

                    $Description = $ReservationPolicy.Description
                }
            }
        
            $Body = @"
                {
                    "id": "$($Id)",
                    "name": "$($Name)",
                    "description": "$($Description)",
                    "reservationPolicyTypeId": "Infrastructure.Reservation.Policy.ComputeResource"
                }
"@                                
            # --- Update existing Reservation Policy
            try {
                if ($PSCmdlet.ShouldProcess($Name)){

                    $URI = "/reservation-service/api/reservations/policies/$($Id)"  

                    # --- Run vRA REST Request
                    $null = Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body

                    # --- Output the Successful Result
                    Get-vRAReservationPolicy -Name $Name
                }
            }
            catch [Exception]{

                throw
            }

                
                break
            }

            "JSON"  {

                $Data = ($JSON | ConvertFrom-Json)
            
                $Body = $JSON
                $ID =  $Data.id
                #$Name = $Data.name
            
                # --- Check for existing Reservation Policy
                try {

                    $ReservationPolicy = Get-vRAReservationPolicy -Id $Id
                
                    if (-not $ReservationPolicy){

                        throw "Reservation Policy with id $($Id) does not exist"
                    }
                }
                catch [Exception]{

                    throw
                }
                try {
                    if ($PSCmdlet.ShouldProcess($Id)){

                        $URI = "/reservation-service/api/reservations/policies/$($Id)"  

                        # --- Run vRA REST Request
                        Invoke-vRARestMethod -Method PUT -URI $URI -Body $Body -Verbose:$VerbosePreference | Out-Null

                        # --- Output the Successful Result
                        Get-vRAReservationPolicy -Id $Id
                    }
                }
                catch [Exception]{

                    throw
                }
                
                break
            }
        }
    

    }
    end {
        
    }
}

<#
    - Function: Set-vRAReservationStorage
#>

function Set-vRAReservationStorage {
<#
    .SYNOPSIS
    Set vRA reservation storage properties

    .DESCRIPTION
    Set vRA reservation storage properties

    .PARAMETER Id
    The Id of the reservation

    .PARAMETER Path
    The storage path
    
    .PARAMETER ReservedSizeGB
    The size in GB of this reservation
    
    .PARAMETER Priority
    The priority of storage
    
    .PARAMETER Enabled
    The status of the storage    

    .INPUTS
    System.String.
    System.Int.
    System.Management.Automation.SwitchParameter

    .OUTPUTS
    System.Management.Automation.PSObject

    .EXAMPLE
    Get-vRAReservation -Name "Reservation01" | Set-vRAReservationStorage -Path "Datastore01"  -ReservedSizeGB 20 -Priority 10

#>
[CmdletBinding(SupportsShouldProcess,ConfirmImpact="High")][OutputType('System.Management.Automation.PSObject')]

    Param (

    [parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [String]$Id,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$Path,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$ReservedSizeGB,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Int]$Priority,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Switch]$Enabled

    )
 
    begin {
    
    }
    
    process {

        try {

            # --- Get the reservation

            $URI = "/reservation-service/api/reservations/$($id)"

            $Reservation = Invoke-vRARestMethod -Method GET -URI $URI
            
            $ReservationTypeName = (Get-vRAReservationType -Id $Reservation.reservationTypeId).name

            $ComputeResourceId = ($Reservation.extensionData.entries | Where-Object {$_.key -eq "computeResource"}).value.id                         

            # ---
            # --- Set Storage Properties
            # ---

            Write-Verbose -Message "Removing Storage From Reservation"

            $ReservationStoragePath = (Get-vRAReservationComputeResourceStorage -Type $ReservationTypeName -ComputeResourceId $ComputeResourceId -Name $Path).values.entries | Where-Object {$_.key -eq "storagePath"}

            $ReservationStoragePathId = $ReservationStoragePath.value.id

            $Storage = $Reservation.extensionData.entries | Where-Object {$_.key -eq "reservationStorages"}  

            $StorageItems = $Storage.value.items

            foreach ($Item in $StorageItems) {

                $StoragePath = $item.values.entries | Where-Object {$_.key -eq "StoragePath"}                

                if ($StoragePath.value.id -eq $ReservationStoragePathId) {

                    if ($PSBoundParameters.ContainsKey("ReservedSizeGB")){

                        $StorageReservedSizeGB = $item.values.entries | Where-Object {$_.key -eq "storageReservedSizeGB"}

                        Write-Verbose -Message "Setting Storage Reservation Size: $($StorageReservedSizeGB.value.value) >> $($ReservedSizeGB)"

                        $StorageReservedSizeGB.value.value = $ReservedSizeGB

                    }
                
                    if ($PSBoundParameters.ContainsKey("Priority")){

                        $StorageReservationPriority = $item.values.entries | Where-Object {$_.key -eq "storageReservationPriority"}

                        Write-Verbose -Message "Setting Storage Reservation Priority: $($StorageReservationPriority.value.value) >> $($Priority)"
                        
                        $StorageReservationPriority.value.value = $Priority                        

                    }

                    if ($PSBoundParameters.ContainsKey("Enabled")){

                        if ($Enabled) {

                            $BoolAsString = "true"                            

                        }
                        else {

                            $BoolAsString = "false"

                        }

                        $StorageEnabled = $item.values.entries | Where-Object {$_.key -eq "storageEnabled"}

                        Write-Verbose -Message "Setting Storage Reservation Priority: $($StorageEnabled.value.value) >> $($BoolAsString)"

                        $StorageEnabled.value.value = $BoolAsString

                    }

                }

            }

            if ($PSCmdlet.ShouldProcess($Id)){

                $URI = "/reservation-service/api/reservations/$($Id)"
                
                Write-Verbose -Message "Preparing PUT to $($URI)"  

                # --- Run vRA REST Request
                Invoke-vRARestMethod -Method PUT -URI $URI -Body ($Reservation | ConvertTo-Json -Depth 100) -Verbose:$VerbosePreference | Out-Null

            }

        }
        catch [Exception]{

            throw

        }
    }
    end {
        
    }
}


