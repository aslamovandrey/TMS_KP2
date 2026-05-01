pipeline {
    agent {
        docker {
            image 'docker:latest'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        // Определите IP вашей ВМ. Важно: добавьте этот IP в "Inventory" Ansible на Jenkins-сервере
        DEPLOY_HOST = '111.88.253.115'
        DOCKER_COMPOSE_PATH = '/home/andrew/project' // Путь на ВМ, куда скопировать файлы
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm // Забираем код из Git
            }
        }

        stage('Build Docker Image') {
            steps {
                // Вместо docker build локально, копируем на ВМ и собираем там
                sshagent(['ansible-ssh-key']) {
                    sh '''
                        # Создаем директорию на ВМ
                        ssh -o StrictHostKeyChecking=no andrew@${DEPLOY_HOST} "mkdir -p /home/andrew/app_builds/build-${BUILD_NUMBER}"
                        
                        # Копируем файлы приложения
                        scp -r ./app/* andrew@${DEPLOY_HOST}:/home/andrew/app_builds/build-${BUILD_NUMBER}/
                        
                        # Собираем образ на ВМ
                        ssh andrew@${DEPLOY_HOST} "cd /home/andrew/app_builds/build-${BUILD_NUMBER} && docker build -t quote-generator:build-${BUILD_NUMBER} ."
                    '''
                }
            }
        }

        stage('Health Check Test') {
            steps {
                script {
                    sh """
                        docker run -d --name test-quote -p 5001:5000 quote-generator:build-${BUILD_NUMBER}
                        sleep 5
                        curl --fail http://localhost:5001/health
                        docker stop test-quote
                        docker rm test-quote
                    """
                }
            }
        }

        stage('Deploy via Docker Compose') {
            steps {
                // Используем sshagent, чтобы Jenkins мог подключиться к ВМ
                sshagent(['ansible-ssh-key']) {
                    sh """
                        # Копируем docker-compose.yml и конфиг nginx на удаленную ВМ
                        scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${DEPLOY_HOST}:/home/ubuntu/
                        scp -o StrictHostKeyChecking=no nginx.conf ubuntu@${DEPLOY_HOST}:/home/ubuntu/
                        # Копируем папку с приложением и Dockerfile
                        scp -r ./app andrew@${DEPLOY_HOST}:${DOCKER_COMPOSE_PATH}/app

                        # Подключаемся к ВМ и выполняем деплой
                        ssh andrew@${DEPLOY_HOST} << EOF
                            cd ${DOCKER_COMPOSE_PATH}
                            # Пересобираем образы и запускаем сервисы в фоне
                            docker-compose up -d --build
                            # Проверяем статус
                            docker-compose ps
                        EOF
                    """
                }
            }
        }
    }

    post {
        // Очистка после сборки
        always {
            cleanWs()
        }
    }
}