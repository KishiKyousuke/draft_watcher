# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_14_140300) do
  create_table "drafts", force: :cascade do |t|
    t.integer "year", null: false
    t.boolean "starts_with_central", default: true
    t.boolean "virtual", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "picks", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "team_id", null: false
    t.integer "year", null: false
    t.integer "draft_round", null: false
    t.boolean "training_player", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "confirmed", default: true, null: false
    t.boolean "final_pick", default: false, null: false
    t.index ["player_id"], name: "index_picks_on_player_id"
    t.index ["team_id"], name: "index_picks_on_team_id"
  end

  create_table "player_positions", force: :cascade do |t|
    t.integer "player_id", null: false
    t.integer "position_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id"], name: "index_player_positions_on_player_id"
    t.index ["position_id"], name: "index_player_positions_on_position_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "category", null: false
    t.string "name", null: false
    t.string "name_kana", null: false
    t.integer "pitching_batting"
    t.string "affiliation"
    t.integer "height"
    t.integer "weight"
    t.integer "age"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "positions", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "team_standings", force: :cascade do |t|
    t.integer "draft_id", null: false
    t.integer "team_id", null: false
    t.integer "rank", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["draft_id", "team_id"], name: "index_team_standings_on_draft_id_and_team_id", unique: true
    t.index ["draft_id"], name: "index_team_standings_on_draft_id"
    t.index ["team_id"], name: "index_team_standings_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name", null: false
    t.integer "league", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "picks", "players"
  add_foreign_key "picks", "teams"
  add_foreign_key "player_positions", "players"
  add_foreign_key "player_positions", "positions"
  add_foreign_key "team_standings", "drafts"
  add_foreign_key "team_standings", "teams"
end
