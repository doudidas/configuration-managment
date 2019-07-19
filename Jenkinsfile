pipeline {
  agent any
  stages {
      stage('Connexion') {
        parallel {
          stage('Connexion') {
            steps {
              sh 'pwsh connectToServer.ps1'
            }
          }
        }
      }
      stage('Capture plateform') {
        parallel {
          stage('Get-vRAAuthorizationRole') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAAuthorizationRole'
            }
          }
          stage('Get-vRABlueprint') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRABlueprint'
            }
          }
          stage('Get-vRABusinessGroup') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRABusinessGroup'
            }
          }
          stage('Get-vRACatalogItem') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRACatalogItem'
            }
          }
          stage('Get-vRAComponentRegistryService') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAComponentRegistryService'
            }
          }
          stage('Get-vRAComponentRegistryServiceStatus') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAComponentRegistryServiceStatus'
            }
          }
          stage('Get-vRAContent') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAContent'
            }
          }
          stage('Get-vRAContentType') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAContentType'
            }
          }
          stage('Get-vRAEntitledCatalogItem') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAEntitledCatalogItem'
            }
          }
          stage('Get-vRAEntitledService') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAEntitledService'
            }
          }
          stage('Get-vRAEntitlement') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAEntitlement'
            }
          }
          stage('Get-vRAExternalNetworkProfile') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAExternalNetworkProfile'
            }
          }
          stage('Get-vRAGroupPrincipal') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAGroupPrincipal'
            }
          }
          stage('Get-vRANATNetworkProfile') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRANATNetworkProfile'
            }
          }
          stage('Get-vRAPackage') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAPackage'
            }
          }
          stage('Get-vRAPropertyDefinition') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAPropertyDefinition'
            }
          }
          stage('Get-vRAPropertyGroup') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAPropertyGroup'
            }
          }
          stage('Get-vRARequest') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRARequest'
            }
          }
          stage('Get-vRAReservation') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAReservation'
            }
          }
          stage('Get-vRAReservationPolicy') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAReservationPolicy'
            }
          }
          stage('Get-vRAReservationType') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAReservationType'
            }
          }
          stage('Get-vRAResourceMetric') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAResourceMetric'
            }
          }
          stage('Get-vRAResourceOperation') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAResourceOperation'
            }
          }
          stage('Get-vRAResourceType') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAResourceType'
            }
          }
          stage('Get-vRAService') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAService'
            }
          }
          stage('Get-vRAServiceBlueprint') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAServiceBlueprint'
            }
          }
          stage('Get-vRAUserPrincipal') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAUserPrincipal'
            }
          }
          stage('Get-vRAVersion') {
            steps {
              sh 'pwsh getObject.ps1 Get-vRAVersion'
            }
          }
        }
      }
      stage('DIFF') {
        parallel {
          stage('Get-vRAAuthorizationRole') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAAuthorizationRole'
            }
          }
          stage('Get-vRABlueprint') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRABlueprint'
            }
          }
          stage('Get-vRABusinessGroup') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRABusinessGroup'
            }
          }
          stage('Get-vRACatalogItem') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRACatalogItem'
            }
          }
          stage('Get-vRAComponentRegistryService') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAComponentRegistryService'
            }
          }
          stage('Get-vRAComponentRegistryServiceStatus') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAComponentRegistryServiceStatus'
            }
          }
          stage('Get-vRAContent') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAContent'
            }
          }
          stage('Get-vRAContentType') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAContentType'
            }
          }
          stage('Get-vRAEntitledCatalogItem') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAEntitledCatalogItem'
            }
          }
          stage('Get-vRAEntitledService') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAEntitledService'
            }
          }
          stage('Get-vRAEntitlement') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAEntitlement'
            }
          }
          stage('Get-vRAExternalNetworkProfile') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAExternalNetworkProfile'
            }
          }
          stage('Get-vRAGroupPrincipal') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAGroupPrincipal'
            }
          }
          stage('Get-vRANATNetworkProfile') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRANATNetworkProfile'
            }
          }
          stage('Get-vRAPackage') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAPackage'
            }
          }
          stage('Get-vRAPropertyDefinition') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAPropertyDefinition'
            }
          }
          stage('Get-vRAPropertyGroup') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAPropertyGroup'
            }
          }
          stage('Get-vRARequest') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRARequest'
            }
          }
          stage('Get-vRAReservation') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAReservation'
            }
          }
          stage('Get-vRAReservationPolicy') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAReservationPolicy'
            }
          }
          stage('Get-vRAReservationType') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAReservationType'
            }
          }
          stage('Get-vRAResourceMetric') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAResourceMetric'
            }
          }
          stage('Get-vRAResourceOperation') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAResourceOperation'
            }
          }
          stage('Get-vRAResourceType') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAResourceType'
            }
          }
          stage('Get-vRAService') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAService'
            }
          }
          stage('Get-vRAServiceBlueprint') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAServiceBlueprint'
            }
          }
          stage('Get-vRAUserPrincipal') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAUserPrincipal'
            }
          }
          stage('Get-vRAVersion') {
            steps {
              sh 'git diff development-current..remotes/origin/development-reference -- export/Get-vRAVersion'
          }
        }
      }
    }
    stage('archive') {
      steps {
        archiveArtifacts(artifacts: 'export/**/*.json', allowEmptyArchive: true)
      }
    }
  }
}