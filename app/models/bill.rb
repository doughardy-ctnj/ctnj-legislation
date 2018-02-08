class Bill < ApplicationRecord
  include PgSearch
  include ActiveSupport::Inflector
  has_many :votes
  before_save :sluggify

  def to_param
    parameterize(session_number)
  end

  private

  def sluggify
    self.session_number = parameterize(data['session'] + data['bill_id'])
  end

  def self.search_formatted_terms(terms)
    terms.gsub(/\s{1}/, ' & ')
  end

  def self.search_by_text(terms)
    search_query = <<~SQL
      SELECT id FROM bills WHERE to_tsvector('english',text) @@ to_tsquery('#{search_formatted_terms(terms)}');
    SQL
    result = ActiveRecord::Base.connection.exec_query(search_query)
    where(id: result.to_hash.map { |x| x['id'] })
  end
end
