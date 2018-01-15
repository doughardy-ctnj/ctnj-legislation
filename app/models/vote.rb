class Vote < ApplicationRecord
  belongs_to :bill, counter_cache: true
  belongs_to :user
end
