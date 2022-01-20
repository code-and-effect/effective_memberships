class CreateEffectiveOrganizations < ActiveRecord::Migration[6.0]
  def change
    # Organizations
    create_table :organizations do |t|
      t.string    :title
      t.string    :email

      t.string    :category
      t.text      :notes

      t.integer   :roles_mask
      t.integer   :representatives_count, default: 0

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :organizations, :title

    # Representatives
    create_table :representatives do |t|
      t.integer :organization_id
      t.string :organization_type

      t.integer :user_id
      t.string :user_type

      t.integer :roles_mask

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :representatives, [:organization_id, :organization_type]
    add_index :representatives, [:user_id, :user_type]

  end
end
