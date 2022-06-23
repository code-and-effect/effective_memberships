module Admin
  class EffectiveApplicantEndorsementsDatatable < Effective::Datatable

    datatable do
      order :name

      col :applicant

      col :endorser
      col :email
      col :name
      col :phone
      col :unknown_member, visible: false

      col :status do |endorsement|
        if endorsement.submitted?
          'Waiting on response'
        elsif endorsement.completed?
          'Completed'
        end
      end

      col :last_notified_at do |endorsement|
        endorsement.last_notified_at&.strftime('%F') unless endorsement.completed?
      end

      actions_col
    end

    collection do
      Effective::ApplicantEndorsement.deep.all
    end

  end
end
