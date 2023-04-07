pipeline {
  agent any
  
  tools {
        terraform 'Jenkins-terraform'
  }
    
  environment {
    AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
    AWS_DEFAULT_REGION = 'us-east-1'
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
        sh 'terraform apply -auto-approve'
      }
    }
  }
  post {
    always {
      input 'Do you want to delete the resource?'
      script {
        dir('terraform') {
          sh 'terraform destroy -target=aws_s3_bucket.myagencya-bucket1 -auto-approve'
        }
        sh 'aws s3 rm s3://myagencya-bucket1 --recursive'
      }
    }
  }
}
