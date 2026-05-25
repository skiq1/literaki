module Moves
  class CreateService < ApplicationService
    SERVICES = {
      "pass" => PassService,
      "resign" => ResignService,
      "exchange_tiles" => ExchangeTilesService,
      "place_tiles" => PlaceTilesService
    }.freeze

    def initialize(game:, user:, params:)
      @game = game
      @user = user
      @params = params.with_indifferent_access
    end

    def call
      service_class = SERVICES[params[:move_type]]
      return failure("Unsupported move type") unless service_class

      service_class.new(game: game, user: user, params: params).call
    end

    private

    attr_reader :game, :user, :params
  end
end
