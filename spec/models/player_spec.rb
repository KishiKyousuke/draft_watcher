# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Player, type: :model do
  it { is_expected.to have_many(:player_draft_years).dependent(:destroy) }

  describe '#draft_years_text' do
    it '登録済みの候補年を新しい順にカンマ区切りで返す' do
      player = create(:player)
      player.player_draft_years.create!(year: 2023)
      player.player_draft_years.create!(year: 2025)

      expect(player.draft_years_text).to eq('2025, 2023')
    end

    it '候補年が未登録の場合は空文字を返す' do
      player = create(:player)

      expect(player.draft_years_text).to eq('')
    end
  end

  describe '#draft_years_text=' do
    it 'カンマ区切りの年から候補年を作成する' do
      player = create(:player)

      player.draft_years_text = '2024, 2025'
      player.save!

      expect(player.reload.player_draft_years.pluck(:year)).to contain_exactly(2024, 2025)
    end

    it '既存の候補年のうち、入力に含まれないものは削除される' do
      player = create(:player)
      player.player_draft_years.create!(year: 2023)
      player.player_draft_years.create!(year: 2024)

      player.draft_years_text = '2024, 2025'
      player.save!

      expect(player.reload.player_draft_years.pluck(:year)).to contain_exactly(2024, 2025)
    end

    it '重複する年は1つにまとめられる' do
      player = create(:player)

      player.draft_years_text = '2024, 2024, 2025'
      player.save!

      expect(player.reload.player_draft_years.pluck(:year)).to contain_exactly(2024, 2025)
    end

    it '空文字を設定すると候補年がすべて削除される' do
      player = create(:player)
      player.player_draft_years.create!(year: 2024)

      player.draft_years_text = ''
      player.save!

      expect(player.reload.player_draft_years).to be_empty
    end

    it '数値以外のトークンが含まれる場合は例外を発生させず、バリデーションエラーになる' do
      player = create(:player)

      expect do
        player.draft_years_text = 'abc'
      end.not_to raise_error

      expect(player.valid?).to be false
      expect(player.errors[:draft_years_text]).to be_present
    end

    it '数値以外のトークンが含まれる場合、saveは例外を発生させずfalseを返す' do
      player = create(:player)
      player.draft_years_text = 'abc'

      expect { player.save }.not_to raise_error
      expect(player.save).to be false
    end

    it '1900年以下の年は無効なトークンとして扱われる' do
      player = create(:player)
      player.draft_years_text = '1900'

      expect(player.valid?).to be false
      expect(player.errors[:draft_years_text]).to be_present
    end

    it '有効なトークンと無効なトークンが混在する場合も例外を発生させない' do
      player = create(:player)

      expect do
        player.draft_years_text = '2024, abc'
      end.not_to raise_error

      expect(player.valid?).to be false
      expect(player.errors[:draft_years_text]).to be_present
    end
  end

  describe '#draft_years_text のキャッシュ挙動（フォーム再表示用）' do
    it 'setterで設定した直後は、DBに保存されていなくてもgetterがその値を返す' do
      player = create(:player)
      player.player_draft_years.create!(year: 2020)

      player.draft_years_text = '2024, 2025'

      expect(player.draft_years_text).to eq('2024, 2025')
    end

    it 'setterを呼んでいない場合はDBの値がそのまま返る' do
      player = create(:player)
      player.player_draft_years.create!(year: 2020)

      expect(player.draft_years_text).to eq('2020')
    end
  end

  describe '#latest_draft_year' do
    it '最も新しい候補年を返す' do
      player = create(:player)
      player.player_draft_years.create!(year: 2023)
      player.player_draft_years.create!(year: 2025)

      expect(player.latest_draft_year).to eq(2025)
    end

    it '候補年が未登録の場合はnilを返す' do
      player = create(:player)

      expect(player.latest_draft_year).to be_nil
    end
  end
end
