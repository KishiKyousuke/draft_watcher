FactoryBot.define do
  factory :pick do
    association :draft
    association :player
    association :team
    sequence(:draft_round) { |n| n }
    training_player { false }
    confirmed { true }
    final_pick { false }
  end
end
