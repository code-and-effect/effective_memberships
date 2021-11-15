class CreateEffectiveMemberships < ActiveRecord::Migration[6.0]
  def change
    # Add user fields
    add_column :users, :membership_category_id, :integer
    add_column :users, :membership_joined_on, :date

    # Membership Categories
    create_table :membership_categories do |t|
      t.string :title
      t.integer :position

      t.boolean :can_apply, default: true
      t.boolean :can_renew, default: true

      t.integer :applicant_fee
      t.integer :annual_fee
      t.integer :renewal_fee

      t.datetime :updated_at
      t.datetime :created_at
    end

    # Applicants
    create_table :applicants do |t|
      t.string :token

      t.integer :user_id
      t.string :user_type

      t.integer :membership_category_id
      t.string :membership_category_type

      t.integer :from_membership_category_id
      t.string :from_membership_category_type

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at
      t.datetime :completed_at
      t.datetime :reviewed_at
      t.datetime :approved_at

      # Declined
      t.datetime :declined_at
      t.datetime :declined_reason

      # Applicant Educations
      t.text :applicant_educations_details

      # Applicant Experiences
      t.integer :applicant_experiences_months
      t.text :applicant_experiences_details

      t.datetime :updated_at
      t.datetime :created_at
    end

    # Applicant Educations
    create_table :applicant_educations do |t|
      t.integer :applicant_id

      t.date :start_on
      t.date :end_on

      t.string :institution
      t.string :location

      t.string :program
      t.string :degree_obtained

      t.datetime :updated_at
      t.datetime :created_at
    end

    # Applicant Experiences
    create_table :applicant_experiences do |t|
      t.integer :applicant_id

      t.string :category
      t.integer :months

      t.date :start_on
      t.date :end_on

      t.string :position
      t.string :employer

      t.boolean :still_work_here, default: false
      t.integer :percent_worked

      t.text :tasks_performed

      t.datetime :created_at
      t.datetime :updated_at
    end

    # Applicant References
    create_table :applicant_references do |t|
      t.integer :applicant_id

      t.string :name
      t.string :email
      t.string :phone

      t.string :status
      t.text :status_steps
      t.string :known
      t.string :relationship

      t.boolean :reservations
      t.text :reservations_reason

      t.text :work_history
      t.boolean :accept_declaration

      t.string :token
      t.datetime :last_notified_at

      t.datetime :created_at
      t.datetime :updated_at
    end

    # Applicant Courses
    create_table :applicant_course_areas do |t|
      t.string :title
      t.integer :position

      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :applicant_course_names do |t|
      t.integer :applicant_course_area_id

      t.string :title
      t.integer :position

      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :applicant_courses do |t|
      t.integer :applicant_course_area_id
      t.integer :applicant_course_name_id
      t.integer :applicant_id

      t.string  :title
      t.integer :amount

      t.string  :code
      t.text    :description

      t.datetime :created_at
      t.datetime :updated_at
    end

    # Fees
    create_table :fees do |t|
      t.string :category

      t.integer :purchased_order_id
      t.integer :membership_category_id

      t.integer :user_id
      t.string :user_type

      t.integer :parent_id
      t.string :parent_type

      t.string :title
      t.integer :price
      t.string :qb_item_name
      t.boolean :tax_exempt, default: false

      t.datetime :created_at
      t.datetime :updated_at
    end


  end
end
