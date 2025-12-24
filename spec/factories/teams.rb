FactoryBot.define do
  factory :team do
    sequence(:name) { |n| "野球チーム#{n}" }
    sequence(:short_name) { |n| "チーム#{n}" }
    league { :central }
  end
end
