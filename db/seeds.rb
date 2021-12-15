puts "Running effective_memberships seeds"

now = Time.zone.now

if Rails.env.test?
  ActionText::RichText.where(record_type: ['Effective::Category']).delete_all
  Effective::Category.delete_all
  Effective::ApplicantCourseArea.delete_all
  Effective::ApplicantCourseName.delete_all
end

member = Effective::Category.create!(
  title: "Full Member",
  can_apply_new: true,
  can_apply_existing: true,
  create_renewal_fees: true,
  create_late_fees: true,
  min_applicant_references: 2,
  min_applicant_reviews: 2,
  applicant_fee: 100_00,
  renewal_fee: 250_00,
  late_fee: 50_00,
  prorated_jan: 120_00, prorated_feb: 110_00, prorated_mar: 100_00, prorated_apr: 90_00, prorated_may: 80_00, prorated_jun: 70_00,
  prorated_jul: 60_00, prorated_aug: 50_00, prorated_sep: 40_00, prorated_oct: 30_00, prorated_nov: 20_00, prorated_dec: 10_00
)

student = Effective::Category.create!(
  title: "Student",
  can_apply_new: true,
  create_renewal_fees: true,
  create_late_fees: true,
  min_applicant_references: 0,
  min_applicant_reviews: 0,
  applicant_fee: 50_00,
  renewal_fee: 125_00,
  late_fee: 25_00,
  prorated_jan: 120_00, prorated_feb: 110_00, prorated_mar: 100_00, prorated_apr: 90_00, prorated_may: 80_00, prorated_jun: 70_00,
  prorated_jul: 60_00, prorated_aug: 50_00, prorated_sep: 40_00, prorated_oct: 30_00, prorated_nov: 20_00, prorated_dec: 10_00
)

retired = Effective::Category.create!(
  title: "Retired",
  can_apply_new: false,
  can_apply_existing: false,
  can_apply_restricted: true,
  can_apply_restricted_ids: [member.id],
  applicant_fee: 0,
  renewal_fee: 0,
  prorated_jan: 120_00, prorated_feb: 110_00, prorated_mar: 100_00, prorated_apr: 90_00, prorated_may: 80_00, prorated_jun: 70_00,
  prorated_jul: 60_00, prorated_aug: 50_00, prorated_sep: 40_00, prorated_oct: 30_00, prorated_nov: 20_00, prorated_dec: 10_00
)

area = Effective::ApplicantCourseArea.create!(title: 'Science')
area.applicant_course_names.create!(title: 'Science 100')
area.applicant_course_names.create!(title: 'Science 200')

area = Effective::ApplicantCourseArea.create!(title: 'Arts')
area.applicant_course_names.create!(title: 'Arts 100')
area.applicant_course_names.create!(title: 'Arts 200')
