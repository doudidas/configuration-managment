pipeline {
  agent any
  stages {
    parallel{
      stage('Get from branch name') {
        steps {
          script {
            platform = sh(returnStdout: true, script: "git name-rev --name-only HEAD | cut -d '-' -f 1").trim()
          }
        }
      }
      stage('Install python libraries') {
        steps {
          sh "pip install -t lib/python -r requirement.txt"
        }
      }
    }
    stage('Connexion') {
      steps {
        sh "pwsh connectToServer.ps1 ${platform}"
      }
    }
    stage('Capture plateform') {
      parallel {
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
    stage('update current-branch') {
      when {
        expression {
          BRANCH_NAME ==~ /.*-current/
        }

      }
      steps {
        sh '''git config user.name "jenkins"
              git config user.email "jenkins@bt1resjnkns1.bpa.bouyguestelecom.fr"
              git add --all
              git commit --allow-empty -m "[${GIT_BRANCH}] Pushed by Jenkins: build #${BUILD_NUMBER}"
              git push -f origin ${GIT_BRANCH}
            '''
      }
    }
    stage('DIFF') {
      parallel {
        stage('vRABlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRABlueprint ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRABusinessGroup') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRABusinessGroup ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRACatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRACatalogItem ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAEntitledCatalogItem') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitledCatalogItem ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAEntitledService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitledService ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAEntitlement') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAEntitlement ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAExternalNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAExternalNetworkProfile ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAGroupPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAGroupPrincipal ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRANATNetworkProfile') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRANATNetworkProfile ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAPackage') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPackage ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAPropertyDefinition') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAPropertyDefinition ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAReservation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservation ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAReservationPolicy') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAReservationPolicy ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAResourceMetric') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceMetric ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAResourceOperation') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAResourceOperation ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAService') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAService ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAServiceBlueprint') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAServiceBlueprint ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAUserPrincipal') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAUserPrincipal ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
        stage('vRAVersion') {
          steps {
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
              sh "pwsh check.ps1 Get-vRAVersion ${platform}-current remotes/origin/${platform}-reference"
            }

          }
        }
      }
    }
    stage('Update Reference') {
      when {
        expression {
          BRANCH_NAME ==~ /.*-current/
        }

      }
      steps {
        sh 'git config user.name "jenkins"'
        sh 'git config user.email "jenkins@bt1resjnkns1.bpa.bouyguestelecom.fr"'
        sh 'git add --all'
        sh 'git rm -f .cached_session.json'
        sh 'git rm -rf ./export_old'
        sh 'git commit --allow-empty -m "[${GIT_BRANCH}] Pushed by Jenkins: build #${BUILD_NUMBER}"'
        sh "git push -f origin ${GIT_BRANCH}:${platform}-reference"
      }
    }
  }
  triggers {
    cron(BRANCH_NAME ==~ /(master|.*-current)/ ? '30 * * * *' : '')
  }
}