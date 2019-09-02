#!groovy
@Library('Infrastructure') _

try {
  node {

    def secrets = [
        secret('elk-private-key', 'ELK_PRIVATE_KEY'), 
        secret('elk-admin-user', 'ELK_USER'),
        secret('elk-admin-password', 'ELK_PASSWORD')
    ]

    env.PATH = "$env.PATH:/usr/local/bin"

    stage('Checkout') {
      deleteDir()
      checkout scm
    }

    stage('Terraform init') {
      sh 'terraform init'
    }

    stage('Terraform Linting Checks') {
      sh 'terraform validate -check-variables=false -no-color'
    }

    stage('Ansible Curator Playbook') {
      withAzureKeyvault(
      azureKeyVaultSecrets: secrets,
      keyVaultURLOverride: "https://rdo-ado-testing.vault.azure.net"
    ) {
        sh('git clone -b ubuntu git@github.com:hmcts/curator-role.git /tmp/ansible')
        sh('ansible-playbook --ssh-extra-args="-o StrictHostKeyChecking=no" --private-key $ELK_PRIVATE_KEY --extra-vars='{"elasticsearch_admin_username": "$ELK_USER", "elasticsearch_admin_password":"$ELK_PASSWORD"}' -i /tmp/ansible/inventory /tmp/ansible/curator-role/main.yml')
      }
    }
  }
}
catch (err) {
  throw err
}