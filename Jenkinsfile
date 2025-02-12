pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Select the action to perform')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'develop', url: 'https://github.com/danielvh01/devops-python.git'
            }
        }
        stage('Terraform init') {
            steps {
                powershell 'terraform init'
            }
        }
        stage('Plan') {
            steps {
                powershell 'terraform plan -out tfplan'
            }
        }
        stage('Apply / Destroy') {
            steps {
                script {
                    if (params.action == 'apply') {
                        if (!params.autoApprove) {
                            def plan = readFile 'tfplan.txt'
                            input message: "Do you want to apply the plan?",
                            parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                        }
                        powershell 'terraform apply --auto-approve'
                    } else if (params.action == 'destroy') {
                        powershell 'terraform destroy --auto-approve'
                    } else {
                        error "Invalid action selected. Please choose either 'apply' or 'destroy'."
                    }
                }
            }
        }
    }
}
