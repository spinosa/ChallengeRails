json.extract! battle, :id, :initiator_id, :recipient_id, :description, :outcome, :state, :disputed_at, :disputed_by_id, :created_at, :updated_at
if current_user == battle.initiator
  json.extract! battle, :invited_recipient_email, :invited_recipient_phone_number
end
json.url battle_url(battle, format: :json)
