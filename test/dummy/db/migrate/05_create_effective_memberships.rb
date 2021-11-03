class CreateEffectiveMemberships < ActiveRecord::Migration[6.0]
  def change

    # Add user fields
    add_column :users, :membership_category_id, :integer
    add_column :users, :membership_category_type, :string

    # Create Effective Membership Tables
    create_table :membership_categories do |t|
      t.string :title
      t.integer :position

      t.boolean :can_apply, default: false

      t.integer :applicant_fee
      t.integer :annual_fee

      t.datetime :updated_at
      t.datetime :created_at
    end

  end
end
