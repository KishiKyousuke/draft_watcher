FactoryBot.define do
  factory :team_standing do
    association :draft
    association :team
    sequence(:rank) { |n| n }
  end
end
