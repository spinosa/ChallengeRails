json.extract! battle, :id, :description, :outcome, :state, :disputed_at, :created_at, :updated_at
json.url battle_url(battle, format: :json)

if current_user == battle.initiator
  json.extract! battle, :invited_recipient_email, :invited_recipient_phone_number
end

json.initiator do
  json.partial! partial: 'users/user', locals: {user: battle.initiator}
end

json.recipient do
  json.partial! partial: 'users/user', locals: {user: battle.recipient}
end

json.disputed_by do
  json.partial! partial: 'users/user', locals: {user: battle.disputed_by}
end