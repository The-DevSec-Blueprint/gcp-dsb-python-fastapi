pipeline {
    agent any

    environment {
       SONAR_TOKEN = credentials('sonar-analysis')
       SONAR_PROJECT_KEY = 'python-fastapi'
       DOCKER_IMAGE_NAME = 'python-fastapi'
    }

    stages {
        stage('Clone') {
            steps {
                checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'Gitea PAT', url: 'http://10.0.0.22/damien/python-fastapi.git']])
            }
        }
        stage('Build and Install') {
            parallel {
                stage('Python Build') {
                    steps {
                        sh '''
                        python -m venv .env
                        source .env/bin/activate
                        pip install -r requirements.txt
                        '''
                    }
                }
                stage('Docker Compile') {
                    steps {
                        sh 'docker build -t ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} .'
                    }
                }
            }
        }
        stage('Security Scan'){
            parallel {
                stage('Sonar Scan') {
                    steps {
                        script {
                            try{
                                withSonarQubeEnv(installationName: 'Sonar Server', credentialsId: 'sonar-analysis') {
                                    sh '''
                                    docker run --rm \
                                    -e SONAR_HOST_URL="${SONAR_HOST_URL}" \
                                    -e SONAR_TOKEN="${SONAR_TOKEN}" \
                                    -v "$(pwd):/usr/src" \
                                    sonarsource/sonar-scanner-cli \
                                    -Dsonar.projectKey="${SONAR_PROJECT_KEY}" \
                                    -Dsonar.qualitygate.wait=true \
                                    -Dsonar.sources=.
                                    '''
                                }
                            } catch (Exception e) {
                                // Handle the error
                                echo "Quality Qate check has failed: ${e}"
                                currentBuild.result = 'UNSTABLE' // Mark the build as unstable instead of failing
                            }
                        }
                    }
                }
                stage('Security Scan') {
                    steps {
                        sh '''
                            trivy image --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER}
                        '''
                    }
                }
            }
        }
    }
    post {
        always {
            sh 'docker image prune -f'
            cleanWs()
        }
    }

}