class Bill < ApplicationRecord
  include PgSearch
  pg_search_scope :search_by_title, against: [:title], using: { tsearch: { any_word: true } }
  has_many :votes
end
