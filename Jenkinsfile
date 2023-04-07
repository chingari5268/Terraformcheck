pipeline {
  agent any
  
  tools {
        terraform 'Jenkins-terraform'
  }
    
  environment {
    AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
    ACCESS_SECRET_ACCESS_KEY = credentials('ACCESS_SECRET_ACCESS_KEY')
  }

  stages {
    stage('Checkout') {
      steps {
         git branch: 'main' , url:'https://github.com/chingari5268/Terraformcheck.git'
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform init'
      }
    }

    stage('Terraform Plan') {
      steps {
        sh 'terraform plan'
      }
    }

    stage('Terraform Apply') {
      steps {
        input "Apply changes?"
        sh 'terraform apply -auto-approve'
      }
    }
  }

  post {
    always {
      sh 'terraform destroy -auto-approve'
    }
  }
}