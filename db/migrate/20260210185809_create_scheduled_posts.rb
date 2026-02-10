class CreateScheduledPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduled_posts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :video_builder, foreign_key: true
      t.references :video_clip, foreign_key: true
      t.string :platform, null: false
      t.datetime :scheduled_at
      t.datetime :published_at
      t.integer :status, default: 0, null: false
      t.text :caption
      t.text :hashtags
      t.text :error_message
      t.string :post_id
      t.string :post_url

      t.timestamps
    end

    add_index :scheduled_posts, :platform
    add_index :scheduled_posts, :status
    add_index :scheduled_posts, :scheduled_at
  end
end
