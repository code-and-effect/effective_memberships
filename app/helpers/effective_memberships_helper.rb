module EffectiveMembershipsHelper

  def edit_effective_applicants_wizard?
    params[:controller] == 'effective/applicants' && defined?(resource) && resource.draft?
  end

  def edit_effective_applicant_reviews_wizard?
    params[:controller] == 'effective/applicant_reviews' && defined?(resource) && resource.draft?
  end

  def edit_effective_fee_payments_wizard?
    params[:controller] == 'effective/fee_payments' && defined?(resource) && resource.draft?
  end

end
