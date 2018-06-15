json.extract! battle, :id, :initiator_id, :recipient_id, :description, :outcome, :state, :disputed_at, :disputed_by_id, :invited_recipient_email, :invited_recipient_phone_number, :created_at, :updated_at
json.url battle_url(battle, format: :json)
