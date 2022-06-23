module Effective
  class MembershipsMailer < EffectiveMemberships.parent_mailer_class

    include EffectiveMailer
    include EffectiveEmailTemplatesMailer if EffectiveMemberships.use_effective_email_templates

    def applicant_completed(resource, opts = {})
      @assigns = assigns_for(resource)
      @applicant = resource

      subject = subject_for(__method__, 'Applicant Completed', resource, opts)
      headers = headers_for(resource, opts)

      mail(to: resource.user.email, subject: subject, **headers)
    end

    def applicant_missing_info(resource, opts = {})
      @assigns = assigns_for(resource)
      @applicant = resource

      subject = subject_for(__method__, 'Applicant Missing Info', resource, opts)
      headers = headers_for(resource, opts)

      mail(to: resource.user.email, subject: subject, **headers)
    end

    def applicant_approved(resource, opts = {})
      @assigns = assigns_for(resource)
      @applicant = resource

      subject = subject_for(__method__, 'Applicant Approved', resource, opts)
      headers = headers_for(resource, opts)

      mail(to: resource.user.email, subject: subject, **headers)
    end

    def applicant_declined(resource, opts = {})
      @assigns = assigns_for(resource)
      @applicant = resource

      subject = subject_for(__method__, 'Applicant Declined', resource, opts)
      headers = headers_for(resource, opts)

      mail(to: resource.user.email, subject: subject, **headers)
    end

    def applicant_endorsement_notification(resource, opts = {})
      @assigns = assigns_for(resource)
      @applicant_endorsement = resource

      subject = subject_for(__method__, 'Endorsement Requested', resource, opts)
      headers = headers_for(resource, opts)

      mail(to: resource.email, subject: subject, **headers)
    end

    def applicant_reference_notification(resource, opts = {})
      @assigns = assigns_for(resource)
      @applicant_reference = resource

      subject = subject_for(__method__, 'Reference Requested', resource, opts)
      headers = headers_for(resource, opts)

      mail(to: resource.email, subject: subject, **headers)
    end

    protected

    def assigns_for(resource)
      if resource.class.respond_to?(:effective_memberships_applicant?)
        return applicant_assigns(resource).merge(owner_assigns(resource.owner))
      end

      if resource.kind_of?(Effective::ApplicantEndorsement)
        return endorsement_assigns(resource).merge(owner_assigns(resource.applicant.owner))
      end

      if resource.kind_of?(Effective::ApplicantReference)
        return reference_assigns(resource).merge(owner_assigns(resource.applicant.owner))
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

        # Optional
        declined_reason: applicant.declined_reason.presence,
        missing_info_reason: applicant.missing_info_reason.presence
      }.compact

      { applicant: values }
    end

    def endorsement_assigns(applicant_endorsement)
      raise('expected a endorsement') unless applicant_endorsement.kind_of?(Effective::ApplicantEndorsement)

      values = {
        name: (applicant_endorsement.endorser&.to_s || applicant_endorsement.name),
        url: effective_memberships.applicant_endorsement_url(applicant_endorsement)
      }

      { endorsement: values }
    end

    def reference_assigns(applicant_reference)
      raise('expected a reference') unless applicant_reference.kind_of?(Effective::ApplicantReference)

      values = {
        name: applicant_reference.name,
        url: effective_memberships.applicant_reference_url(applicant_reference)
      }

      { reference: values }
    end

    def owner_assigns(owner)
      raise('expected a owner') unless owner.class.respond_to?(:effective_memberships_owner?)

      values = {
        name: owner.to_s,
        email: owner.email
      }

      { user: values }
    end

  end
end
