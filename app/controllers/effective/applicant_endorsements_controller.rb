module Effective
  class ApplicantEndorsementsController < ApplicationController
    include Effective::CrudController

    page_title 'Confidential Endorsement Form'

    # The show and update actions are public routes but can only be reached by the token.
    # The endorser must declare and submit the form
    # To move an applicant endorsement from submitted to completed

    submit :notify, 'Resend email notification',
      success: -> { "Sent email notification to #{resource.email}" }

    submit :complete, 'Complete Endorsement'

    def show
      @applicant_endorsement = ApplicantEndorsement.submitted.find(params[:id])
      EffectiveResources.authorize!(self, :show, @applicant_endorsement)

      render 'edit'
    end

    # Must be signed in
    def select2_ajax_endorser
      authenticate_user! if defined?(Devise)
      authorize! :index, User

      collection = Effective::ApplicantEndorsement.endorser_collection(resource)

      # Collection
      collection = User.shallow.sorted.all

      # Search
      if (term = params[:term]).present?
        collection = collection
          .where('first_name ILIKE ?', "%#{term}%")
          .or(collection.where('last_name ILIKE ?', "%#{term}%"))
          .or(collection.where('email ILIKE ?', "%#{term}%"))
      end

      # Paginate
      per_page = 20
      page = (params[:page] || 1).to_i
      last = (collection.reselect(:id).count.to_f / per_page).ceil
      more = page < last

      offset = [(page - 1), 0].max * per_page
      collection = collection.limit(per_page).offset(offset)

      # Results
      results = collection.map { |user| { id: user.to_param, text: user.to_s_verbose } }

      respond_to do |format|
        format.js do
          render json: { results: results, pagination: { more: more } }
        end
      end
    end



    protected

    def permitted_params
      permitted = params.require(:effective_applicant_endorsement).permit!.except(:token, :last_notified_at, :status, :status_steps, :applicant_id, :endorser_id)

      if current_user && current_user.memberships_owners.include?(resource.applicant&.owner)
        permitted.except(:notes, :accept_declaration)
      else
        permitted
      end

    end

  end
end
