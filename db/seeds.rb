puts "Running effective_memberships seeds"

now = Time.zone.now

if Rails.env.test?
  ActionText::RichText.where(record_type: ['Effective::MembershipCategory']).delete_all
  Effective::MembershipCategory.delete_all
  Effective::ApplicantCourseArea.delete_all
  Effective::ApplicantCourseName.delete_all
end

member = Effective::MembershipCategory.create!(
  title: "Full Member",
  can_apply_new: true,
  can_apply_existing: true,
  min_applicant_references: 2,
  min_applicant_reviews: 2,
  applicant_fee: 100_00,
  annual_fee: 250_00,
  prorated_jan: 120, prorated_feb: 110, prorated_mar: 100, prorated_apr: 90, prorated_may: 80, prorated_jun: 70,
  prorated_jul: 60, prorated_aug: 50, prorated_sep: 40, prorated_oct: 30, prorated_nov: 20, prorated_dec: 10
)

student = Effective::MembershipCategory.create!(
  title: "Student",
  can_apply_new: true,
  min_applicant_references: 0,
  min_applicant_reviews: 0,
  applicant_fee: 50_00,
  annual_fee: 125_00,
  prorated_jan: 120, prorated_feb: 110, prorated_mar: 100, prorated_apr: 90, prorated_may: 80, prorated_jun: 70,
  prorated_jul: 60, prorated_aug: 50, prorated_sep: 40, prorated_oct: 30, prorated_nov: 20, prorated_dec: 10
)

retired = Effective::MembershipCategory.create!(
  title: "Retired",
  can_apply_new: false,
  can_apply_existing: false,
  can_apply_restricted: true,
  can_apply_restricted_ids: [member.id],
  applicant_fee: 0,
  annual_fee: 0,
  prorated_jan: 0, prorated_feb: 0, prorated_mar: 0, prorated_apr: 0, prorated_may: 0, prorated_jun: 0,
  prorated_jul: 0, prorated_aug: 0, prorated_sep: 0, prorated_oct: 0, prorated_nov: 0, prorated_dec: 0
)

area = Effective::ApplicantCourseArea.create!(title: 'Science')
area.applicant_course_names.create!(title: 'Science 100')
area.applicant_course_names.create!(title: 'Science 200')

area = Effective::ApplicantCourseArea.create!(title: 'Arts')
area.applicant_course_names.create!(title: 'Arts 100')
area.applicant_course_names.create!(title: 'Arts 200')
