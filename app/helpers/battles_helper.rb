module BattlesHelper
  
  def state_string(b)
    case b.state
    when Battle::BattleState::OPEN 
      return "Open"
    when Battle::BattleState::CANCELLED_BY_INITIATOR 
      return "Rescinded"
    when Battle::BattleState::DECLINED_BY_RECIPIENT 
      return "Declined"
    when Battle::BattleState::PENDING 
      return "Pending"
    when Battle::BattleState::COMPLETE 
      return "Complete!"
    else 
      return "?"
    end
  end
  
  def outcome_string(b)
    case b.outcome
    when Battle::Outcome::TBD 
      return "TBD"
    when Battle::Outcome::INITIATOR_WIN 
      return "Winner: #{b.initiator.screenname}"
    when Battle::Outcome::INITIATOR_LOSS 
      return "Winner: #{b.recipient.screename}"
    when Battle::Outcome::NO_CONTEST 
      return "No Contest"
    else
      return "?"
    end
  end
  
end
