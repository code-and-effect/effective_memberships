puts "Running effective_memberships seeds"

now = Time.zone.now

if Rails.env.test?
  ActionText::RichText.where(record_type: ['Effective::MembershipCategory']).delete_all
  Effective::MembershipCategory.delete_all
  Effective::ApplicantCourseArea.delete_all
  Effective::ApplicantCourseName.delete_all
end

category = Effective::MembershipCategory.create!(
  title: "Level A",
  can_apply: true,
  applicant_fee: 100_00,
  annual_fee: 250_00
)

area = Effective::ApplicantCourseArea.create!(title: 'Science')
area.applicant_course_names.create!(title: 'Science 100')
area.applicant_course_names.create!(title: 'Science 200')

area = Effective::ApplicantCourseArea.create!(title: 'Arts')
area.applicant_course_names.create!(title: 'Arts 100')
area.applicant_course_names.create!(title: 'Arts 200')
