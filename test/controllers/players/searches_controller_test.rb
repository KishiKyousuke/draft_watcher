require 'test_helper'

class Players::SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @draft = Draft.create!(year: 2025)
    @suzuki_2025 = Player.create!(name: '鈴木一郎', name_kana: 'すずきいちろう', category: :high_school,
                                  draft_years_text: '2025')
    @suzuki_2024 = Player.create!(name: '鈴木二郎', name_kana: 'すずきじろう', category: :university,
                                  draft_years_text: '2024')
    @suzuki_both = Player.create!(name: '鈴木三郎', name_kana: 'すずきさぶろう', category: :corporate,
                                  draft_years_text: '2024, 2025')
  end

  test 'draft_idを指定するとそのドラフト年度の候補選手だけを返す' do
    get players_searches_path(format: :json), params: { query: '鈴木', draft_id: @draft.id }

    ids = response.parsed_body.map { |player| player['id'] }
    assert_equal [@suzuki_2025.id, @suzuki_both.id].sort, ids.sort
  end

  test 'draft_idを指定しない場合は全選手から検索する' do
    get players_searches_path(format: :json), params: { query: '鈴木' }

    ids = response.parsed_body.map { |player| player['id'] }
    assert_equal [@suzuki_2025.id, @suzuki_2024.id, @suzuki_both.id].sort, ids.sort
  end
end
