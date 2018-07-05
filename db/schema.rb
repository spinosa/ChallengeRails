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

ActiveRecord::Schema.define(version: 2018_07_05_133635) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "battles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "initiator_id", null: false
    t.uuid "recipient_id"
    t.text "description"
    t.integer "outcome", default: 0
    t.integer "state", default: 0
    t.datetime "disputed_at"
    t.uuid "disputed_by_id"
    t.string "invited_recipient_email"
    t.string "invited_recipient_phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["disputed_by_id"], name: "index_battles_on_disputed_by_id"
    t.index ["initiator_id"], name: "index_battles_on_initiator_id"
    t.index ["invited_recipient_email"], name: "index_battles_on_invited_recipient_email"
    t.index ["invited_recipient_phone_number"], name: "index_battles_on_invited_recipient_phone_number"
    t.index ["outcome"], name: "index_battles_on_outcome"
    t.index ["recipient_id"], name: "index_battles_on_recipient_id"
    t.index ["state"], name: "index_battles_on_state"
  end

  create_table "jwt_blacklist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_blacklist_on_jti"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.boolean "phone_confirmed", default: false
    t.string "screenname", null: false
    t.integer "wins_total", default: 0
    t.integer "losses_total", default: 0
    t.integer "wins_when_initiator", default: 0
    t.integer "losses_when_initiator", default: 0
    t.integer "wins_when_recipient", default: 0
    t.integer "losses_when_recipient", default: 0
    t.integer "disputes_brought_total", default: 0
    t.integer "disputes_brought_against_total", default: 0
    t.boolean "is_root", default: false
    t.string "apns_device_token"
    t.string "sns_platform_endpoint_arn"
    t.string "apns_sandbox_device_token"
    t.string "sns_sandbox_platform_endpoint_arn"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["screenname"], name: "index_users_on_screenname", unique: true
  end

  add_foreign_key "battles", "users", column: "disputed_by_id"
  add_foreign_key "battles", "users", column: "initiator_id"
  add_foreign_key "battles", "users", column: "recipient_id"
end
