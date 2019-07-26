pipeline {
  agent any
    environment {
      platform = ''
    }
  stages {
    stage("Connexion"){
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
              sh 'pwsh check.ps1 Get-vRAAuthorizationRole '
              sh 'pwsh check.ps1 Get-vRAAuthorizationRole  verbose'
            }
          }
        }
        stage('vRABlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRABlueprint '
              sh 'pwsh check.ps1 Get-vRABlueprint  verbose'
            }
          }
        }
        stage('vRABusinessGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRABusinessGroup '
              sh 'pwsh check.ps1 Get-vRABusinessGroup  verbose'
            }
          }
        }
        stage('vRACatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRACatalogItem '
              sh 'pwsh check.ps1 Get-vRACatalogItem  verbose'
            }
          }
        }
        stage('vRAComponentRegistryService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAComponentRegistryService '
              sh 'pwsh check.ps1 Get-vRAComponentRegistryService  verbose'
            }
          }
        }
        stage('vRAComponentRegistryServiceStatus') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAComponentRegistryServiceStatus '
              sh 'pwsh check.ps1 Get-vRAComponentRegistryServiceStatus  verbose'
            }
          }
        }
        stage('vRAContent') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAContent '
              sh 'pwsh check.ps1 Get-vRAContent  verbose'
            }
          }
        }
        stage('vRAContentType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAContentType '
              sh 'pwsh check.ps1 Get-vRAContentType  verbose'
            }
          }
        }
        stage('vRAEntitledCatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAEntitledCatalogItem '
              sh 'pwsh check.ps1 Get-vRAEntitledCatalogItem  verbose'
            }
          }
        }
        stage('vRAEntitledService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAEntitledService '
              sh 'pwsh check.ps1 Get-vRAEntitledService  verbose'
            }
          }
        }
        stage('vRAEntitlement') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAEntitlement '
              sh 'pwsh check.ps1 Get-vRAEntitlement  verbose'
            }
          }
        }
        stage('vRAExternalNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAExternalNetworkProfile '
              sh 'pwsh check.ps1 Get-vRAExternalNetworkProfile  verbose'
            }
          }
        }
        stage('vRAGroupPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAGroupPrincipal '
              sh 'pwsh check.ps1 Get-vRAGroupPrincipal  verbose'
            }
          }
        }
        stage('vRANATNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRANATNetworkProfile '
              sh 'pwsh check.ps1 Get-vRANATNetworkProfile  verbose'
            }
          }
        }
        stage('vRAPackage') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAPackage '
              sh 'pwsh check.ps1 Get-vRAPackage  verbose'
            }
          }
        }
        stage('vRAPropertyDefinition') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAPropertyDefinition '
              sh 'pwsh check.ps1 Get-vRAPropertyDefinition  verbose'
            }
          }
        }
        stage('vRAPropertyGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAPropertyGroup '
              sh 'pwsh check.ps1 Get-vRAPropertyGroup  verbose'
            }
          }
        }
        stage('vRARequest') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRARequest '
              sh 'pwsh check.ps1 Get-vRARequest  verbose'
            }
          }
        }
        stage('vRAReservation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAReservation '
              sh 'pwsh check.ps1 Get-vRAReservation  verbose'
            }
          }
        }
        stage('vRAReservationPolicy') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAReservationPolicy '
              sh 'pwsh check.ps1 Get-vRAReservationPolicy  verbose'
            }
          }
        }
        stage('vRAReservationType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAReservationType '
              sh 'pwsh check.ps1 Get-vRAReservationType  verbose'
            }
          }
        }
        stage('vRAResourceMetric') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAResourceMetric '
              sh 'pwsh check.ps1 Get-vRAResourceMetric  verbose'
            }
          }
        }
        stage('vRAResourceOperation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAResourceOperation '
              sh 'pwsh check.ps1 Get-vRAResourceOperation  verbose'
            }
          }
        }
        stage('vRAResourceType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAResourceType '
              sh 'pwsh check.ps1 Get-vRAResourceType  verbose'
            }
          }
        }
        stage('vRAService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAService '
              sh 'pwsh check.ps1 Get-vRAService  verbose'
            }
          }
        }
        stage('vRAServiceBlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAServiceBlueprint '
              sh 'pwsh check.ps1 Get-vRAServiceBlueprint  verbose'
            }
          }
        }
        stage('vRAUserPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAUserPrincipal '
              sh 'pwsh check.ps1 Get-vRAUserPrincipal  verbose'
            }
          }
        }
        stage('vRAVersion') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh 'pwsh check.ps1 Get-vRAVersion '
              sh 'pwsh check.ps1 Get-vRAVersion  verbose'
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