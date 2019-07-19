pipeline {
  agent any
    environment {
      platform = 'development'
    }
  stages {
    stage('Connexion') {
      steps {
        sh 'pwsh connectToServer.ps1'
      }
    }
    stage('Capture plateform') {
      parallel {
        stage('vRAAuthorizationRole') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAAuthorizationRole'
          }
        }
        stage('vRABlueprint') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRABlueprint'
          }
        }
        stage('vRABusinessGroup') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRABusinessGroup'
          }
        }
        stage('vRACatalogItem') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRACatalogItem'
          }
        }
        stage('vRAComponentRegistryService') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAComponentRegistryService'
          }
        }
        stage('vRAComponentRegistryServiceStatus') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAComponentRegistryServiceStatus'
          }
        }
        stage('vRAContent') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAContent'
          }
        }
        stage('vRAContentType') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAContentType'
          }
        }
        stage('vRAEntitledCatalogItem') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAEntitledCatalogItem'
          }
        }
        stage('vRAEntitledService') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAEntitledService'
          }
        }
        stage('vRAEntitlement') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAEntitlement'
          }
        }
        stage('vRAExternalNetworkProfile') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAExternalNetworkProfile'
          }
        }
        stage('vRAGroupPrincipal') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAGroupPrincipal'
          }
        }
        stage('vRANATNetworkProfile') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRANATNetworkProfile'
          }
        }
        stage('vRAPackage') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAPackage'
          }
        }
        stage('vRAPropertyDefinition') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAPropertyDefinition'
          }
        }
        stage('vRAPropertyGroup') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAPropertyGroup'
          }
        }
        stage('vRARequest') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRARequest'
          }
        }
        stage('vRAReservation') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAReservation'
          }
        }
        stage('vRAReservationPolicy') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAReservationPolicy'
          }
        }
        stage('vRAReservationType') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAReservationType'
          }
        }
        stage('vRAResourceMetric') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAResourceMetric'
          }
        }
        stage('vRAResourceOperation') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAResourceOperation'
          }
        }
        stage('vRAResourceType') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAResourceType'
          }
        }
        stage('vRAService') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAService'
          }
        }
        stage('vRAServiceBlueprint') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAServiceBlueprint'
          }
        }
        stage('vRAUserPrincipal') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAUserPrincipal'
          }
        }
        stage('vRAVersion') {
          steps {
            sh 'pwsh getObject.ps1 Get-vRAVersion'
          }
        }
      }
    }
    stage('DIFF') {
      parallel {
        stage('vRAAuthorizationRole') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAAuthorizationRole'
            }
          }
        }
        stage('vRABlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRABlueprint'
            }
          }
        }
        stage('vRABusinessGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRABusinessGroup'
            }
          }
        }
        stage('vRACatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRACatalogItem'
            }
          }
        }
        stage('vRAComponentRegistryService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAComponentRegistryService'
            }
          }
        }
        stage('vRAComponentRegistryServiceStatus') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAComponentRegistryServiceStatus'
            }
          }
        }
        stage('vRAContent') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAContent'
            }
          }
        }
        stage('vRAContentType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAContentType'
            }
          }
        }
        stage('vRAEntitledCatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAEntitledCatalogItem'
            }
          }
        }
        stage('vRAEntitledService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAEntitledService'
            }
          }
        }
        stage('vRAEntitlement') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAEntitlement'
            }
          }
        }
        stage('vRAExternalNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAExternalNetworkProfile'
            }
          }
        }
        stage('vRAGroupPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAGroupPrincipal'
            }
          }
        }
        stage('vRANATNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRANATNetworkProfile'
            }
          }
        }
        stage('vRAPackage') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAPackage'
            }
          }
        }
        stage('vRAPropertyDefinition') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAPropertyDefinition'
            }
          }
        }
        stage('vRAPropertyGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAPropertyGroup'
            }
          }
        }
        stage('vRARequest') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRARequest'
            }
          }
        }
        stage('vRAReservation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAReservation'
            }
          }
        }
        stage('vRAReservationPolicy') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAReservationPolicy'
            }
          }
        }
        stage('vRAReservationType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAReservationType'
            }
          }
        }
        stage('vRAResourceMetric') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAResourceMetric'
            }
          }
        }
        stage('vRAResourceOperation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAResourceOperation'
            }
          }
        }
        stage('vRAResourceType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAResourceType'
            }
          }
        }
        stage('vRAService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAService'
            }
          }
        }
        stage('vRAServiceBlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAServiceBlueprint'
            }
          }
        }
        stage('vRAUserPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAUserPrincipal'
            }
          }
        }
        stage('vRAVersion') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh './check.sh Get-vRAVersion'
            }
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