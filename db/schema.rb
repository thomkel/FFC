# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140827220035) do

  create_table "demands", force: true do |t|
    t.integer  "league_id"
    t.integer  "max_per_position"
    t.integer  "num_starters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "position"
  end

  create_table "drafts", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "draft_type"
    t.integer  "league_id"
    t.integer  "num_rounds"
  end

  create_table "franchises", force: true do |t|
    t.integer  "league_id"
    t.integer  "team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "leagues", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", force: true do |t|
    t.integer  "draft_id"
    t.integer  "team_id"
    t.integer  "order_position"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "picks", force: true do |t|
    t.integer  "draft_id"
    t.integer  "pick_num"
    t.integer  "team_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "player_id"
    t.integer  "round"
  end

  create_table "players", force: true do |t|
    t.string   "name"
    t.integer  "bye"
    t.string   "image_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "position"
  end

  create_table "plays", force: true do |t|
    t.integer  "player_id"
    t.integer  "position_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "positions", force: true do |t|
    t.string   "position_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "recruits", force: true do |t|
    t.integer  "team_id"
    t.integer  "player_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "last_year_points"
    t.integer  "projected_points"
    t.integer  "league_id"
  end

  create_table "teams", force: true do |t|
    t.string   "name"
    t.string   "image_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "league_id"
  end

end
