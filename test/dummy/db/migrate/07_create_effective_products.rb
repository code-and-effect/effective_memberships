class CreateEffectiveProducts < ActiveRecord::Migration[6.1]
  def change
    create_table :rings do |t|
      t.integer :owner_id
      t.string :owner_type

      t.integer :ring_wizard_id
      t.string :ring_wizard_type

      t.integer :size
      t.string :metal

      t.datetime :issued_at

      # Acts as purchasable
      t.integer :purchased_order_id
      t.integer :price
      t.boolean :tax_exempt, default: false
      t.string :qb_item_name

      t.timestamps
    end

    create_table :ring_wizards do |t|
      t.string :token

      t.integer :owner_id
      t.string :owner_type

      t.integer :user_id
      t.string :user_type

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :ring_wizards, [:owner_id, :owner_type]
    add_index :ring_wizards, :status
    add_index :ring_wizards, :token

    create_table :stamps do |t|
      t.integer :owner_id
      t.string :owner_type

      t.integer :stamp_wizard_id
      t.string :stamp_wizard_type

      t.integer :applicant_id
      t.string :applicant_type

      t.string :status
      t.text :status_steps

      t.string :category
      t.string :name
      t.string :name_confirmation

      t.datetime :issued_at

      # Acts as purchasable
      t.integer :purchased_order_id
      t.integer :price
      t.boolean :tax_exempt, default: false
      t.string :qb_item_name

      t.timestamps
    end

    create_table :stamp_wizards do |t|
      t.string :token

      t.integer :owner_id
      t.string :owner_type

      t.integer :user_id
      t.string :user_type

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :stamp_wizards, [:owner_id, :owner_type]
    add_index :stamp_wizards, :status
    add_index :stamp_wizards, :token

  end
end
