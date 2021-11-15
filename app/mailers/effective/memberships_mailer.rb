module Effective
  class MembershipsMailer < EffectiveMemberships.parent_mailer_class
    include EffectiveEmailTemplatesMailer

    default from: -> { EffectiveMemberships.mailer_sender }
    layout -> { EffectiveMemberships.mailer_layout || 'effective_memberships_mailer_layout' }

    def applicant_reference_notification(resource, opts = {})
      @assigns = effective_memberships_email_assigns(resource).merge(
        reference_name: resource.name,
        applicant_name: resource.applicant.user.to_s,
        url: effective_memberships.applicant_reference_url(resource.token)
      )

      mail(to: resource.email, **headers_for(resource, opts))
    end

    protected

    def headers_for(resource, opts = {})
      resource.respond_to?(:log_changes_datatable) ? opts.merge(log: resource) : opts
    end

    def effective_memberships_email_assigns(resource)
      {}
    end

  end
end
