pipeline {
  agent any
  stages {
    stage('Set Environment') {
      parallel {
        stage('only for Dev') {
          when {
            branch 'dev'
          }
          steps {
            script {
              platform = "development"
            }

          }
        }
        stage('None dev Branch') {
          when {
            not {
              branch 'dev'
            }

          }
          steps {
            script {
              platform = sh(returnStdout: true, script: "git name-rev --name-only HEAD | cut -d '-' -f 1").trim()
            }

          }
        }
        stage('Get remotes branches') {
          steps {
            sh 'git pull --all'
            sh 'git branch --all'
          }
        }
      }
    }
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
              sh "pwsh check.ps1 Get-vRAAuthorizationRole ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAAuthorizationRole ${platform} ${path} verbose"
            }

          }
        }
        stage('vRABlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRABlueprint ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRABlueprint ${platform} ${path} verbose"
            }

          }
        }
        stage('vRABusinessGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRABusinessGroup ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRABusinessGroup ${platform} ${path} verbose"
            }

          }
        }
        stage('vRACatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRACatalogItem ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRACatalogItem ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAComponentRegistryService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAComponentRegistryService ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAComponentRegistryService ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAComponentRegistryServiceStatus') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAComponentRegistryServiceStatus ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAComponentRegistryServiceStatus ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAContent') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAContent ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAContent ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAContentType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAContentType ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAContentType ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAEntitledCatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitledCatalogItem ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAEntitledCatalogItem ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAEntitledService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitledService ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAEntitledService ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAEntitlement') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitlement ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAEntitlement ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAExternalNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAExternalNetworkProfile ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAExternalNetworkProfile ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAGroupPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAGroupPrincipal ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAGroupPrincipal ${platform} ${path} verbose"
            }

          }
        }
        stage('vRANATNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRANATNetworkProfile ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRANATNetworkProfile ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAPackage') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPackage ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAPackage ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAPropertyDefinition') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPropertyDefinition ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAPropertyDefinition ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAPropertyGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPropertyGroup ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAPropertyGroup ${platform} ${path} verbose"
            }

          }
        }
        stage('vRARequest') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRARequest ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRARequest ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAReservation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservation ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAReservation ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAReservationPolicy') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservationPolicy ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAReservationPolicy ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAReservationType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservationType ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAReservationType ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAResourceMetric') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceMetric ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAResourceMetric ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAResourceOperation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceOperation ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAResourceOperation ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAResourceType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceType ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAResourceType ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAService ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAService ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAServiceBlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAServiceBlueprint ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAServiceBlueprint ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAUserPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAUserPrincipal ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAUserPrincipal ${platform} ${path} verbose"
            }

          }
        }
        stage('vRAVersion') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAVersion ${platform} ${path}"
              sh "pwsh check.ps1 Get-vRAVersion ${platform} ${path} verbose"
            }

          }
        }
      }
    }
    stage('update current-branch') {
      when {
        expression {
          BRANCH_NAME ==~ /(dev|.*-current)/
        }

      }
      steps {
        sh 'git add --all'
        sh 'git commit --allow-empty -m "[${GIT_BRANCH}] Pushed by Jenkins: build n�${BUILD_NUMBER}"'
        sh "git push origin ${GIT_BRANCH}"
      }
    }
  }
  environment {
    path = '/var/log/jenkins/configuration-drift/'
  }
  triggers {
    cron('@midnight')
  }
}