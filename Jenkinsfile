pipeline {
    agent any
    tools{
        nodejs('22.1.0')
    }
    stages {
        stage('Checkout') {
            steps {
                echo '========== Pulling latest code =========='
                git branch: 'main',
                    url: 'https://github.com/wak75/DummyRepo_MCP_hackathon.git'
            }
        }
        
        stage('Install Dependencies & Run Tests') {
            steps {
                echo '========== Installing dependencies =========='
                sh 'npm install'
                
                echo '========== Running tests =========='
                sh 'npm test'
            }
        }
    }
    
    post {
        always {
            echo '========== Pipeline execution completed =========='
        }
        success {
            echo '========== Pipeline passed successfully =========='
        }
        failure {
            echo '========== Pipeline failed =========='
        }
    }
}
