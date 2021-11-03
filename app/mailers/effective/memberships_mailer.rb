module Effective
  class MembershipsMailer < EffectiveMemberships.parent_mailer_class
    default from: -> { EffectiveMemberships.mailer_sender }
    layout -> { EffectiveMemberships.mailer_layout || 'effective_memberships_mailer_layout' }

    def action(resource, opts = {})
      @assigns = effective_memberships_email_assigns(resource)
      @assigns.merge!(url: effective_memberships.some_url)

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
