pipeline {
  agent any
  triggers {
    cron(BRANCH_NAME ==~ /(dev|.*-current)/ ? '0 * * * *' : '')
  }
  stages {
    stage('Set default value') {
      parallel {
        stage('Dev') {
          when {
            branch 'dev'
          }
          steps {
            script {
              platform = "lab"
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
    stage('Initiate') {
      parallel{
        stage('Connexion') {
          steps {
            sh "pwsh connectToServer.ps1 ${platform}"
          }
        }
        stage('Install Powershell Lib') {
          steps {
            sh "pwsh init.ps1"
          }
        }
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
              sh "pwsh check.ps1 Get-vRAAuthorizationRole ${platform}"
            }

          }
        }
        stage('vRABlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRABlueprint ${platform}"
            }

          }
        }
        stage('vRABusinessGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRABusinessGroup ${platform}"
            }

          }
        }
        stage('vRACatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRACatalogItem ${platform}"
            }

          }
        }
        stage('vRAComponentRegistryService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAComponentRegistryService ${platform}"
            }

          }
        }
        stage('vRAComponentRegistryServiceStatus') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAComponentRegistryServiceStatus ${platform}"
            }

          }
        }
        stage('vRAContent') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAContent ${platform}"
            }

          }
        }
        stage('vRAContentType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAContentType ${platform}"
            }

          }
        }
        stage('vRAEntitledCatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitledCatalogItem ${platform}"
            }

          }
        }
        stage('vRAEntitledService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitledService ${platform}"
            }

          }
        }
        stage('vRAEntitlement') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitlement ${platform}"
            }

          }
        }
        stage('vRAExternalNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAExternalNetworkProfile ${platform}"
            }

          }
        }
        stage('vRAGroupPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAGroupPrincipal ${platform}"
            }

          }
        }
        stage('vRANATNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRANATNetworkProfile ${platform}"
            }

          }
        }
        stage('vRAPackage') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPackage ${platform}"
            }

          }
        }
        stage('vRAPropertyDefinition') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPropertyDefinition ${platform}"
            }

          }
        }
        stage('vRAReservation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservation ${platform}"
            }

          }
        }
        stage('vRAReservationPolicy') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservationPolicy ${platform}"
            }

          }
        }
        stage('vRAReservationType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservationType ${platform}"
            }

          }
        }
        stage('vRAResourceMetric') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceMetric ${platform}"
            }

          }
        }
        stage('vRAResourceOperation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceOperation ${platform}"
            }

          }
        }
        stage('vRAResourceType') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceType ${platform}"
            }

          }
        }
        stage('vRAService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAService ${platform}"
            }

          }
        }
        stage('vRAServiceBlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAServiceBlueprint ${platform}"
            }

          }
        }
        stage('vRAUserPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAUserPrincipal ${platform}"
            }

          }
        }
        stage('vRAVersion') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAVersion ${platform}"
            }

          }
        }
      }
    }
    stage('update current-branch') {
      when {
        expression {
          BRANCH_NAME ==~ /.*-current/
        }
      }
      steps {
        sh 'git add --all'
        sh 'git commit --allow-empty -m "[${GIT_BRANCH}] Pushed by Jenkins: build #${BUILD_NUMBER}"'
        sh "git push origin ${GIT_BRANCH}"
      }
    }
  }
}
