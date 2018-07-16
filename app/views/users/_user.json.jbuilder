if user
  json.extract! user, :screenname, :wins_total, :losses_total, 
    :wins_when_initiator, :losses_when_initiator,
    :wins_when_recipient, :losses_when_recipient,
    :disputes_brought_total, :disputes_brought_against_total
end