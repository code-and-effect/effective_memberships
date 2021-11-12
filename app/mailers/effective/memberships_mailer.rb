module Effective
  class MembershipsMailer < EffectiveMemberships.parent_mailer_class
    include EffectiveEmailTemplatesMailer

    default from: -> { EffectiveMemberships.mailer_sender }
    layout -> { EffectiveMemberships.mailer_layout || 'effective_memberships_mailer_layout' }

    def applicant_reference_notification(resource, opts = {})
      @assigns = effective_memberships_email_assigns(resource)
      mail(to: EffectiveMemberships.mailer_admin, **headers_for(resource, opts))
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
