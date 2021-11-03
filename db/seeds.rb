puts "Running effective_memberships seeds"

now = Time.zone.now

if Rails.env.test?
  ActionText::RichText.where(record_type: ['Effective::MembershipCategory']).delete_all
end

category = Effective::MembershipCategory.create!(
  title: "Level A",
  can_apply: true,
  applicant_fee: 100_00,
  annual_fee: 250_00
)
