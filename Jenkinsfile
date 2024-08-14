pipeline { 
    agent any 

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically apply or destroy changes after planning')
        choice(name: 'action', choices: ['plan', 'apply', 'destroy'], description: 'Select the action to perform')
    }

    environment { 
        // Define environment variables for Terraform if needed 
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id') // Use the ID of your AWS credentials 
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key') // Use the ID of your AWS credentials 
        TF_VAR_region = 'us-east-1' 
    } 

    stages { 
        stage('Checkout') { 
            steps { 
                git branch: 'main', url: 'https://github.com/Taha-coder/Ekart.git' 
            } 
        } 

        stage('Initialize Terraform') { 
            steps { 
                script { 
                    // Initialize Terraform in the Terraform directory 
                    dir('Terraform') { 
                        sh 'terraform init' 
                    } 
                } 
            } 
        } 

        stage('Plan Terraform') { 
            when {
                expression { params.action == 'plan' || params.action == 'apply' }
            }
            steps { 
                script { 
                    // Generate Terraform execution plan 
                    dir('Terraform') { 
                        sh 'terraform plan -out=tfplan' 
                        sh 'terraform show -no-color tfplan > tfplan.txt' 
                    } 
                } 
            } 
        } 

        stage('Apply / Destroy Terraform') { 
            when {
                expression { params.action == 'apply' || params.action == 'destroy' }
            }
            steps { 
                script { 
                    dir('Terraform') {
                        if (params.action == 'apply') {
                            if (!params.autoApprove) {
                                def plan = readFile('tfplan.txt')
                                input message: "Review the Terraform plan", parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                            }
                            sh 'terraform apply -input=false tfplan'
                        } else if (params.action == 'destroy') {
                            if (!params.autoApprove) {
                                def plan = readFile('tfplan.txt')
                                input message: "Review the Terraform destroy plan", parameters: [text(name: 'Plan', description: 'Please review the destroy plan', defaultValue: plan)]
                            }
                            sh 'terraform destroy -auto-approve'
                        } else {
                            error "Invalid action selected. Please choose 'apply' or 'destroy'."
                        }
                    }
                } 
            } 
        } 
    } 

    post { 
        success { 
            echo 'Terraform deployment successful!' 
        } 
        failure { 
            echo 'Terraform deployment failed.' 
        } 
    } 
}
