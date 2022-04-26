#!groovy
@Library('Infrastructure') _

try {
  node {
    env.PATH = "$env.PATH:/usr/local/bin"

    stage('Checkout') {
      deleteDir()
      checkout scm
    }

    stage('Terraform install') {
      sh 'tfenv install'
    }

    stage('Terraform init') {
      sh 'terraform init'
    }

    stage('Terraform plan') {
      sh 'terraform plan'
    }
  }
}
catch (err) {
  throw err
}