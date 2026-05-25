module Words
  class ValidateService < ApplicationService
    def initialize(words:, language: "pl")
      @words = Array(words)
      @language = language
    end

    def call
      return success([]) if words.empty?

      missing = normalized_words - Word.where(value: normalized_words, language: language).pluck(:value)
      missing.empty? ? success(normalized_words) : failure(missing.map { |word| "#{word} is not in dictionary" })
    end

    private

    attr_reader :words, :language

    def normalized_words
      @normalized_words ||= words.map { |word| word.to_s.upcase }
    end
  end
end
