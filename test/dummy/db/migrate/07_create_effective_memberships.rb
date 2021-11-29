class CreateEffectiveMemberships < ActiveRecord::Migration[6.0]
  def change

    # Membership Categories
    create_table :membership_categories do |t|
      t.string :title
      t.integer :position

      # Applicants
      t.boolean :can_apply_new, default: false
      t.boolean :can_apply_existing, default: false
      t.boolean :can_apply_restricted, default: false
      t.text :can_apply_restricted_ids

      t.text :applicant_wizard_steps
      t.integer :applicant_fee

      t.text :applicant_review_wizard_steps

      t.integer :min_applicant_educations
      t.integer :min_applicant_experiences_months
      t.integer :min_applicant_references
      t.integer :min_applicant_courses
      t.integer :min_applicant_files

      t.integer :min_applicant_reviews

      t.text :fee_payment_wizard_steps

      t.integer :prorated_jan
      t.integer :prorated_feb
      t.integer :prorated_mar
      t.integer :prorated_apr
      t.integer :prorated_may
      t.integer :prorated_jun
      t.integer :prorated_jul
      t.integer :prorated_aug
      t.integer :prorated_sep
      t.integer :prorated_oct
      t.integer :prorated_nov
      t.integer :prorated_dec

      # Renewals
      t.boolean :create_renewal_fees, default: false
      t.integer :renewal_fee

      t.boolean :create_late_fees, default: false
      t.integer :late_fee

      t.boolean :create_bad_standing, default: false

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :membership_categories, :title
    add_index :membership_categories, :position

    # Memberships
    create_table :memberships do |t|
      t.integer :user_id
      t.string :user_type

      t.integer :category_id
      t.string :category_type

      t.string :number
      t.date :joined_on
      t.date :registration_on
      t.date :fees_paid_through_period

      t.boolean :bad_standing, default: false
      t.boolean :bad_standing_admin, default: false
      t.text :bad_standing_reason

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :memberships, [:category_id, :category_type]
    add_index :memberships, [:user_id, :user_type], unique: true
    add_index :memberships, :number

    # Membership Histories
    create_table :membership_histories do |t|
      t.integer :user_id
      t.string :user_type

      t.integer :membership_category_id
      t.string :membership_category_type

      t.date :start_on
      t.date :end_on

      t.string :number

      t.boolean :bad_standing, default: false
      t.boolean :removed, default: false

      t.text :notes

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :membership_histories, [:user_id, :user_type]
    add_index :membership_histories, :start_on

    # Applicants
    create_table :applicants do |t|
      t.string :token

      t.integer :user_id
      t.string :user_type

      t.integer :membership_category_id
      t.string :membership_category_type

      t.integer :from_membership_category_id
      t.string :from_membership_category_type

      t.string :category

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
      t.text :declined_reason

      # Applicant Educations
      t.text :applicant_educations_details

      # Applicant Experiences
      t.integer :applicant_experiences_months
      t.text :applicant_experiences_details

      # Additional Information
      t.text :additional_information

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :applicants, [:user_id, :user_type]
    add_index :applicants, :status
    add_index :applicants, :token

    # Applicant Educations
    create_table :applicant_educations do |t|
      t.integer :applicant_id

      t.date :start_on
      t.date :end_on

      t.string :institution
      t.string :location

      t.string :degree_obtained

      t.datetime :updated_at
      t.datetime :created_at
    end

    add_index :applicant_educations, :applicant_id
    add_index :applicant_educations, :start_on

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

    add_index :applicant_experiences, :applicant_id
    add_index :applicant_experiences, :start_on

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

    add_index :applicant_references, :applicant_id
    add_index :applicant_references, :token

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

    # Applicant Reviews
    create_table :applicant_reviews do |t|
      t.string :token
      t.integer :applicant_id

      t.integer :user_id
      t.string :user_type

      # Acts as Statused
      t.string :status
      t.text :status_steps

      # Acts as Wizard
      t.text :wizard_steps

      # Dates
      t.datetime :submitted_at

      # Recommendation
      t.string :recommendation
      t.text :comments

      # Steps
      t.boolean :conflict_of_interest
      t.boolean :education_accepted
      t.boolean :course_amounts_accepted
      t.boolean :courses_accepted
      t.boolean :experience_accepted
      t.boolean :references_accepted
      t.boolean :files_accepted

      t.timestamps
    end

    # Fees
    create_table :fees do |t|
      t.string :category

      t.integer :purchased_order_id

      t.integer :membership_category_id
      t.string :membership_category_type

      t.integer :user_id
      t.string :user_type

      t.integer :parent_id
      t.string :parent_type

      t.date :period
      t.date :late_on
      t.date :bad_standing_on

      t.string :title
      t.integer :price

      t.string :qb_item_name
      t.boolean :tax_exempt, default: false

      t.datetime :created_at
      t.datetime :updated_at
    end

    add_index :fees, :category
    add_index :fees, :purchased_order_id
    add_index :fees, :membership_category_id

    add_index :fees, [:user_id, :user_type]
    add_index :fees, [:parent_id, :parent_type]

    # Fee Payments
    create_table :fee_payments do |t|
      t.string :token

      t.integer :user_id
      t.string :user_type

      t.integer :membership_category_id
      t.string :membership_category_type

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

    add_index :fee_payments, [:user_id, :user_type]
    add_index :fee_payments, :status
    add_index :fee_payments, :token

  end
end
