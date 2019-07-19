pipeline {
  agent any
  stages {
    stage('Connexion') {
      steps {
        sh 'pwsh connectToServer.ps1'
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
              sh 'check.sh Get-vRAAuthorizationRole'
            }
          }
          stage('Get-vRABlueprint') {
            steps {
              sh 'check.sh Get-vRABlueprint'
            }
          }
          stage('Get-vRABusinessGroup') {
            steps {
              sh 'check.sh Get-vRABusinessGroup'
            }
          }
          stage('Get-vRACatalogItem') {
            steps {
              sh 'check.sh Get-vRACatalogItem'
            }
          }
          stage('Get-vRAComponentRegistryService') {
            steps {
              sh 'check.sh Get-vRAComponentRegistryService'
            }
          }
          stage('Get-vRAComponentRegistryServiceStatus') {
            steps {
              sh 'check.sh Get-vRAComponentRegistryServiceStatus'
            }
          }
          stage('Get-vRAContent') {
            steps {
              sh 'check.sh Get-vRAContent'
            }
          }
          stage('Get-vRAContentType') {
            steps {
              sh 'check.sh Get-vRAContentType'
            }
          }
          stage('Get-vRAEntitledCatalogItem') {
            steps {
              sh 'check.sh Get-vRAEntitledCatalogItem'
            }
          }
          stage('Get-vRAEntitledService') {
            steps {
              sh 'check.sh Get-vRAEntitledService'
            }
          }
          stage('Get-vRAEntitlement') {
            steps {
              sh 'check.sh Get-vRAEntitlement'
            }
          }
          stage('Get-vRAExternalNetworkProfile') {
            steps {
              sh 'check.sh Get-vRAExternalNetworkProfile'
            }
          }
          stage('Get-vRAGroupPrincipal') {
            steps {
              sh 'check.sh Get-vRAGroupPrincipal'
            }
          }
          stage('Get-vRANATNetworkProfile') {
            steps {
              sh 'check.sh Get-vRANATNetworkProfile'
            }
          }
          stage('Get-vRAPackage') {
            steps {
              sh 'check.sh Get-vRAPackage'
            }
          }
          stage('Get-vRAPropertyDefinition') {
            steps {
              sh 'check.sh Get-vRAPropertyDefinition'
            }
          }
          stage('Get-vRAPropertyGroup') {
            steps {
              sh 'check.sh Get-vRAPropertyGroup'
            }
          }
          stage('Get-vRARequest') {
            steps {
              sh 'check.sh Get-vRARequest'
            }
          }
          stage('Get-vRAReservation') {
            steps {
              sh 'check.sh Get-vRAReservation'
            }
          }
          stage('Get-vRAReservationPolicy') {
            steps {
              sh 'check.sh Get-vRAReservationPolicy'
            }
          }
          stage('Get-vRAReservationType') {
            steps {
              sh 'check.sh Get-vRAReservationType'
            }
          }
          stage('Get-vRAResourceMetric') {
            steps {
              sh 'check.sh Get-vRAResourceMetric'
            }
          }
          stage('Get-vRAResourceOperation') {
            steps {
              sh 'check.sh Get-vRAResourceOperation'
            }
          }
          stage('Get-vRAResourceType') {
            steps {
              sh 'check.sh Get-vRAResourceType'
            }
          }
          stage('Get-vRAService') {
            steps {
              sh 'check.sh Get-vRAService'
            }
          }
          stage('Get-vRAServiceBlueprint') {
            steps {
              sh 'check.sh Get-vRAServiceBlueprint'
            }
          }
          stage('Get-vRAUserPrincipal') {
            steps {
              sh 'check.sh Get-vRAUserPrincipal'
            }
          }
          stage('Get-vRAVersion') {
            steps {
              sh 'check.sh Get-vRAVersion'
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