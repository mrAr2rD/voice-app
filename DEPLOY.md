# Инструкция по деплою AppCaster через Coolify

## Переменные окружения

### Обязательные

```env
RAILS_MASTER_KEY=d0352a89a39567b55c08da7a981577ff
RAILS_ENV=production
```

### Опциональные (для полного функционала)

```env
# API ключи для транскрибации
NEXARA_API_KEY=ваш_ключ_nexara

# OpenAI (озвучка TTS и генерация метаданных)
OPENAI_API_KEY=sk-ваш_ключ_openai

# ElevenLabs (озвучка TTS)
ELEVENLABS_API_KEY=ваш_ключ_elevenlabs

# OpenRouter (переводы через различные AI модели)
OPENROUTER_API_KEY=ваш_ключ_openrouter

# YouTube API (публикация видео)
GOOGLE_CLIENT_ID=ваш_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=ваш_client_secret
```

---

## Деплой через Coolify

### Вариант 1: Docker Compose (рекомендуется)

1. **Создайте новый сервис** в Coolify:
   - Тип: `Docker Compose`
   - Источник: GitHub репозиторий

2. **Укажите путь к docker-compose.yml**:
   ```
   docker-compose.yml
   ```

3. **Добавьте переменные окружения**:
   ```
   RAILS_MASTER_KEY=d0352a89a39567b55c08da7a981577ff
   ```

4. **Настройте домен** в Coolify для сервиса `web`

5. **Деплой** - Coolify автоматически:
   - Соберёт Docker образ
   - Запустит web и worker сервисы
   - Настроит volumes для данных

### Вариант 2: Только Dockerfile

1. **Создайте новый сервис**:
   - Тип: `Dockerfile`
   - Build Pack: `Dockerfile`

2. **Переменные окружения**:
   ```
   RAILS_MASTER_KEY=d0352a89a39567b55c08da7a981577ff
   RAILS_ENV=production
   RAILS_LOG_TO_STDOUT=true
   RAILS_SERVE_STATIC_FILES=true
   ```

3. **Порт**: `80`

4. **Health Check**: `/up`

5. **Для background jobs** создайте отдельный сервис:
   - Тот же образ
   - Command: `./bin/jobs`

---

## Структура сервисов

```
┌─────────────────────────────────────────────┐
│                  Coolify                     │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────┐      ┌─────────────┐      │
│  │     Web     │      │   Worker    │      │
│  │  (Rails +   │      │  (Solid     │      │
│  │  Thruster)  │      │   Queue)    │      │
│  │   :80       │      │             │      │
│  └──────┬──────┘      └──────┬──────┘      │
│         │                    │              │
│         └────────┬───────────┘              │
│                  │                          │
│         ┌───────┴────────┐                  │
│         │    Volumes     │                  │
│         │  - storage     │                  │
│         │  - sqlite_data │                  │
│         └────────────────┘                  │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Volumes и данные

### Важно! Настройте persistent volumes:

| Volume | Путь в контейнере | Описание |
|--------|-------------------|----------|
| `storage` | `/rails/storage` | Active Storage файлы |
| `sqlite_data` | `/rails/db` | SQLite база данных |

В Coolify добавьте volumes:
```yaml
/data/appcaster/storage:/rails/storage
/data/appcaster/db:/rails/db
```

---

## После первого деплоя

### 1. Проверьте здоровье приложения
```bash
curl https://ваш-домен.com/up
```

### 2. Создайте admin пользователя
Через Rails console (в контейнере):
```bash
docker exec -it <container_id> ./bin/rails console
```
```ruby
User.create!(
  name: "Admin",
  email: "admin@example.com",
  password: "secure_password",
  password_confirmation: "secure_password",
  admin: true
)
```

### 3. Настройте API ключи
Перейдите в `/admin/settings` и добавьте:
- Nexara API Key (транскрибация)
- OpenAI API Key (озвучка, генерация)
- ElevenLabs API Key (озвучка)
- OpenRouter API Key (переводы)

---

## Troubleshooting

### Логи
```bash
# Web сервис
docker logs -f <web_container_id>

# Worker сервис
docker logs -f <worker_container_id>
```

### База данных
```bash
# Миграции
docker exec -it <container_id> ./bin/rails db:migrate

# Консоль
docker exec -it <container_id> ./bin/rails console
```

### Перезапуск worker
```bash
docker restart <worker_container_id>
```

---

## Требования к серверу

- **RAM**: минимум 1GB (рекомендуется 2GB)
- **CPU**: 1 vCPU (рекомендуется 2 vCPU для видео обработки)
- **Диск**: 10GB+ (для хранения видео/аудио файлов)
- **FFmpeg**: включён в Docker образ

---

## Безопасность

⚠️ **ВАЖНО**: Не коммитьте `RAILS_MASTER_KEY` в репозиторий!

Храните ключи только в:
- Переменных окружения Coolify
- Секретах CI/CD
- Vault/Secret Manager

---

## Полезные ссылки

- [Coolify Documentation](https://coolify.io/docs)
- [Rails Credentials](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Solid Queue](https://github.com/rails/solid_queue)
