pipeline {
  agent any
  stages {
    stage('Connexion') {
      steps {
        sh 'pwsh connectToServer.ps1'
      }
    }
    stage('Capture plateform') {
      parrallel {
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
      }
    }
  }
}