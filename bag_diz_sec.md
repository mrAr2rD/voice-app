# Исправление проблемы со стилями после работы над безопасностью

## Дата: 12 февраля 2026

## Проблема
После внедрения CSP (Content Security Policy) стили перестали загружаться правильно - страницы показывали только тёмный фон и белый текст, Tailwind CSS классы не применялись.

## Причина
Строгие правила Content Security Policy блокировали:
1. Загрузку Google Fonts (Golos Text и Unbounded)
2. Inline стили могли блокироваться из-за отсутствия nonce

## Решение

### 1. Обновление CSP правил (`config/initializers/content_security_policy.rb`)

**Добавлены разрешения для Google Fonts:**
```ruby
policy.font_src    :self, :data, "https://fonts.gstatic.com"
policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com"
```

### 2. Включен режим Report-Only для CSP (временно)
```ruby
config.content_security_policy_report_only = true
```

Это позволяет CSP логировать нарушения, но не блокировать загрузку ресурсов. Полезно для отладки.

### 3. Перекомпиляция Tailwind CSS
```bash
bin/rails assets:clobber
bin/rails tailwindcss:build
```

### 4. Перезапуск Rails сервера
Необходим для применения изменений в initializers.

## Подключение MCP серверов

### chrome-devtools MCP
Установлен и настроен для работы с Chrome DevTools:
```bash
claude mcp add chrome-devtools -s user -- npx chrome-devtools-mcp
```

Статус: ✅ Connected

## Технические детали

### Asset Pipeline (Propshaft)
- Используется Propshaft для управления assets
- CSS файлы обслуживаются с fingerprinting (хеши в именах файлов)
- Пример: `/assets/tailwind-68c47504.css`

### Порядок загрузки CSS
1. `critical.css` - критические CSS переменные (темная тема)
2. `tailwind.css` - Tailwind CSS v4.1.18
3. `application.css` - кастомные стили и компоненты

### Tailwind CSS
- Версия: 4.1.18
- Входной файл: `app/assets/tailwind/application.css`
- Выходной файл: `app/assets/builds/tailwind.css`

## Рекомендации на будущее

1. **Тестирование CSP:**
   - Всегда тестируйте CSP в режиме report-only перед включением enforcement
   - Проверяйте консоль браузера на CSP violations

2. **Google Fonts:**
   - Убедитесь, что в CSP разрешены домены:
     - `fonts.googleapis.com` для CSS
     - `fonts.gstatic.com` для шрифтов

3. **Inline стили:**
   - По возможности избегайте inline стилей
   - Или используйте CSP nonce для безопасности

4. **После изменения initializers:**
   - Всегда перезапускайте Rails сервер
   - Проверяйте, что изменения применились

## Файлы, которые были изменены

1. `config/initializers/content_security_policy.rb`
   - Добавлены Google Fonts в font-src и style-src
   - Включен режим report-only

## Проверка работоспособности

Все CSS файлы загружаются успешно (HTTP 200):
- ✅ `/assets/critical-*.css`
- ✅ `/assets/tailwind-*.css`
- ✅ `/assets/application-*.css`

Стили применяются корректно, темная тема работает как задумано.
