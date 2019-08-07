def token = ''
pipeline {
  agent any
    environment {
      platform = 'development'
    }
  stages {
    stage('Connexion'){
      steps {
        token = sh(returnStdout: true, script: 'pwsh connectToServer.ps1')
      }
    }
    stage('Capture plateform') {
      parallel {
        stage('vRAAuthorizationRole') {
          steps {
            echo "${browser}"
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
              sh 'pwsh check.ps1 Get-vRAAuthorizationRole $platform'
              sh 'pwsh check.ps1 Get-vRAAuthorizationRole $platform verbose'
            }
          }
        }
        stage('vRABlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRABlueprint $platform'
              sh 'pwsh check.ps1 Get-vRABlueprint $platform verbose'
            }
          }
        }
        stage('vRABusinessGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRABusinessGroup $platform'
              sh 'pwsh check.ps1 Get-vRABusinessGroup $platform verbose'
            }
          }
        }
        stage('vRACatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRACatalogItem $platform'
              sh 'pwsh check.ps1 Get-vRACatalogItem $platform verbose'
            }
          }
        }
        stage('vRAComponentRegistryService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAComponentRegistryService $platform'
              sh 'pwsh check.ps1 Get-vRAComponentRegistryService $platform verbose'
            }
          }
        }
        stage('vRAComponentRegistryServiceStatus') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAComponentRegistryServiceStatus $platform'
              sh 'pwsh check.ps1 Get-vRAComponentRegistryServiceStatus $platform verbose'
            }
          }
        }
        stage('vRAContent') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAContent $platform'
              sh 'pwsh check.ps1 Get-vRAContent $platform verbose'
            }
          }
        }
        stage('vRAContentType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAContentType $platform'
              sh 'pwsh check.ps1 Get-vRAContentType $platform verbose'
            }
          }
        }
        stage('vRAEntitledCatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAEntitledCatalogItem $platform'
              sh 'pwsh check.ps1 Get-vRAEntitledCatalogItem $platform verbose'
            }
          }
        }
        stage('vRAEntitledService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAEntitledService $platform'
              sh 'pwsh check.ps1 Get-vRAEntitledService $platform verbose'
            }
          }
        }
        stage('vRAEntitlement') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAEntitlement $platform'
              sh 'pwsh check.ps1 Get-vRAEntitlement $platform verbose'
            }
          }
        }
        stage('vRAExternalNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAExternalNetworkProfile $platform'
              sh 'pwsh check.ps1 Get-vRAExternalNetworkProfile $platform verbose'
            }
          }
        }
        stage('vRAGroupPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAGroupPrincipal $platform'
              sh 'pwsh check.ps1 Get-vRAGroupPrincipal $platform verbose'
            }
          }
        }
        stage('vRANATNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRANATNetworkProfile $platform'
              sh 'pwsh check.ps1 Get-vRANATNetworkProfile $platform verbose'
            }
          }
        }
        stage('vRAPackage') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAPackage $platform'
              sh 'pwsh check.ps1 Get-vRAPackage $platform verbose'
            }
          }
        }
        stage('vRAPropertyDefinition') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAPropertyDefinition $platform'
              sh 'pwsh check.ps1 Get-vRAPropertyDefinition $platform verbose'
            }
          }
        }
        stage('vRAPropertyGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAPropertyGroup $platform'
              sh 'pwsh check.ps1 Get-vRAPropertyGroup $platform verbose'
            }
          }
        }
        stage('vRARequest') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRARequest $platform'
              sh 'pwsh check.ps1 Get-vRARequest $platform verbose'
            }
          }
        }
        stage('vRAReservation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAReservation $platform'
              sh 'pwsh check.ps1 Get-vRAReservation $platform verbose'
            }
          }
        }
        stage('vRAReservationPolicy') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAReservationPolicy $platform'
              sh 'pwsh check.ps1 Get-vRAReservationPolicy $platform verbose'
            }
          }
        }
        stage('vRAReservationType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAReservationType $platform'
              sh 'pwsh check.ps1 Get-vRAReservationType $platform verbose'
            }
          }
        }
        stage('vRAResourceMetric') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAResourceMetric $platform'
              sh 'pwsh check.ps1 Get-vRAResourceMetric $platform verbose'
            }
          }
        }
        stage('vRAResourceOperation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAResourceOperation $platform'
              sh 'pwsh check.ps1 Get-vRAResourceOperation $platform verbose'
            }
          }
        }
        stage('vRAResourceType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAResourceType $platform'
              sh 'pwsh check.ps1 Get-vRAResourceType $platform verbose'
            }
          }
        }
        stage('vRAService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAService $platform'
              sh 'pwsh check.ps1 Get-vRAService $platform verbose'
            }
          }
        }
        stage('vRAServiceBlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAServiceBlueprint $platform'
              sh 'pwsh check.ps1 Get-vRAServiceBlueprint $platform verbose'
            }
          }
        }
        stage('vRAUserPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAUserPrincipal $platform'
              sh 'pwsh check.ps1 Get-vRAUserPrincipal $platform verbose'
            }
          }
        }
        stage('vRAVersion') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAVersion $platform'
              sh 'pwsh check.ps1 Get-vRAVersion $platform verbose'
            }
          }
        }
      }
    }
    stage('archive') {
      steps {
        archiveArtifacts(artifacts: 'diff/*.txt', allowEmptyArchive: true)
      }
    }
  }
}