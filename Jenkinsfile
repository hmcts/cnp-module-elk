#!groovy

@Library('Infrastructure') _

properties([
    parameters([
        string(name: 'PRODUCT_NAME', defaultValue: 'ccd-elk', description: ''),
        string(name: 'ENVIRONMENT', defaultValue: 'db-sandbox', description: 'Suffix for resources created'),
        choice(name: 'SUBSCRIPTION', choices: 'sandbox\nprod\nnonprod', description: 'Azure subscriptions available to build in'),
        booleanParam(name: 'PLAN_ONLY', defaultValue: true, description: 'set to true for skipping terraform apply')
    ])
])

productName = params.PRODUCT_NAME
environment = params.ENVIRONMENT
subscription = params.SUBSCRIPTION
planOnly = params.PLAN_ONLY

node {
  env.PATH = "$env.PATH:/usr/local/bin"
  def az = { cmd -> return sh(script: "env AZURE_CONFIG_DIR=/opt/jenkins/.azure-$subscription az $cmd", returnStdout: true).trim() }

  stage('Checkout') {
    deleteDir()
    checkout scm
  }

  withSubscription(subscription) {
    env.TF_VAR_product = productName

    spinInfra(productName, environment, planOnly, subscription)
  }
}
