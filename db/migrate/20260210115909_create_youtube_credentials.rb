class CreateYoutubeCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :youtube_credentials do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :access_token_encrypted
      t.text :refresh_token_encrypted
      t.datetime :expires_at
      t.string :channel_id
      t.string :channel_name

      t.timestamps
    end
  end
end
