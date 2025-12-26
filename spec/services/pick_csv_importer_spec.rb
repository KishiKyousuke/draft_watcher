# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PickCsvImporter, type: :service do
  describe '#import' do
    let!(:draft) { create(:draft, year: 2024) }
    let!(:team) { create(:team, name: '読売ジャイアンツ') }
    let!(:player1) { create(:player, name: '田中太郎', affiliation: '東京高等学校') }
    let!(:player2) { create(:player, name: '鈴木次郎', affiliation: '大阪高等学校') }

    def csv_file_for(content)
      file = double('file')
      allow(file).to receive(:read).and_return(content.dup)
      file
    end

    context '正しい形式のCSVがある場合' do
      let(:csv_content) do
        <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
        CSV
      end

      let(:csv_file) { csv_file_for(csv_content) }

      it '有効なCSVを読み込んでPickオブジェクトが作成される' do
        importer = PickCsvImporter.new(csv_file)
        result = importer.import

        expect(result).to be true
        expect(importer.imported_count).to eq(1)
        expect(Pick.count).to eq(1)
      end

      it 'CSVの行数分のPickが作成される' do
        csv_with_multiple_rows = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
          2024,鈴木次郎,大阪高等学校,読売ジャイアンツ,2,FALSE,TRUE,FALSE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_with_multiple_rows))
        result = importer.import

        expect(result).to be true
        expect(importer.imported_count).to eq(2)
        expect(Pick.count).to eq(2)
      end

      it 'トランザクション処理で成功時はすべてのPickが保存される' do
        importer = PickCsvImporter.new(csv_file)
        result = importer.import

        expect(result).to be true
        saved_pick = Pick.first
        expect(saved_pick.player.name).to eq('田中太郎')
        expect(saved_pick.team.name).to eq('読売ジャイアンツ')
        expect(saved_pick.draft_round).to eq(1)
      end
    end

    context '球団検索とエラー処理' do
      it '球団が見つからない場合、エラーが返される' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,存在しない球団,1,FALSE,TRUE,FALSE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be false
        expect(importer.errors.first).to include('球団が見つかりません')
        expect(importer.errors.first).to include('2行目')
      end

      it '球団が見つかる場合、正しく関連付けられる' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be true
        saved_pick = Pick.first
        expect(saved_pick.team.name).to eq('読売ジャイアンツ')
      end
    end

    context 'ドラフト自動作成' do
      it '存在しないドラフト年の場合、新規ドラフトが作成される' do
        Draft.delete_all

        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2025,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be true
        expect(Draft.find_by(year: 2025)).not_to be_nil
      end

      it '新規作成時、デフォルト値が設定される' do
        Draft.delete_all

        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2025,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be true
        draft = Draft.find_by(year: 2025)
        expect(draft.starts_with_central).to be true
        expect(draft.virtual).to be false
      end

      it '既存ドラフト年の場合、既存ドラフトが使用される' do
        existing_draft = create(:draft, year: 2026)

        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2026,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,TRUE,FALSE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be true
        saved_pick = Pick.first
        expect(saved_pick.draft.id).to eq(existing_draft.id)
      end
    end

    context 'Boolean値の変換' do
      it '「TRUE」が true に変換される' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,TRUE,TRUE,TRUE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be true
        saved_pick = Pick.first
        expect(saved_pick.training_player).to be true
        expect(saved_pick.confirmed).to be true
        expect(saved_pick.final_pick).to be true
      end

      it '「FALSE」が false に変換される' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,FALSE,FALSE,FALSE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be true
        saved_pick = Pick.first
        expect(saved_pick.training_player).to be false
        expect(saved_pick.confirmed).to be false
        expect(saved_pick.final_pick).to be false
      end

      it '大文字小文字を区別しない' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,true,false,True
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be true
        saved_pick = Pick.first
        expect(saved_pick.training_player).to be true
        expect(saved_pick.confirmed).to be false
        expect(saved_pick.final_pick).to be true
      end

      it '空文字は false に変換される' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,,,
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be true
        saved_pick = Pick.first
        expect(saved_pick.training_player).to be false
        expect(saved_pick.confirmed).to be false
        expect(saved_pick.final_pick).to be false
      end

      it '不正なBoolean値でエラーが返される' do
        csv_content = <<~CSV
          ドラフト年,選手名,所属,指名球団,指名順位,育成,確定,最終指名
          2024,田中太郎,東京高等学校,読売ジャイアンツ,1,INVALID,FALSE,FALSE
        CSV

        importer = PickCsvImporter.new(csv_file_for(csv_content))
        result = importer.import

        expect(result).to be false
        expect(importer.errors.first).to include('Boolean値が正しくありません')
      end
    end
  end
end
