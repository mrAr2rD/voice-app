# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_10_115909) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name"], name: "index_projects_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key"
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "transcription_segments", force: :cascade do |t|
    t.float "confidence"
    t.datetime "created_at", null: false
    t.float "end_time", null: false
    t.string "speaker"
    t.float "start_time", null: false
    t.text "text", null: false
    t.integer "transcription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["start_time"], name: "index_transcription_segments_on_start_time"
    t.index ["transcription_id"], name: "index_transcription_segments_on_transcription_id"
  end

  create_table "transcriptions", force: :cascade do |t|
    t.float "audio_duration_seconds", default: 0.0
    t.integer "cost_cents", default: 0
    t.datetime "created_at", null: false
    t.float "duration"
    t.text "error_message"
    t.text "full_text"
    t.string "language"
    t.string "original_filename"
    t.integer "progress", default: 0
    t.integer "project_id"
    t.integer "source_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "title"
    t.integer "tokens_used", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "youtube_url"
    t.index ["created_at"], name: "index_transcriptions_on_created_at"
    t.index ["project_id"], name: "index_transcriptions_on_project_id"
    t.index ["status"], name: "index_transcriptions_on_status"
    t.index ["user_id"], name: "index_transcriptions_on_user_id"
  end

  create_table "translations", force: :cascade do |t|
    t.integer "cost_cents", default: 0
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "model", default: "google/gemini-2.0-flash-001"
    t.integer "project_id"
    t.string "source_language", default: "auto"
    t.text "source_text", null: false
    t.integer "status", default: 0, null: false
    t.string "target_language", null: false
    t.integer "tokens_used", default: 0
    t.text "translated_text"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_translations_on_created_at"
    t.index ["project_id"], name: "index_translations_on_project_id"
    t.index ["status"], name: "index_translations_on_status"
    t.index ["user_id"], name: "index_translations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "video_builder_audio_sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0
    t.datetime "updated_at", null: false
    t.integer "video_builder_id", null: false
    t.integer "voice_generation_id"
    t.index ["video_builder_id", "position"], name: "idx_on_video_builder_id_position_11f576f6cc"
    t.index ["video_builder_id"], name: "index_video_builder_audio_sources_on_video_builder_id"
    t.index ["voice_generation_id"], name: "index_video_builder_audio_sources_on_voice_generation_id"
  end

  create_table "video_builders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.text "error_message"
    t.float "output_duration"
    t.integer "progress", default: 0
    t.integer "project_id"
    t.datetime "published_at"
    t.integer "status", default: 0, null: false
    t.boolean "subtitles_enabled", default: false
    t.integer "subtitles_font_size", default: 24
    t.string "subtitles_position", default: "bottom"
    t.string "subtitles_style", default: "default"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "video_mode", default: "trim"
    t.text "youtube_description"
    t.string "youtube_status", default: "not_published"
    t.text "youtube_tags"
    t.text "youtube_title"
    t.string "youtube_video_id"
    t.index ["created_at"], name: "index_video_builders_on_created_at"
    t.index ["project_id"], name: "index_video_builders_on_project_id"
    t.index ["status"], name: "index_video_builders_on_status"
    t.index ["user_id"], name: "index_video_builders_on_user_id"
    t.index ["youtube_status"], name: "index_video_builders_on_youtube_status"
  end

  create_table "voice_generations", force: :cascade do |t|
    t.integer "characters_count", default: 0
    t.integer "cost_cents", default: 0
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "project_id"
    t.integer "provider", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "voice_id", null: false
    t.string "voice_name"
    t.index ["created_at"], name: "index_voice_generations_on_created_at"
    t.index ["project_id"], name: "index_voice_generations_on_project_id"
    t.index ["status"], name: "index_voice_generations_on_status"
    t.index ["user_id"], name: "index_voice_generations_on_user_id"
  end

  create_table "youtube_credentials", force: :cascade do |t|
    t.text "access_token_encrypted"
    t.string "channel_id"
    t.string "channel_name"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.text "refresh_token_encrypted"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_youtube_credentials_on_user_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "projects", "users"
  add_foreign_key "transcription_segments", "transcriptions"
  add_foreign_key "transcriptions", "projects"
  add_foreign_key "transcriptions", "users"
  add_foreign_key "translations", "projects"
  add_foreign_key "translations", "users"
  add_foreign_key "video_builder_audio_sources", "video_builders"
  add_foreign_key "video_builder_audio_sources", "voice_generations"
  add_foreign_key "video_builders", "projects"
  add_foreign_key "video_builders", "users"
  add_foreign_key "voice_generations", "projects"
  add_foreign_key "voice_generations", "users"
  add_foreign_key "youtube_credentials", "users"
end
