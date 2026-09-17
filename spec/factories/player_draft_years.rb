FactoryBot.define do
  factory :player_draft_year do
    association :player
    sequence(:year) { |n| 2020 + n }
  end
end
