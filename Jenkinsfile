pipeline {
    agent any
    
    environment {
        TERRAFORM_DIR = 'terraform'
        TERRAFORM_SECURE_DIR = 'terraform-secure'
        TRIVY_VERSION = 'latest'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '========================================='
                echo 'Stage 1: Checking out source code'
                echo '========================================='
                
                checkout scm
                
                echo 'Source code checked out successfully'
                sh 'ls -la'
            }
        }
        
        stage('Install Trivy') {
            steps {
                echo '========================================='
                echo 'Installing Trivy Security Scanner'
                echo '========================================='
                
                script {
                    sh '''
                        # Check if Trivy is already installed
                        if ! command -v trivy &> /dev/null; then
                            echo "Installing Trivy..."
                            
                            # Install Trivy (Debian/Ubuntu)
                            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
                            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
                            apt-get update
                            apt-get install -y trivy
                        else
                            echo "Trivy is already installed"
                        fi
                        
                        trivy --version
                    '''
                }
            }
        }
        
        stage('Infrastructure Security Scan') {
            steps {
                echo '========================================='
                echo 'Stage 2: Scanning Terraform for Security Vulnerabilities'
                echo '========================================='
                
                script {
                    // Determine which Terraform directory to scan
                    def terraformPath = env.USE_SECURE_TERRAFORM == 'true' ? TERRAFORM_SECURE_DIR : TERRAFORM_DIR
                    
                    echo "Scanning Terraform files in: ${terraformPath}"
                    
                    // Run Trivy security scan
                    def scanResult = sh(
                        script: """
                            trivy config ${terraformPath} \
                                --severity HIGH,CRITICAL \
                                --format table \
                                --exit-code 1
                        """,
                        returnStatus: true
                    )
                    
                    echo "\n========================================="
                    echo "Security Scan Results"
                    echo "========================================="
                    
                    if (scanResult == 0) {
                        echo "✅ SUCCESS: No critical security vulnerabilities found!"
                        echo "The infrastructure code meets security standards."
                    } else {
                        echo "❌ FAILURE: Security vulnerabilities detected!"
                        echo "\n📋 VULNERABILITY REPORT:"
                        echo "========================================="
                        
                        // Run again without exit code to show full report
                        sh """
                            trivy config ${terraformPath} \
                                --severity HIGH,CRITICAL \
                                --format table
                        """
                        
                        echo "\n========================================="
                        echo "🔍 AI REMEDIATION GUIDANCE"
                        echo "========================================="
                        echo """
The security scan has identified vulnerabilities in your Terraform code.

NEXT STEPS:
1. Copy the vulnerability report above
2. Use an AI tool (ChatGPT, Claude, Gemini, etc.) with this prompt:

---
PROMPT FOR AI:
"I have the following security vulnerabilities in my Terraform code for GCP:

[PASTE TRIVY REPORT HERE]

Please:
1. Explain each vulnerability and its security risks
2. Provide the exact Terraform code fixes needed
3. Explain how each fix improves security
4. Show the corrected code"
---

3. Apply the AI-recommended fixes to your Terraform code
4. Update the USE_SECURE_TERRAFORM parameter to 'true'
5. Re-run this pipeline to verify fixes

CURRENT STATUS: Using vulnerable Terraform code (${terraformPath})
TO FIX: Switch to terraform-secure/ directory or fix terraform/ files
                        """
                        
                        error("Security scan failed. Please remediate vulnerabilities and re-run the pipeline.")
                    }
                }
            }
        }
        
        stage('Terraform Validation') {
            steps {
                echo '========================================='
                echo 'Stage 3: Validating Terraform Configuration'
                echo '========================================='
                
                script {
                    def terraformPath = env.USE_SECURE_TERRAFORM == 'true' ? TERRAFORM_SECURE_DIR : TERRAFORM_DIR
                    
                    dir(terraformPath) {
                        sh '''
                            # Initialize Terraform
                            terraform init -backend=false
                            
                            # Validate Terraform syntax
                            terraform validate
                            
                            echo "Terraform configuration is valid"
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo '========================================='
                echo 'Stage 4: Running Terraform Plan'
                echo '========================================='
                
                script {
                    def terraformPath = env.USE_SECURE_TERRAFORM == 'true' ? TERRAFORM_SECURE_DIR : TERRAFORM_DIR
                    
                    dir(terraformPath) {
                        sh '''
                            # Run Terraform plan
                            terraform plan -out=tfplan
                            
                            echo "\n========================================="
                            echo "Terraform plan completed successfully"
                            echo "========================================="
                            echo "Review the plan above to see what resources will be created."
                            echo "To apply: terraform apply tfplan"
                        '''
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo '\n========================================='
            echo '✅ PIPELINE COMPLETED SUCCESSFULLY!'
            echo '========================================='
            echo 'All stages passed:'
            echo '  ✓ Code checkout'
            echo '  ✓ Security scan'
            echo '  ✓ Terraform validation'
            echo '  ✓ Terraform plan'
            echo ''
            echo 'Next steps:'
            echo '  1. Review the Terraform plan'
            echo '  2. If satisfied, run: terraform apply'
            echo '  3. Access your application at the public IP'
            echo '========================================='
        }
        
        failure {
            echo '\n========================================='
            echo '❌ PIPELINE FAILED'
            echo '========================================='
            echo 'Please check the logs above for details.'
            echo 'Common issues:'
            echo '  - Security vulnerabilities in Terraform code'
            echo '  - Terraform syntax errors'
            echo '  - Missing dependencies'
            echo ''
            echo 'Refer to the AI Remediation Guidance above.'
            echo '========================================='
        }
        
        always {
            echo '\nPipeline execution completed at: ' + new Date().toString()
        }
    }
}
