FactoryBot.define do
  factory :user do
    email 'dev@null.com'
    name 'Developer Null'
    password 'testing123'
    provider 'facebook'
    uid '10100266606926782'
  end
end
