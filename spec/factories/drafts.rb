FactoryBot.define do
  factory :draft do
    sequence(:year) { |n| 2020 + n }
    starts_with_central { true }
    virtual { false }
  end
end
