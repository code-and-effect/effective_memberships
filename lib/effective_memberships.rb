require 'effective_resources'
require 'effective_datatables'
require 'effective_memberships/engine'
require 'effective_memberships/version'

module EffectiveMemberships

  def self.config_keys
    [
      :membership_categories_table_name,
      :membership_category,
      :layout,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :use_effective_email_templates
    ]
  end

  include EffectiveGem

  def self.mailer_class
    return mailer.constantize if mailer.present?
    Effective::MembershipsMailer
  end

  def self.parent_mailer_class
    return parent_mailer.constantize if parent_mailer.present?

    if use_effective_email_templates
      require 'effective_email_templates'
      Effective::EmailTemplatesMailer
    else
      ActionMailer::Base
    end
  end

  def self.send_email(email, *args)
    raise('expected args to be an Array') unless args.kind_of?(Array)

    if defined?(Tenant)
      tenant = Tenant.current || raise('expected a current tenant')
      args << { tenant: tenant }
    end

    deliver_method = EffectiveMemberships.deliver_method || EffectiveResources.deliver_method

    begin
      EffectiveMemberships.mailer_class.send(email, *args).send(deliver_method)
    rescue => e
      raise if Rails.env.development? || Rails.env.test?
    end
  end

end
