FactoryBot.define do
  factory :position do
    sequence(:name) { |n| "ポジション#{n}" }
    sequence(:short_name) { |n| "P#{n}" }
  end
end
