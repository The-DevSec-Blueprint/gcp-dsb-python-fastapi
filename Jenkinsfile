pipeline {
    agent any

    environment {
       SONAR_TOKEN = credentials('sonar-analysis')
       SONAR_PROJECT_KEY = 'python-fastapi'
       DOCKER_IMAGE_NAME = 'python-fastapi'
       NEXUS_DOCKER_REGISTRY = 'nexus-dockerproxy.dsb-hub.local'
       NEXUS_DOCKER_PUSH_INDEX = 'nexus-dockerhub.dsb-hub.local'
       NEXUS_DOCKER_PUSH_PATH = 'repository/docker-host'
    }

    options {
        disableConcurrentBuilds()
    }

    stages {
        stage('Clone') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Gitea PAT', url: 'https://dsb-hub.local/damien/python-fastapi.git']])
            }
        }
        stage('Build and Install') {
            parallel {
                stage('Python Build') {
                    steps {
                        sh '''
                        python3 -m venv .env
                        . .env/bin/activate
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
                                    ${NEXUS_DOCKER_REGISTRY}/sonarsource/sonar-scanner-cli \
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
                            trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} > trivy-report.txt
                        '''
                    }
                }
            }
        }
        stage('Publish') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'nexus', passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                        sh """
                        docker login ${NEXUS_DOCKER_PUSH_INDEX} -u $NEXUS_USERNAME -p $NEXUS_PASSWORD
                        docker tag ${DOCKER_IMAGE_NAME}:${BUILD_NUMBER} ${NEXUS_DOCKER_PUSH_INDEX}/${NEXUS_DOCKER_PUSH_PATH}/${DOCKER_IMAGE_NAME}:latest
                        docker push ${NEXUS_DOCKER_PUSH_INDEX}/${NEXUS_DOCKER_PUSH_PATH}/${DOCKER_IMAGE_NAME}:latest
                        """
                    }
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
            cleanWs()
        }
    }

}