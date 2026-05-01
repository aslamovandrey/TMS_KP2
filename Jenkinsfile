pipeline {
    agent any

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
                script {
                    // Собираем образ приложения локально в Jenkins (или на агенте)
                    docker.build("quote-generator:build-${env.BUILD_NUMBER}", "./app")
                }
            }
        }

        stage('Health Check Test') {
            steps {
                script {
                    // Запускаем контейнер для проверки эндпоинта /health
                    def testContainer = docker.image("quote-generator:build-${env.BUILD_NUMBER}").run("-d -p 5001:5000")
                    // Ждем пару секунд для инициализации приложения
                    sh 'sleep 5'
                    // Проверяем, что health-check возвращает успешный код (200)
                    sh 'curl --fail http://localhost:5001/health'
                    // Останавливаем и удаляем тестовый контейнер
                    testContainer.stop()
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