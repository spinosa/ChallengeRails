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
  # remote notifications
  after_create :push_created_remote_notifications
  after_update :push_updated_state_remote_notifications, if: -> { saved_change_to_state? }
  after_update :push_updated_outcome_remote_notifications, if: -> { saved_change_to_outcome? }
  after_update :push_updated_disputed_remote_notifications, if: -> { saved_change_to_disputed_by_id? }
  
  validates_presence_of :description
  validates_length_of :description, minimum: 1
  
  validate :has_or_invited_recipient 
  validate :was_not_given_invalid_recipient_screenname
  
  module BattleState
    OPEN                     = (1 << 0) # Created by initiator
    CANCELLED_BY_INITIATOR   = (1 << 1)
    DECLINED_BY_RECIPIENT    = (1 << 2)
    PENDING                  = (1 << 3) # After recipient accepts, the battle is pending until it's complete
    COMPLETE                 = (1 << 4) # A disputed Battle remains in the pending state
    
    ALL_ACTIVE  = [Battle::BattleState::OPEN, 
                   Battle::BattleState::PENDING]
    ALL_ARCHIVE = [Battle::BattleState::CANCELLED_BY_INITIATOR, 
                   Battle::BattleState::DECLINED_BY_RECIPIENT, 
                   Battle::BattleState::COMPLETE]
  end
  
  # NB: Outcomes are recorded by the *recipient* using the system of honor
  module Outcome
    TBD             = (1 << 0) # Battle hasn't taken place yet
    INITIATOR_WIN   = (1 << 1) # Recipient Lost
    INITIATOR_LOSS  = (1 << 2) # Recipient Won
    NO_CONTEST      = (1 << 3) # There is no winner or loser
  end
  
  def recipient_screenname=(sn)
    return if sn.blank?
    if recipient = User.find_by_screenname(sn.gsub('@', ''))
      self.recipient = recipient
    else
      @invalid_recipient_screename = sn
    end
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
    if outcome > Battle::Outcome::NO_CONTEST
      self.errors[:base] << "You cannot set that outcome" and return
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
  
  # ----------------- Other Helpers -----------------
  def disputed?
    self.disputed_by != nil
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
      
      # ----------------- Remote Notifcations Update -----------------
      
      def push_created_remote_notifications
        self.recipient.pushRemoteNotification("#{self.initiator.screenname} challenges you!", {battle_id: self.id}) if self.recipient
      end
      
      def push_updated_state_remote_notifications
        if state_before_last_save == Battle::BattleState::OPEN && state == Battle::BattleState::PENDING
          self.initiator.pushRemoteNotification("#{self.recipient.screenname} accepts your challenge...", {battle_id: self.id})
        end
      end
      
      def push_updated_outcome_remote_notifications
        if outcome == Battle::Outcome::INITIATOR_WIN
          self.initiator.pushRemoteNotification("#{self.recipient.screenname} concedes.  You win!", {battle_id: self.id})
        elsif outcome == Battle::Outcome::INITIATOR_LOSS
          self.initiator.pushRemoteNotification("#{self.recipient.screenname} claims victory over you.", {battle_id: self.id})
        end
      end
      
      def push_updated_disputed_remote_notifications
        self.recipient.pushRemoteNotification("#{self.initiator.screenname} disputes your claim.", {battle_id: self.id})
      end
    
      # ----------------- Validation -----------------
      
      def has_or_invited_recipient
        if self.recipient == nil and self.invited_recipient_email.blank? and self.invited_recipient_phone_number.blank?
          self.errors[:base] << "Battles need an opponent"
        end
      end
      
      def was_not_given_invalid_recipient_screenname
        unless @invalid_recipient_screename.blank?
          self.errors.add(:recipient_screename, "not found: #{@invalid_recipient_screename}")
        end
      end
end
