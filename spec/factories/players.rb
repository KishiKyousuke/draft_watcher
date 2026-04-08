FactoryBot.define do
  factory :player do
    sequence(:name) { |n| "選手#{n}" }
    sequence(:name_kana) { |n| "せんしゅ#{n}" }
    category { :high_school }
    affiliation { "高校名" }
  end
end
