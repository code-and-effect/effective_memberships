module Effective
  class ApplicantsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)

    include Effective::WizardController

    resource_scope -> { EffectiveMemberships.Applicant.deep.where(owner: current_user.effective_memberships_owners) }

    submit :resubmit, 'Submit Application'

  end
end
