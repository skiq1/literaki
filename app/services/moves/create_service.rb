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
      clock = Games::ClockService.new(game: game).call
      return clock unless clock.success?

      service_class = SERVICES[move_type]
      return failure("Unsupported move type") unless service_class

      service_class.new(game: game, user: user, params: params.merge(move_type: move_type)).call
    end

    private

    attr_reader :game, :user, :params

    def move_type
      params[:move_type] == "skip" ? "pass" : params[:move_type]
    end
  end
end
