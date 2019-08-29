$commands = @(
    'getObject.ps1 Get-vRAAuthorizationRole',
    'getObject.ps1 Get-vRABlueprint', 
    'getObject.ps1 Get-vRABusinessGroup', 
    'getObject.ps1 Get-vRACatalogItem', 
    'getObject.ps1 Get-vRAComponentRegistryService', 
    'getObject.ps1 Get-vRAComponentRegistryServiceStatus',
    'getObject.ps1 Get-vRAContent', 
    'getObject.ps1 Get-vRAContentType', 
    'getObject.ps1 Get-vRAEntitledCatalogItem',
    'getObject.ps1 Get-vRAEntitledService', 
    'getObject.ps1 Get-vRAEntitlement', 
    'getObject.ps1 Get-vRAExternalNetworkProfile',
    'getObject.ps1 Get-vRAGroupPrincipal',
    'getObject.ps1 Get-vRANATNetworkProfile',
    'getObject.ps1 Get-vRAPackage', 
    'getObject.ps1 Get-vRAPropertyDefinition',
    # 'getObject.ps1 Get-vRAPropertyGroup', 
    # 'getObject.ps1 Get-vRARequest', 
    'getObject.ps1 Get-vRAReservation',
    'getObject.ps1 Get-vRAReservationPolicy',
    'getObject.ps1 Get-vRAReservationType', 
    'getObject.ps1 Get-vRAResourceMetric', 
    'getObject.ps1 Get-vRAResourceOperation',
    'getObject.ps1 Get-vRAResourceType', 
    'getObject.ps1 Get-vRAService', 
    'getObject.ps1 Get-vRAServiceBlueprint',
    'getObject.ps1 Get-vRAUserPrincipal', 
    'getObject.ps1 Get-vRAVersion'
)
connectToServer.ps1
foreach ($cmd in $commands) {
    Invoke-Expression -Command "$cmd silent"
}