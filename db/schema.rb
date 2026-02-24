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

ActiveRecord::Schema[8.1].define(version: 2026_02_24_004150) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "dice_rolls", force: :cascade do |t|
    t.integer "amount"
    t.datetime "created_at", null: false
    t.string "direction"
    t.bigint "game_id", null: false
    t.bigint "player_id", null: false
    t.bigint "stock_id", null: false
    t.integer "turn_number"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_dice_rolls_on_game_id"
    t.index ["player_id"], name: "index_dice_rolls_on_player_id"
    t.index ["stock_id"], name: "index_dice_rolls_on_stock_id"
  end

  create_table "game_stocks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_price"
    t.bigint "game_id", null: false
    t.bigint "stock_id", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_stocks_on_game_id"
    t.index ["stock_id"], name: "index_game_stocks_on_stock_id"
  end

  create_table "game_transactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_stock_id", null: false
    t.bigint "player_id", null: false
    t.integer "price_at_time", null: false
    t.integer "quantity", null: false
    t.integer "total_amount", null: false
    t.string "transaction_type", null: false
    t.integer "turn_number", null: false
    t.datetime "updated_at", null: false
    t.index ["game_stock_id"], name: "index_game_transactions_on_game_stock_id"
    t.index ["player_id"], name: "index_game_transactions_on_player_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_turn"
    t.integer "duration"
    t.datetime "ends_at"
    t.bigint "host_id", null: false
    t.string "invite_code"
    t.string "name"
    t.integer "remaining_time"
    t.datetime "starts_at"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_games_on_host_id"
    t.index ["invite_code"], name: "index_games_on_invite_code"
  end

  create_table "holdings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "game_stock_id", null: false
    t.bigint "player_id", null: false
    t.integer "quantity"
    t.datetime "updated_at", null: false
    t.index ["game_stock_id"], name: "index_holdings_on_game_stock_id"
    t.index ["player_id"], name: "index_holdings_on_player_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id"], name: "index_messages_on_game_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "players", force: :cascade do |t|
    t.integer "cash"
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.string "status"
    t.integer "turn_position"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id"], name: "index_players_on_game_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "stocks", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "symbol"
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "dice_rolls", "games"
  add_foreign_key "dice_rolls", "players"
  add_foreign_key "dice_rolls", "stocks"
  add_foreign_key "game_stocks", "games"
  add_foreign_key "game_stocks", "stocks"
  add_foreign_key "game_transactions", "game_stocks"
  add_foreign_key "game_transactions", "players"
  add_foreign_key "games", "users", column: "host_id"
  add_foreign_key "holdings", "game_stocks"
  add_foreign_key "holdings", "players"
  add_foreign_key "messages", "games"
  add_foreign_key "messages", "users"
  add_foreign_key "players", "games"
  add_foreign_key "players", "users"
end
