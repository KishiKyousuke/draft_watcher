# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlayerDraftYear, type: :model do
  it { is_expected.to belong_to(:player) }
  it { is_expected.to validate_presence_of(:year) }
  it { is_expected.to validate_numericality_of(:year).only_integer.is_greater_than(1900) }

  describe 'uniqueness' do
    subject { build(:player_draft_year, player: create(:player)) }

    it { is_expected.to validate_uniqueness_of(:year).scoped_to(:player_id) }
  end
end
