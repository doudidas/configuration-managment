def customPath = "/var/log/jenkins/configuration-drift/"
pipeline {
  agent any
  triggers { cron('@midnight')}
  stages {
    stage('Set default value') {
      parallel {
        stage('Dev') {
          when {
            branch 'dev'
          }
          steps {
            script {
              platform = "development"
            }

          }
        }
        stage('Get from branch name') {
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
              sh "pwsh check.ps1 Get-vRAAuthorizationRole ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAAuthorizationRole ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRABlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRABlueprint ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRABlueprint ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRABusinessGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRABusinessGroup ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRABusinessGroup ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRACatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRACatalogItem ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRACatalogItem ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAComponentRegistryService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAComponentRegistryService ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAComponentRegistryService ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAComponentRegistryServiceStatus') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAComponentRegistryServiceStatus ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAComponentRegistryServiceStatus ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAContent') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAContent ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAContent ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAContentType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAContentType ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAContentType ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAEntitledCatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitledCatalogItem ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAEntitledCatalogItem ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAEntitledService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitledService ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAEntitledService ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAEntitlement') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitlement ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAEntitlement ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAExternalNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAExternalNetworkProfile ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAExternalNetworkProfile ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAGroupPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAGroupPrincipal ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAGroupPrincipal ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRANATNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRANATNetworkProfile ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRANATNetworkProfile ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAPackage') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPackage ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAPackage ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAPropertyDefinition') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPropertyDefinition ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAPropertyDefinition ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAPropertyGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPropertyGroup ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAPropertyGroup ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRARequest') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRARequest ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRARequest ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAReservation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservation ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAReservation ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAReservationPolicy') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservationPolicy ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAReservationPolicy ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAReservationType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservationType ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAReservationType ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAResourceMetric') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceMetric ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAResourceMetric ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAResourceOperation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceOperation ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAResourceOperation ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAResourceType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceType ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAResourceType ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAService ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAService ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAServiceBlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAServiceBlueprint ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAServiceBlueprint ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAUserPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAUserPrincipal ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAUserPrincipal ${platform} ${customPath} verbose"
            }

          }
        }
        stage('vRAVersion') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAVersion ${platform} ${customPath}"
              sh "pwsh check.ps1 Get-vRAVersion ${platform} ${customPath} verbose"
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
}