# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ProdMarket - Rails 8.1 приложение для транскрибации аудио/видео и синтеза речи (TTS). Поддерживает загрузку файлов, YouTube ссылки, экспорт в TXT/SRT/JSON.

## Development Commands

```bash
# Рабочая директория - app/
cd app

# Запуск сервера разработки (Rails + Tailwind watcher)
bin/dev

# Только Rails сервер
bin/rails server

# Background jobs (Solid Queue)
bin/jobs

# База данных
bin/rails db:prepare
bin/rails db:migrate
bin/rails db:reset         # Полный сброс

# Тесты
bin/rails test
bin/rails test test/models/setting_test.rb    # Один файл
bin/rails test test/models/setting_test.rb:10 # Одна строка

# Линтинг и безопасность
bin/rubocop
bin/brakeman
bin/bundler-audit

# Первоначальная настройка
bin/setup
```

## Architecture

### Service Objects Pattern
Сервисы наследуются от `ApplicationService` и возвращают `Result`:
```ruby
result = Transcriptions::ProcessService.call(transcription)
result.success? # true/false
result.data     # данные при успехе
result.error    # ошибка при неудаче
```

### Key Domains

**Транскрибация** (`app/services/transcriptions/`):
- `ProcessService` - основной пайплайн обработки
- `NexaraClient` - API клиент для транскрибации
- `YoutubeDownloader` - загрузка с YouTube
- `AudioExtractor` - извлечение аудио из видео (FFmpeg)
- `ExportService` - экспорт в TXT/SRT/JSON

**Озвучка TTS** (`app/services/tts/`):
- `GenerationService` - генерация аудио
- `OpenaiClient` - OpenAI TTS
- `ElevenlabsClient` - ElevenLabs API

### Background Jobs
Solid Queue с очередями:
- `TranscriptionProcessJob` (queue: `:transcription`)
- `VoiceGenerationJob` (queue: `:default`)

### Frontend
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- Stimulus контроллеры в `app/javascript/controllers/`

### Settings
Настройки хранятся в таблице `settings`. API ключи читаются через `Setting.nexara_api_key`, `Setting.openai_api_key`, `Setting.elevenlabs_api_key` (приоритет: БД → Rails credentials).

### Models
- `User` - пользователи (has_secure_password)
- `Transcription` - транскрибации (statuses: pending→processing→extracting_audio→transcribing→completed/failed)
- `TranscriptionSegment` - сегменты с таймкодами
- `VoiceGeneration` - озвучки (providers: elevenlabs, openai)

## Tech Stack
- Ruby 3.4.7, Rails 8.1
- SQLite3 (storage/*.sqlite3)
- Active Storage для файлов
- Kamal для деплоя
