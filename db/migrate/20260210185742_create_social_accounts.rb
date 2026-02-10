class CreateSocialAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :social_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :platform, null: false
      t.text :access_token_encrypted
      t.text :refresh_token_encrypted
      t.datetime :expires_at
      t.string :account_id
      t.string :account_name
      t.string :account_avatar
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :social_accounts, :platform
    add_index :social_accounts, [ :user_id, :platform ], unique: true
  end
end
