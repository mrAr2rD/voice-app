# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ProdMarket - Rails 8.1 приложение для создания видеоконтента: транскрибация аудио/видео, синтез речи (TTS), перевод текстов, сборка видео и публикация на YouTube.

## Development Commands

```bash
# Рабочая директория - app/
cd app

# Запуск сервера разработки (Rails + Tailwind watcher)
bin/dev

# Background jobs (Solid Queue)
bin/jobs

# База данных
bin/rails db:prepare
bin/rails db:migrate

# Тесты
bin/rails test
bin/rails test test/models/setting_test.rb    # Один файл
bin/rails test test/models/setting_test.rb:10 # Конкретный тест

# CI pipeline (rubocop + brakeman + bundler-audit + importmap audit + tests)
bin/ci

# Линтинг отдельно
bin/rubocop
bin/brakeman
```

## System Dependencies

- FFmpeg (обязательно для video_building: извлечение аудио, обрезка/зацикливание видео, вшивание субтитров)
- yt-dlp (загрузка с YouTube)

## Architecture

### Service Objects Pattern
Сервисы наследуются от `ApplicationService` и возвращают `Result`:
```ruby
result = Transcriptions::ProcessService.call(transcription)
result.success? # true/false
result.data     # данные при успехе
result.error    # ошибка при неудаче

# Callback chains
result.on_success { |data| ... }.on_failure { |error, data| ... }
```

### Domains

**Транскрибация** (`app/services/transcriptions/`):
- `ProcessService` - пайплайн: скачивание → извлечение аудио → API → парсинг сегментов
- `NexaraClient` - Nexara API для транскрибации
- `YoutubeDownloader` - загрузка с YouTube через yt-dlp
- `AudioExtractor` - извлечение аудио (FFmpeg)
- `ExportService` - экспорт в TXT/SRT/JSON

**Озвучка TTS** (`app/services/tts/`):
- `GenerationService` - генерация аудио
- `OpenaiClient`, `ElevenlabsClient` - провайдеры

**Перевод** (`app/services/translations/`):
- `TranslateService` - перевод через OpenRouter
- Бесплатные модели: DeepSeek, Gemini Flash, Grok

**Сборка видео** (`app/services/video_building/`):
- `ProcessService` - пайплайн сборки
- `AudioMergerService` - объединение аудио дорожек
- `VideoTrimmerService`, `VideoLooperService` - обрезка/зацикливание под аудио
- `VideoMuxerService` - соединение видео + аудио
- `SubtitleBurnerService` - вшивание субтитров

**YouTube** (`app/services/youtube/`):
- `AuthService`, `TokenRefreshService` - OAuth авторизация
- `UploadService` - загрузка видео
- `ThumbnailService`, `MetadataService` - превью и метаданные

**AI генерация** (`app/services/ai/`):
- `ThumbnailGeneratorService`, `MetadataGeneratorService`

**Голосовое клонирование** (`app/services/tts/`):
- `VoiceCloningService` - клонирование голоса через ElevenLabs
- `ElevenlabsClient.clone_voice` - API для создания клонов

**AI Script Writer** (`app/services/scripts/`):
- `GenerationService` - генерация сценариев через OpenRouter

**Auto-Clipping** (`app/services/clipping/`):
- `HighlightDetectorService` - AI-поиск интересных моментов
- `ClipCreatorService` - нарезка клипов (FFmpeg)

**YouTube Analytics** (`app/services/youtube/`):
- `AnalyticsService` - статистика канала и видео

### Background Jobs (Solid Queue)
- `TranscriptionProcessJob` (queue: `:transcription`)
- `VoiceGenerationJob` (queue: `:default`)
- `TranslationJob` (queue: `:default`)
- `VideoBuilderProcessJob` (queue: `:video_processing`)
- `YoutubeUploadJob` (queue: `:default`)
- `VoiceCloningJob` (queue: `:default`) - клонирование голоса
- `ScriptGenerationJob` (queue: `:default`) - генерация сценариев
- `VideoClipJob` (queue: `:video_processing`) - создание клипов

### Real-time Updates
Модели используют Turbo Streams через `broadcast_*` callbacks для обновления UI в реальном времени (см. `after_create_commit`, `after_update_commit`).

### Models
- `User` - пользователи (has_secure_password)
- `Project` - проекты для группировки контента
- `Transcription` - транскрибации (pending→processing→extracting_audio→transcribing→completed/failed)
- `TranscriptionSegment` - сегменты с таймкодами
- `VoiceGeneration` - озвучки (providers: elevenlabs, openai)
- `Translation` - переводы (pending→processing→completed/failed)
- `VideoBuilder` - сборщик видео (draft→processing→completed/failed)
- `YoutubeCredential` - OAuth токены YouTube (encrypted)
- `ClonedVoice` - клонированные голоса ElevenLabs
- `BatchJob` - пакетные задачи (transcription, voice_generation, translation)
- `Script` - AI-сценарии (types: tutorial, review, sales, educational...)
- `VideoClip` - короткие клипы для Shorts/Reels (9:16, 1:1, 4:5)
- `SocialAccount` - подключённые соц. сети (TikTok, Instagram, VK)
- `ScheduledPost` - запланированные публикации

### Settings
API ключи: `Setting.nexara_api_key`, `Setting.openai_api_key`, `Setting.elevenlabs_api_key`, `Setting.openrouter_api_key` (приоритет: БД → Rails credentials).

## Tech Stack
- Ruby 3.4.7, Rails 8.1
- SQLite3, Active Storage
- Hotwire (Turbo + Stimulus), Tailwind CSS
- Kamal для деплоя
