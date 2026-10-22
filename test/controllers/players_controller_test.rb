require 'test_helper'

class PlayersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @older = Player.create!(name: '古井一郎', name_kana: 'ふるいいちろう', category: :high_school, draft_years_text: '2025')
    @newer = Player.create!(name: '新井二郎', name_kana: 'あらいじろう', category: :high_school, draft_years_text: '2025')
    @multi = Player.create!(name: '複数三郎', name_kana: 'ふくすうさぶろう', category: :high_school,
                            draft_years_text: '2024, 2025')
    @no_year = Player.create!(name: '無年四郎', name_kana: 'むねんしろう', category: :high_school)

    @older.player_draft_years.find_by!(year: 2025).update_columns(created_at: Time.zone.local(2025, 1, 1))
    @newer.player_draft_years.find_by!(year: 2025).update_columns(created_at: Time.zone.local(2025, 3, 1))
    # 最新の候補年（2025）の登録日時を使い、古い候補年（2024）の登録日時は無視する
    @multi.player_draft_years.find_by!(year: 2025).update_columns(created_at: Time.zone.local(2025, 2, 1))
    @multi.player_draft_years.find_by!(year: 2024).update_columns(created_at: Time.zone.local(2025, 12, 1))
  end

  test 'should get index' do
    get players_path

    assert_response :success
  end

  test '最新の候補年の登録日時の昇順で並び替えられる' do
    get players_path, params: { sort: 'created_at_asc' }

    assert_equal [@older, @multi, @newer, @no_year].map(&:name), listed_names
  end

  test '最新の候補年の登録日時の降順で並び替えられる' do
    get players_path, params: { sort: 'created_at_desc' }

    assert_equal [@newer, @multi, @older, @no_year].map(&:name), listed_names
  end

  test '登録日時が同じ場合はIDで並び替える' do
    same_time = Time.zone.local(2025, 1, 1)
    [@older, @newer, @multi].each do |player|
      player.player_draft_years.find_by!(year: 2025).update_columns(created_at: same_time)
    end

    get players_path, params: { sort: 'created_at_asc' }
    assert_equal [@older, @newer, @multi, @no_year].map(&:name), listed_names

    get players_path, params: { sort: 'created_at_desc' }
    assert_equal [@multi, @newer, @older, @no_year].map(&:name), listed_names
  end

  test '候補年の古い順で並び替えられる' do
    get players_path, params: { sort: 'draft_year_asc' }

    # 最新の候補年が同じ選手はその候補年の登録日時の古い順、候補年がない選手は末尾
    assert_equal [@older, @multi, @newer, @no_year].map(&:name), listed_names
  end

  test '候補年の古い順では最新の候補年で比較する' do
    @older.update!(draft_years_text: '2026')

    get players_path, params: { sort: 'draft_year_asc' }

    assert_equal [@multi, @newer, @older, @no_year].map(&:name), listed_names
  end

  test '候補年の古い順で候補年も登録日時も同じ場合はIDで並び替える' do
    same_time = Time.zone.local(2025, 1, 1)
    [@older, @newer, @multi].each do |player|
      player.player_draft_years.find_by!(year: 2025).update_columns(created_at: same_time)
    end

    get players_path, params: { sort: 'draft_year_asc' }

    assert_equal [@older, @newer, @multi, @no_year].map(&:name), listed_names
  end

  private

  def listed_names
    names = [@older, @newer, @multi, @no_year].map(&:name)
    names.sort_by { |name| response.body.index(name) || Float::INFINITY }
  end
end
