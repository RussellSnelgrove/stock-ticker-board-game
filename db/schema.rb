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

ActiveRecord::Schema[8.1].define(version: 2026_04_11_042401) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "dice_rolls", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "direction", null: false
    t.bigint "game_id", null: false
    t.bigint "player_id", null: false
    t.bigint "stock_rolled_id", null: false
    t.integer "turn_number", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "turn_number"], name: "index_dice_rolls_on_game_id_and_turn_number"
    t.index ["game_id"], name: "index_dice_rolls_on_game_id"
    t.index ["player_id"], name: "index_dice_rolls_on_player_id"
    t.index ["stock_rolled_id"], name: "index_dice_rolls_on_stock_rolled_id"
  end

  create_table "game_stocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_price", default: 100, null: false
    t.bigint "game_id", null: false
    t.bigint "stock_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "stock_id"], name: "index_game_stocks_on_game_id_and_stock_id", unique: true
    t.index ["game_id"], name: "index_game_stocks_on_game_id"
    t.index ["stock_id"], name: "index_game_stocks_on_stock_id"
  end

  create_table "game_transactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_stock_id", null: false
    t.bigint "player_id", null: false
    t.integer "price_at_time", null: false
    t.integer "quantity", default: 0, null: false
    t.integer "total_amount", null: false
    t.string "transaction_type", null: false
    t.integer "turn_number", null: false
    t.datetime "updated_at", null: false
    t.index ["game_stock_id", "turn_number"], name: "index_game_transactions_on_game_stock_id_and_turn_number"
    t.index ["game_stock_id"], name: "index_game_transactions_on_game_stock_id"
    t.index ["player_id", "turn_number"], name: "index_game_transactions_on_player_id_and_turn_number"
    t.index ["player_id"], name: "index_game_transactions_on_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_turn", default: 0, null: false
    t.integer "duration", null: false
    t.datetime "ends_at"
    t.bigint "host_id", null: false
    t.string "invite_code", null: false
    t.string "name", null: false
    t.integer "remaining_time"
    t.integer "rolls_remaining_this_turn", default: 2, null: false
    t.datetime "starts_at"
    t.string "status", default: "waiting", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_games_on_host_id"
    t.index ["invite_code"], name: "index_games_on_invite_code", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.string "body", limit: 200, null: false
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id", "created_at"], name: "index_messages_on_game_id_and_created_at"
    t.index ["game_id"], name: "index_messages_on_game_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "cash", default: 500000, null: false
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.integer "net_worth"
    t.string "status", default: "active", null: false
    t.integer "turn_position", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id", "turn_position"], name: "index_players_on_game_id_and_turn_position", unique: true
    t.index ["game_id", "user_id"], name: "index_players_on_game_id_and_user_id", unique: true
    t.index ["game_id"], name: "index_players_on_game_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "stocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_stocks_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "dice_rolls", "games"
  add_foreign_key "dice_rolls", "players"
  add_foreign_key "dice_rolls", "stocks", column: "stock_rolled_id"
  add_foreign_key "game_stocks", "games"
  add_foreign_key "game_stocks", "stocks"
  add_foreign_key "game_transactions", "game_stocks"
  add_foreign_key "game_transactions", "players"
  add_foreign_key "games", "users", column: "host_id"
  add_foreign_key "messages", "games"
  add_foreign_key "messages", "users"
  add_foreign_key "players", "games"
  add_foreign_key "players", "users"
end
