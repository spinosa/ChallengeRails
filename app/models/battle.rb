# 1) A Battle is brought by the initiator.
# 2) It may be accepted or declined by the recipient.
# 3) If accepted, it moves to pending
# 4) The recipient (only!) then records the outcome and the Battle moves to complete
# 5) The initiator may then dispute the recorded outcome
class Battle < ApplicationRecord
  belongs_to :initiator,   class_name: "User"  
  belongs_to :recipient,   class_name: "User", optional: true
  belongs_to :disputed_by, class_name: "User", optional: true
  
  after_update :update_win_loss_records, if: -> { saved_change_to_outcome? }
  after_update :update_disputes_records, if: -> { saved_change_to_disputed_by_id? }
  
  module BattleState
    OPEN                     = (1 << 0) # Created by initiator
    CANCELLED_BY_INITIATOR   = (1 << 1)
    DECLINED_BY_RECIPIENT    = (1 << 2)
    PENDING                  = (1 << 3) # After recipient accepts, the battle is pending until it's complete
    COMPLETE                 = (1 << 4) # A disputed Battle remains in the pending state
  end
  
  # NB: Outcomes are recorded by the *recipient* using the system of honor
  module Outcome
    TBD             = (1 << 0) # Battle hasn't taken place yet
    INITIATOR_WIN   = (1 << 1) # Recipient Lost
    INITIATOR_LOSS  = (1 << 2) # Recipient Won
    NO_CONTEST      = (1 << 3) # There is no winner or loser
  end
  
  # ----------------- State Machinations -----------------
  
  def cancel(actor)
    if self.state != Battle::BattleState::OPEN
      self.errors[:base] << "You can no longer cancel this battle" and return      
    end
    if actor != self.initiator
      self.errors[:base] << "You cannot cancel this battle" and return
    end
    
    self.state = Battle::BattleState::CANCELLED_BY_INITIATOR
  end
  
  def decline(actor)
    if self.state != Battle::BattleState::OPEN
      self.errors[:base] << "You can no longer decline this battle" and return      
    end
    if actor != self.recipient
      self.errors[:base] << "You cannot decline this battle" and return
    end
    
    self.state = Battle::BattleState::DECLINED_BY_RECIPIENT
  end
  
  def accept(actor)
    if self.state != Battle::BattleState::OPEN
      self.errors[:base] << "You can no longer accept this battle" and return      
    end
    if actor != self.recipient
      self.errors[:base] << "You cannot accept this battle" and return
    end
    
    self.state = Battle::BattleState::PENDING
  end
  
  def set_outcome(outcome, actor)
    if self.state != Battle::BattleState::PENDING
      self.errors[:base] << "You can no longer set an outcome on this battle" and return      
    end
    if actor != self.recipient
      self.errors[:base] << "You cannot set the outcome of this battle" and return
    end
    
    self.state = Battle::BattleState::COMPLETE
    self.outcome = outcome
    # see update_win_loss_records for User model updates
  end
  
  def dispute(actor)
    if self.state != Battle::BattleState::COMPLETE && self.disputed_at != nil
      self.errors[:base] << "You can no longer dispute the outcome of this battle" and return      
    end
    if actor != self.initiator
      self.errors[:base] << "You cannot dispute the outcome this battle" and return
    end
    
    self.disputed_by = actor
    self.disputed_at = Time.now
    # see update_disputes_records for User model updates
  end
  
  
  # ----------------- JSON Helpers -----------------
  def initiator_screenname
    self.initiator.screenname
  end
  
  def recipient_screenname
    self.recipient.try(:screenname)
  end
  
  def disputed_by_screenname
    self.disputed_by.try(:screenname)
  end
  
  private
  
  # ----------------- After Update -----------------
  
    def update_win_loss_records
      if outcome == Battle::Outcome::INITIATOR_WIN
        self.initiator.increment!(:wins_total)
        self.initiator.increment!(:wins_when_initiator)
        self.recipient.increment!(:losses_total)
        self.recipient.increment!(:losses_when_recipient)
        
      elsif outcome == Battle::Outcome::INITIATOR_LOSS
        self.initiator.increment!(:losses_total)
        self.initiator.increment!(:losses_when_initiator)
        self.recipient.increment!(:wins_total)
        self.recipient.increment!(:wins_when_recipient)
      end
    end
    
    def update_disputes_records
      self.initiator.increment!(:disputes_brought_total)
      self.recipient.increment!(:disputes_brought_against_total)
    end
end
