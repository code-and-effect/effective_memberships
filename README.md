# Effective Memberships

Membership categories, applications to join and reclassify, annual dues payments.

Works with action_text for content bodies, and active_storage for file uploads.

## Getting Started

This requires Rails 6+ and Twitter Bootstrap 4 and just works with Devise.

Please first install the [effective_datatables](https://github.com/code-and-effect/effective_datatables) gem.

Please download and install the [Twitter Bootstrap4](http://getbootstrap.com)

Add to your Gemfile:

```ruby
gem 'haml-rails' # or try using gem 'hamlit-rails'
gem 'effective_memberships'
```

Run the bundle command to install it:

```console
bundle install
```

Then run the generator:

```ruby
rails generate effective_memberships:install
```

The generator will install an initializer which describes all configuration options and creates a database migration.

If you want to tweak the table names, manually adjust both the configuration file and the migration now.

Then migrate the database:

```ruby
rake db:migrate
```

Please add the following to your User model:

```
effective_memberships_user

Use the following datatables to display to your user their applicants dues:

```haml
%h2 Applications to Join
- datatable = EffectiveMembershipsApplicantssDatatable.new(self)
```

and

```
Add a link to the admin menu:

```haml
- if can? :admin, :effective_memberships
  - if can? :index, Effective::MembershipCategory
    = nav_link_to 'Membership Categories', effective_memberships.admin_membership_categories_path

  - if can? :index, Effective::Applicants
    = nav_link_to 'Applicants', effective_memberships.admin_applicants_path
```

## Configuration

## Authorization

All authorization checks are handled via the effective_resources gem found in the `config/initializers/effective_resources.rb` file.

## Permissions

The permissions you actually want to define are as follows (using CanCan):

```ruby
# Regular signed up user. Guest users not supported.
if user.persisted?
  can :new, Effective::Applicant
end

if user.admin?
  can :admin, :effective_memberships
  can :manage, Effective::MembershipCategory
  can :manage, Effective::Applicant
end
```

## License

MIT License.  Copyright [Code and Effect Inc.](http://www.codeandeffect.com/)

## Testing

Run tests by:

```ruby
rails test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Bonus points for test coverage
6. Create new Pull Request
