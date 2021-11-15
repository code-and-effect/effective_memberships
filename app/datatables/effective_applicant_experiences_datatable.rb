class EffectiveApplicantExperiencesDatatable < Effective::Datatable
  datatable do
    length :all
    order :start_on

    col :start_on

    col :end_on do |applicant_experience|
      if applicant_experience.still_work_here?
        'Still there'
      else
        applicant_experience.end_on&.strftime('%F')
      end
    end

    col :position
    col :employer

    col :still_work_here, visible: false

    col :category do |applicant_experience|
      if applicant_experience.part_time?
        applicant_experience.category + ' ' + applicant_experience.percent_worked_to_s
      else
        applicant_experience.category
      end
    end

    col :percent_worked, as: :percent, visible: false

    col :months
    col :tasks_performed
  end

  collection do
    Effective::ApplicantExperience.deep.where(applicant: applicant)
  end

  def applicant
    @applicant ||= EffectiveMemberships.applicant_class.where(id: attributes[:applicant_id]).first!
  end
end
