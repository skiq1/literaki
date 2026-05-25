class Word < ApplicationRecord
  validates :value, presence: true, uniqueness: { scope: :language }
  validates :language, presence: true

  before_validation :normalize_value

  private

  def normalize_value
    self.value = value.to_s.upcase if value.present?
  end
end
