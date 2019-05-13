pipeline {
  agent { label 'linux-docker-small' }
  options {
    buildDiscarder(logRotator(numToKeepStr:'25'))
    disableConcurrentBuilds()
    timestamps()
  }
  triggers {
    /*
      Restrict nightly builds to master branch
      Note: The BRANCH_NAME will only work with a multi-branch job using the github-branch-source
    */
    cron(BRANCH_NAME == "master" ? "H H(4-6) * * *" : "")
  }
  environment { PATH="${tool 'docker-latest'}/bin:$PATH" }
  stages {
    stage('Build Images') {
      steps {
        sh 'make image'
      }
    }
    stage('Deploy Images') {
      when {
        allOf {
          expression { env.CHANGE_ID == null }
          expression { env.BRANCH_NAME == "master" }
        }
      }
      environment {
        DOCKER_LOGIN = credentials('dockerhub-codicebot')
      }
      steps {
        sh 'docker login -u $DOCKER_LOGIN_USR -p $DOCKER_LOGIN_PSW'
        sh 'make push'
      }
    }
  }
}
