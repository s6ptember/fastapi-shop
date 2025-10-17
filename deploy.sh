#!/bin/bash

# ============================================================================
# Скрипт автоматического развертывания FastAPI Shop на VPS
# ============================================================================

set -e  # Останавливаем выполнение при любой ошибке

# Цвета для красивого вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Функции для красивого вывода
print_header() {
    echo -e "\n${BOLD}${MAGENTA}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${MAGENTA}║${NC}  $1"
    echo -e "${BOLD}${MAGENTA}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

print_step() {
    echo -e "\n${BOLD}${BLUE}▶${NC} $1${NC}"
}

# Проверка, что скрипт запущен с правами root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Этот скрипт должен быть запущен с правами root (используйте sudo)"
        exit 1
    fi
}

# Приветствие
show_welcome() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
   ╔═══════════════════════════════════════════════════════════╗
   ║                                                           ║
   ║       🛍️  FASTAPI SHOP - СКРИПТ РАЗВЕРТЫВАНИЯ 🛍️         ║
   ║                                                           ║
   ║         Автоматическая установка и настройка             ║
   ║                   на Ubuntu VPS                          ║
   ║                                                           ║
   ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Диалоговое меню для ввода данных
get_user_input() {
    print_header "НАСТРОЙКА ПАРАМЕТРОВ ПРОЕКТА"

    # Домен
    while true; do
        echo -e "${BOLD}${YELLOW}Введите основной домен (например: myshop.com):${NC}"
        read -p "> " DOMAIN
        if [[ -z "$DOMAIN" ]]; then
            print_error "Домен не может быть пустым!"
        elif [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]]; then
            print_error "Некорректный формат домена!"
        else
            print_success "Домен принят: $DOMAIN"
            break
        fi
    done

    # Email для Let's Encrypt
    echo -e "\n${BOLD}${YELLOW}Введите email для сертификатов Let's Encrypt:${NC}"
    read -p "> " EMAIL
    while [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        print_error "Некорректный формат email!"
        read -p "> " EMAIL
    done
    print_success "Email принят: $EMAIL"

    # Название приложения
    echo -e "\n${BOLD}${YELLOW}Введите название магазина (по умолчанию: FastAPI Shop):${NC}"
    read -p "> " APP_NAME
    APP_NAME=${APP_NAME:-"FastAPI Shop"}
    print_success "Название: $APP_NAME"

    # Подтверждение
    echo -e "\n${BOLD}${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Проверьте введенные данные:${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "  Домен:          ${GREEN}$DOMAIN${NC}"
    echo -e "  WWW Домен:      ${GREEN}www.$DOMAIN${NC}"
    echo -e "  Email:          ${GREEN}$EMAIL${NC}"
    echo -e "  Название:       ${GREEN}$APP_NAME${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"

    read -p "Всё верно? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Настройка отменена. Перезапустите скрипт."
        exit 0
    fi
}

# Создание .env файла
create_env_file() {
    print_step "Создание файла конфигурации .env"

    cat > .env << EOF
# Domain Configuration
DOMAIN=$DOMAIN
EMAIL=$EMAIL

# Application
APP_NAME=$APP_NAME
DEBUG=False

# CORS Origins (comma-separated)
CORS_ORIGINS=https://$DOMAIN,https://www.$DOMAIN

# API Configuration
VITE_API_BASE_URL=https://$DOMAIN/api
EOF

    print_success ".env файл создан успешно"
}

# Создание backend .env файла
create_backend_env_file() {
    print_step "Создание backend/.env файла"

    cat > backend/.env << EOF
# Application
APP_NAME=$APP_NAME
DEBUG=False

# Database
DATABASE_URL=sqlite:///./shop.db

# CORS Origins
CORS_ORIGINS=https://$DOMAIN,https://www.$DOMAIN

# Static files
STATIC_DIR=static
IMAGES_DIR=static/images
EOF

    print_success "backend/.env файл создан успешно"
}

# Обновление системы
update_system() {
    print_step "Обновление системы Ubuntu"
    apt-get update -qq > /dev/null 2>&1
    apt-get upgrade -y -qq > /dev/null 2>&1
    print_success "Система обновлена"
}

# Установка необходимых пакетов
install_dependencies() {
    print_step "Установка необходимых пакетов"

    PACKAGES=(
        "curl"
        "wget"
        "git"
        "software-properties-common"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )

    for package in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            print_info "Установка $package..."
            apt-get install -y -qq "$package" > /dev/null 2>&1
            print_success "$package установлен"
        else
            print_info "$package уже установлен"
        fi
    done
}

# Остановка процессов на порту 80
kill_port_80() {
    print_step "Проверка процессов на порту 80"

    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Обнаружены процессы на порту 80"
        print_info "Останавливаем процессы..."

        PIDS=$(lsof -Pi :80 -sTCP:LISTEN -t)
        for PID in $PIDS; do
            PROCESS_NAME=$(ps -p $PID -o comm=)
            print_info "Останавливаем процесс: $PROCESS_NAME (PID: $PID)"
            kill -9 $PID 2>/dev/null || true
        done

        sleep 2

        if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
            print_error "Не удалось освободить порт 80"
            exit 1
        else
            print_success "Порт 80 освобожден"
        fi
    else
        print_success "Порт 80 свободен"
    fi
}

# Установка Docker
install_docker() {
    print_step "Проверка установки Docker"

    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
        print_success "Docker уже установлен (версия: $DOCKER_VERSION)"
    else
        print_info "Установка Docker..."

        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        apt-get update -qq > /dev/null 2>&1
        apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1

        systemctl start docker
        systemctl enable docker > /dev/null 2>&1

        DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
        print_success "Docker установлен успешно (версия: $DOCKER_VERSION)"
    fi
}

# Установка Certbot
install_certbot() {
    print_step "Установка Certbot для SSL сертификатов"

    if command -v certbot &> /dev/null; then
        print_success "Certbot уже установлен"
    else
        print_info "Установка Certbot..."
        apt-get install -y -qq certbot > /dev/null 2>&1
        print_success "Certbot установлен"
    fi
}

# Получение SSL сертификатов
obtain_ssl_certificates() {
    print_step "Получение SSL сертификатов Let's Encrypt"

    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        print_warning "Сертификаты для $DOMAIN уже существуют"
        read -p "Перевыпустить сертификаты? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Используем существующие сертификаты"
            return 0
        fi
    fi

    mkdir -p certbot/www

    print_info "Запуск временного веб-сервера для верификации домена..."

    docker run --rm -d \
        --name nginx_certbot_temp \
        -p 80:80 \
        -v "$(pwd)/certbot/www:/usr/share/nginx/html" \
        nginx:alpine > /dev/null 2>&1

    sleep 3

    print_info "Запрос сертификатов для доменов: $DOMAIN, www.$DOMAIN"

    certbot certonly --webroot \
        --webroot-path="$(pwd)/certbot/www" \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --force-renewal \
        -d "$DOMAIN" \
        -d "www.$DOMAIN"

    docker stop nginx_certbot_temp > /dev/null 2>&1 || true

    if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
        print_success "SSL сертификаты успешно получены"
        print_info "Сертификаты сохранены в: /etc/letsencrypt/live/$DOMAIN/"
    else
        print_error "Не удалось получить SSL сертификаты"
        print_warning "Проверьте, что домены $DOMAIN и www.$DOMAIN указывают на этот сервер"
        exit 1
    fi
}

# Настройка Nginx конфигурации
configure_nginx() {
    print_step "Настройка Nginx конфигурации"

    cat > nginx/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server_tokens off;
    client_max_body_size 10M;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name $DOMAIN www.$DOMAIN;

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://\$host\$request_uri;
        }
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name $DOMAIN www.$DOMAIN;

        ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Frontend (Vue.js)
        location / {
            proxy_pass http://frontend:80;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        # Backend API
        location /api {
            proxy_pass http://backend:8000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;

            proxy_http_version 1.1;
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }

        # Static files from backend
        location /static/ {
            alias /app/backend/static/;
            expires 30d;
            add_header Cache-Control "public, immutable";
        }

        # Health check
        location /health {
            proxy_pass http://backend:8000;
            access_log off;
        }
    }
}
EOF

    print_success "Nginx конфигурация создана"
}

# Обновление docker-compose.yml
update_docker_compose() {
    print_step "Обновление docker-compose.yml"

    cat > docker-compose.yml << EOF
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: backend/Dockerfile
    container_name: fashop_backend
    command: uvicorn backend.app.main:app --host 0.0.0.0 --port 8000
    volumes:
      - ./backend:/app/backend
      - ./backend/shop.db:/app/backend/shop.db
      - backend_static:/app/backend/static
    environment:
      - APP_NAME=$APP_NAME
      - DEBUG=False
      - DATABASE_URL=sqlite:///./backend/shop.db
      - CORS_ORIGINS=https://$DOMAIN,https://www.$DOMAIN
    expose:
      - "8000"
    restart: unless-stopped
    networks:
      - fashop_network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - VITE_API_BASE_URL=https://$DOMAIN/api
    container_name: fashop_frontend
    depends_on:
      - backend
    expose:
      - "80"
    restart: unless-stopped
    networks:
      - fashop_network

  nginx:
    image: nginx:alpine
    container_name: fashop_nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - backend_static:/app/backend/static:ro
      - ./certbot/www:/var/www/certbot:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - backend
      - frontend
    restart: unless-stopped
    networks:
      - fashop_network

  certbot:
    image: certbot/certbot
    container_name: fashop_certbot
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait \$\${!}; done;'"
    restart: unless-stopped
    networks:
      - fashop_network

networks:
  fashop_network:
    driver: bridge

volumes:
  backend_static:
EOF

    print_success "docker-compose.yml обновлен"
}

# Обновление backend Dockerfile
update_backend_dockerfile() {
    print_step "Обновление backend Dockerfile"

    cat > backend/Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \\
    gcc \\
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .

# Создаем директорию static в правильном месте
RUN mkdir -p static/images

RUN chmod -R 755 static

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

    print_success "backend/Dockerfile обновлен"
}

# Обновление frontend Dockerfile для передачи API URL
update_frontend_dockerfile() {
    print_step "Обновление frontend Dockerfile"

    cat > frontend/Dockerfile << EOF
FROM node:20-alpine as build

WORKDIR /app

ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=\${VITE_API_BASE_URL}

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

    print_success "frontend/Dockerfile обновлен"
}

# Создание необходимых директорий
create_directories() {
    print_step "Создание необходимых директорий"

    DIRS=(
        "backend/static/images"
        "certbot/www"
    )

    for dir in "${DIRS[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            print_success "Создана директория: $dir"
        else
            print_info "Директория уже существует: $dir"
        fi
    done

    chmod -R 755 backend/static 2>/dev/null || true
    print_success "Права доступа установлены"
}

# Сборка и запуск Docker контейнеров
build_and_run_docker() {
    print_step "Сборка и запуск Docker контейнеров"

    if docker ps -a | grep -q "fashop"; then
        print_info "Останавливаем существующие контейнеры..."
        docker compose down > /dev/null 2>&1 || true
        print_success "Старые контейнеры остановлены"
    fi

    print_info "Сборка Docker образов (это может занять несколько минут)..."
    docker compose build --no-cache > /dev/null 2>&1
    print_success "Docker образы собраны"

    print_info "Запуск контейнеров..."
    docker compose up -d

    print_info "Ожидание запуска сервисов..."
    sleep 15

    STATUS=$(docker compose ps | grep -c "Up" || echo "0")

    if [ "$STATUS" -ge 2 ]; then
        print_success "Все контейнеры запущены успешно"
    else
        print_warning "Некоторые контейнеры могут быть не запущены"
        print_info "Проверьте статус: docker compose ps"
    fi
}

# Заполнение базы данных тестовыми данными
seed_database() {
    print_step "Заполнение базы данных тестовыми данными"

    print_info "Проверка наличия данных в базе..."

    sleep 5

    print_info "Запуск скрипта seed_data.py..."
    docker compose exec -T backend python backend/seed_data.py

    if [ $? -eq 0 ]; then
        print_success "База данных успешно заполнена"
    else
        print_warning "Возможно, база уже содержит данные"
    fi
}

# Проверка работоспособности
check_health() {
    print_step "Проверка работоспособности приложения"

    print_info "Ожидание инициализации сервиса..."
    sleep 5

    if curl -f -s http://localhost:8000/health > /dev/null 2>&1; then
        print_success "Backend отвечает на запросы"
    else
        print_warning "Backend пока не отвечает (может требоваться больше времени)"
    fi

    print_info "Проверка HTTPS доступности..."
    sleep 3
    if curl -f -s -k "https://$DOMAIN/health" > /dev/null 2>&1; then
        print_success "HTTPS работает корректно"
    else
        print_warning "HTTPS может требовать дополнительного времени для инициализации"
    fi
}

# Показать информацию о развертывании
show_deployment_info() {
    clear
    print_header "РАЗВЕРТЫВАНИЕ ЗАВЕРШЕНО УСПЕШНО! 🎉"

    echo -e "${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║                   ИНФОРМАЦИЯ О ПРОЕКТЕ                       ║${NC}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}\n"

    echo -e "${BOLD}🌐 URLs:${NC}"
    echo -e "   Магазин:           ${CYAN}https://$DOMAIN${NC}"
    echo -e "   WWW версия:        ${CYAN}https://www.$DOMAIN${NC}"
    echo -e "   API Docs:          ${CYAN}https://$DOMAIN/api/docs${NC}"
    echo -e "   Health Check:      ${CYAN}https://$DOMAIN/health${NC}"

    echo -e "\n${BOLD}📝 Полезные команды:${NC}"
    echo -e "   Просмотр логов:         ${CYAN}docker compose logs -f${NC}"
    echo -e "   Логи backend:           ${CYAN}docker compose logs -f backend${NC}"
    echo -e "   Логи frontend:          ${CYAN}docker compose logs -f frontend${NC}"
    echo -e "   Перезапуск:             ${CYAN}docker compose restart${NC}"
    echo -e "   Остановка:              ${CYAN}docker compose down${NC}"
    echo -e "   Статус контейнеров:     ${CYAN}docker compose ps${NC}"
    echo -e "   Пересоздать данные:     ${CYAN}docker compose exec backend python backend/seed_data.py${NC}"

    echo -e "\n${BOLD}📂 Важные файлы:${NC}"
    echo -e "   Конфигурация:    ${CYAN}.env${NC}"
    echo -e "   Backend config:  ${CYAN}backend/.env${NC}"
    echo -e "   База данных:     ${CYAN}backend/shop.db${NC}"
    echo -e "   SSL сертификаты: ${CYAN}/etc/letsencrypt/live/$DOMAIN/${NC}"

    echo -e "\n${BOLD}🔄 Обновление сертификатов:${NC}"
    echo -e "   Сертификаты автоматически обновляются через контейнер certbot"
    echo -e "   Ручное обновление: ${CYAN}docker compose restart certbot${NC}"

    echo -e "\n${BOLD}📦 Структура проекта:${NC}"
    echo -e "   Backend:  FastAPI (SQLite) - порт 8000"
    echo -e "   Frontend: Vue.js 3 + Vite - порт 80 (внутри контейнера)"
    echo -e "   Nginx:    Reverse Proxy + SSL - порты 80/443"

    echo -e "\n${BOLD}${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║  Ваш магазин доступен по адресу: https://$DOMAIN         ║${NC}"
    echo -e "${BOLD}${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
}

# Основная функция
main() {
    show_welcome

    print_info "Проверка прав доступа..."
    check_root

    get_user_input

    print_header "НАЧАЛО УСТАНОВКИ"

    create_env_file
    create_backend_env_file
    update_system
    install_dependencies
    kill_port_80
    install_docker
    install_certbot
    obtain_ssl_certificates
    configure_nginx
    update_docker_compose
    update_frontend_dockerfile
    create_directories
    build_and_run_docker
    seed_database
    check_health

    show_deployment_info

    print_success "Развертывание завершено!"
}

# Обработка прерывания
trap 'echo -e "\n${RED}Установка прервана пользователем${NC}"; exit 130' INT

# Запуск основной функции
main

exit 0
