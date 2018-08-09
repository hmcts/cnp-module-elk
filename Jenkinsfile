#!groovy

@Library('Infrastructure') _

properties([
    parameters([
        string(name: 'PRODUCT_NAME', defaultValue: 'ccd-elk', description: ''),
        string(name: 'ENVIRONMENT', defaultValue: 'db-sandbox', description: 'Suffix for resources created'),
        choice(name: 'SUBSCRIPTION', choices: 'sandbox\nprod\nnonprod', description: 'Azure subscriptions available to build in'),
        booleanParam(name: 'PLAN_ONLY', defaultValue: true, description: 'set to true for skipping terraform apply'),
        booleanParam(name: 'BUILD_LOGSTASH_IMAGE', defaultValue: false, description: 'set to true to build a new Logstash image')
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

  if (params.BUILD_LOGSTASH_IMAGE == true) {
    stage('Packer Install') {
      packerInstall {
        install_path = '.' // optional location to install packer
        platform = 'linux_amd64' // platform where packer will be installed
        version = '1.1.3' // version of packer to install
      }
    }

    stage('Packer Build Image') {
      withSubscription(subscription) {
        packerBuild {
          bin = './packer' // optional location of packer install
          template = 'src/packer_images/logstash.packer.json'
          var = ["resource_group_name=ccd-definition-store-elastic-search-sandbox"] // optional variable setting
        }
      }
    }
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
  unzip(zipFile: 'packer.zip', dir: config.install_path)
  sh "chmod +rx ${config.install_path}/packer"
  remove_file('packer.zip')
  print "Packer successfully installed at ${config.install_path}/packer."
}

def remove_file(String file) {
    sh "rm ${file}"
}

def download_file(String url, String dest) {
    sh "wget -q -O ${dest} ${url}"
}

def packerBuild(body) {
  // evaluate the body block and collect configuration into the object
  def config = [:]
  body.resolveStrategy = Closure.DELEGATE_FIRST
  body.delegate = config
  body()

  // input checking
  if (config.template == null) {
    throw new Exception('The required template parameter was not set.')
  }
  config.bin = config.bin == null ? 'packer' : config.bin

  if (fileExists(config.template)) {
    // create artifact with packer
    try {
      cmd = "${config.bin} build -color=false"

      // check for optional inputs
      if (config.var_file != null) {
        if (fileExists(config.var_file)) {
          cmd += " -var_file=${config.var_file}"
        }
        else {
          throw new Exception("The var file ${config.var_file} does not exist!")
        }
      }
      if (config.var != null) {
        config.var.each() {
          cmd += " -var ${it}"
        }
      }
      if (config.only != null) {
        cmd += " -only=${config.only}"
      }

      sh "${cmd} ${config.template}"
    }
    catch(Exception error) {
      print 'Failure using packer build.'
      throw error
    }
    print 'Packer build artifact created successfully.'
  }
  else {
    throw new Exception("The template file ${config.template} does not exist!")
  }
}