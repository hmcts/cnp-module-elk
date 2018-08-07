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

  stage('Packer') {
    packerInstall {
      install_path = '.' // optional location to install packer
      platform = 'linux_amd64' // platform where packer will be installed
      version = '1.1.3' // version of packer to install
    }
  }

  withSubscription(subscription) {
    env.TF_VAR_product = productName

    spinInfra(productName, environment, planOnly, subscription)
  }
}

def packerInstall(body) {
  // evaluate the body block and collect configuration into the object
  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  // input checking
  config.install_path = config.install_path == null ? '/usr/bin' : config.install_path
  if (config.platform == null || config.version == null) {
    throw new Exception('A required parameter is missing from this packer.install block. Please consult the documentation for proper usage.')
  }

  // check if current version already installed
  if (fileExists("${config.install_path}/packer")) {
    installed_version = sh(returnStdout: true, script: "${config.install_path}/packer version").trim()
    if (installed_version =~ config.version) {
      print "Packer version ${config.version} already installed at ${config.install_path}."
      return
    }
  }
  // otherwise download and install specified version
  download_file("https://releases.hashicorp.com/packer/${config.version}/packer_${config.version}_${config.platform}.zip", 'packer.zip')
  sh 'ls -l packer.zip'
  sh 'pwd'
  sh 'ls -l /opt/jenkins/workspace/HMCTS_cnp-module-elk_master-DUAS6XIVJXFJ5QGTXXH46AS5NTBKF6ND4OOTMBS4IAGUTOSU7N3A/packer.zip'
  sh 'ls -l /usr/bin'
  unzip(zipFile: 'packer.zip', dir: config.install_path)
  sh "chmod +rx ${config.install_path}/packer"
  remove_file('packer.zip')
  print "Packer successfully installed at ${config.install_path}/packer."
}

def remove_file(String file) {
    new File(file).delete()
}

def download_file(String url, String dest) {
    sh "wget -q -O ${dest} ${url}"
}
