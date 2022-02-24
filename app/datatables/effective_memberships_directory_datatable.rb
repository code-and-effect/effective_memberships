# Member Directory Datatable
class EffectiveMembershipsDirectoryDatatable < Effective::Datatable
  datatable do
    length 100

    col(:name) { |membership| membership.owner.to_s }

    col :joined_on
    col :number
    col :categories, search: :string, label: 'Category'
  end

  collection do
    scope = Effective::Membership.deep.good_standing.includes(:owner)

    archived_klasses.each do |klass|
      scope = scope.where.not(owner_id: klass.archived.select('id'), owner_type: klass.name)
    end

    scope
  end

  def archived_klasses
    @archived_klasses ||= begin
      klasses = Effective::Membership.distinct(:owner_type).pluck(:owner_type)
      klasses = klasses.select { |klass| klass.safe_constantize.try(:acts_as_archived?) }
      klasses.map { |klass| klass.constantize }
    end
  end

end
