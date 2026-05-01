pipeline {
    agent any

    environment {
        // Определите IP вашей ВМ. Важно: добавьте этот IP в "Inventory" Ansible на Jenkins-сервере
        DEPLOY_HOST = '111.88.253.115'
        DEPLOY_USER = 'andrew'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm // Забираем код из Git
            }
        }

        stage('Build and Deploy') {
            steps {
                // Используем SSH для выполнения команд на хостовой VM
                sshagent(['ansible-ssh-key']) {
                    sh """
                        echo "=== Копируем файлы на сервер ==="
                        scp -o StrictHostKeyChecking=no docker-compose.yml ${DEPLOY_USER}@${DEPLOY_HOST}:/home/${DEPLOY_USER}/
                        scp -o StrictHostKeyChecking=no nginx.conf ${DEPLOY_USER}@${DEPLOY_HOST}:/home/${DEPLOY_USER}/
                        scp -o StrictHostKeyChecking=no -r ./app ${DEPLOY_USER}@${DEPLOY_HOST}:/home/${DEPLOY_USER}/
                        
                        echo "=== Сборка и деплой на сервере ==="
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} << 'EOF'
                            cd /home/${DEPLOY_USER}
                            
                            # Останавливаем старые контейнеры (если есть)
                            docker-compose down 2>/dev/null || true
                            
                            # Собираем и запускаем
                            docker-compose up -d --build
                            
                            # Проверяем статус
                            echo "=== Статус контейнеров ==="
                            docker-compose ps
                            
                            # Проверяем health endpoint
                            echo "=== Проверка health ==="
                            sleep 3
                            curl -s http://localhost:5000/health
                            
                            echo ""
                            echo "=== Деплой успешно завершен! ==="
                        EOF
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Pipeline выполнен успешно!"
            echo "Приложение доступно: http://${DEPLOY_HOST}:5000"
        }
        failure {
            echo "❌ Pipeline завершился с ошибкой"
        }
    }
}