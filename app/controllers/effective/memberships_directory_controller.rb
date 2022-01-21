module Effective
  class MembershipsDirectoryController < ApplicationController
    include Effective::CrudController

    def index
      @page_title = 'Directory'

      EffectiveResources.authorize!(self, :index, Effective::Membership)

      @datatable = EffectiveResources.best('EffectiveMembershipsDirectoryDatatable').new
    end

  end
end
