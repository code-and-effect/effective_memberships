module Effective
  class MembershipsMailer < EffectiveMemberships.parent_mailer_class
    include EffectiveEmailTemplatesMailer

    default from: -> { EffectiveMemberships.mailer_sender }
    layout -> { EffectiveMemberships.mailer_layout || 'effective_memberships_mailer_layout' }

    def applicant_approved(resource, opts = {})
      @assigns = assigns_for(resource)
      mail(to: EffectiveMemberships.mailer_admin, **headers_for(resource, opts))
    end

    def applicant_declined(resource, opts = {})
      @assigns = assigns_for(resource)
      mail(to: EffectiveMemberships.mailer_admin, **headers_for(resource, opts))
    end

    def applicant_reference_notification(resource, opts = {})
      @assigns = assigns_for(resource)
      mail(to: resource.email, **headers_for(resource, opts))
    end

    protected

    def headers_for(resource, opts = {})
      resource.respond_to?(:log_changes_datatable) ? opts.merge(log: resource) : opts
    end

    def assigns_for(resource)
      if resource.class.respond_to?(:effective_memberships_applicant?)
        return applicant_assigns(resource).merge(user_assigns(resource.owner))
      end

      if resource.kind_of?(Effective::ApplicantReference)
        return reference_assigns(resource).merge(user_assigns(resource.applicant.owner))
      end

      raise('unexpected resource')
    end

    def applicant_assigns(applicant)
      raise('expected an applicant') unless applicant.class.respond_to?(:effective_memberships_applicant?)

      values = {
        date: (applicant.submitted_at || Time.zone.now).strftime('%F'),

        to_category: applicant.category.to_s,
        from_category: applicant.from_category.to_s,

        url: effective_memberships.applicant_url(applicant),
        admin_url: effective_memberships.edit_admin_applicant_url(applicant),
      }

      if applicant.declined_reason.present?
        values.merge!(declined_reason: applicant.declined_reason)
      end

      { applicant: values }
    end

    def reference_assigns(applicant_reference)
      raise('expected a reference') unless applicant_reference.kind_of?(Effective::ApplicantReference)

      values = {
        name: applicant_reference.name,
        url: effective_memberships.applicant_reference_url(applicant_reference)
      }

      { reference: values }
    end

    def user_assigns(owner)
      raise('expected a owner') unless owner.class.respond_to?(:effective_memberships_owner?)

      values = {
        name: owner.to_s,
        email: owner.email
      }

      { user: values }
    end

  end
end
