json.extract! battle, :id, :initiator_screenname, :recipient_screenname, :description, :outcome, :state, :disputed_at, :disputed_by_screenname, :created_at, :updated_at
if current_user == battle.initiator
  json.extract! battle, :invited_recipient_email, :invited_recipient_phone_number
end
json.url battle_url(battle, format: :json)
