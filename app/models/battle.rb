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
  
  module BattleType
    CHALLENGE = 0 # Traditional me vs. you; my victory is your defeat
    DARE = 1      # Outcome only impacts the recipient (ie. the dared party)
  end
  
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
    TBD                 = (1 << 0) # Battle hasn't taken place yet
    # Challenge Type
    INITIATOR_WIN       = (1 << 1) # Recipient Lost
    INITIATOR_LOSS      = (1 << 2) # Recipient Won
    NO_CONTEST          = (1 << 3) # There is no winner or loser
    # Dare Type
    RECIPIENT_DARE_WIN  = (1 << 4) # Recipient completed dare
    RECIPIENT_DARE_LOSS = (1 << 5) # Recdipient failed dare
  end
  
  def recipient_screenname=(sn)
    return if sn.blank?
    if recipient = User.find_by_screenname(sn.gsub('@', ''))
      self.recipient = recipient
    else
      @invalid_recipient_screenname = sn
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
    if outcome > Battle::Outcome::RECIPIENT_DARE_LOSS
      self.errors[:base] << "You cannot set that outcome" and return
    end
    if !outcome_valid_for_type(outcome)
      self.errors[:base] << "You cannot set that type of outcome on this type of battle" and return
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
          
        elsif outcome == Battle::Outcome::RECIPIENT_DARE_WIN
          self.recipient.increment!(:wins_total)
          self.recipient.increment!(:wins_when_recipient)
          
        elsif outcome == Battle::Outcome::RECIPIENT_DARE_LOSS
          self.recipient.increment!(:losses_total)
          self.recipient.increment!(:losses_when_recipient)
          
        end
      end
    
      def update_disputes_records
        self.initiator.increment!(:disputes_brought_total)
        self.recipient.increment!(:disputes_brought_against_total)
      end
      
      # ----------------- Remote Notifcations Update -----------------
      
      def push_created_remote_notifications
        if self.battle_type == Battle::BattleType::CHALLENGE
          self.recipient.pushBattleRemoteNotification(self, 
            {title: "@#{self.initiator.screenname} challenges you!", 
             body: self.description}) if self.recipient
             
        elsif self.battle_type == Battle::BattleType::DARE
          self.recipient.pushBattleRemoteNotification(self,
            {title: "@#{self.initiator.screenname}", 
             subtitle: "\"You won't...\"",
             body: self.description}) if self.recipient
        else
          #assertion failure
        end
      end
      
      def push_updated_state_remote_notifications
        if state_before_last_save == Battle::BattleState::OPEN && state == Battle::BattleState::PENDING
          self.initiator.pushBattleRemoteNotification(self,
            {title: "Challenge accepted",
             subtitle: "@#{self.recipient.screenname}",
             body: self.description})
        end
      end
      
      def push_updated_outcome_remote_notifications
        if outcome == Battle::Outcome::INITIATOR_WIN
          self.initiator.pushBattleRemoteNotification(self,
            {title: "You win!",
             subtitle: "@#{self.recipient.screenname} concedes.",
             body: self.description})
             
        elsif outcome == Battle::Outcome::INITIATOR_LOSS
          self.initiator.pushBattleRemoteNotification(self,
            {title: "@#{self.recipient.screenname} claims victory over you.",
             body: self.description})
          
        elsif outcome == Battle::Outcome::RECIPIENT_DARE_WIN
          self.initiator.pushBattleRemoteNotification(self,
            {title: "@#{self.recipient.screenname} did it.",
             subtitle: "They actually did it!",
             body: self.description})
          
        elsif outcome == Battle::Outcome::RECIPIENT_DARE_LOSS
          self.initiator.pushBattleRemoteNotification(self,
            {title: "@#{self.recipient.screenname} failed.",
             subtitle: "You were right; they won't.",
             body: self.description})
          
        end
      end
      
      def push_updated_disputed_remote_notifications
        self.recipient.pushBattleRemoteNotification(self,
          {title: "@#{self.initiator.screenname} disputes your claim.",
          body: self.description})
        
      end
    
      # ----------------- Validation -----------------
      
      def has_or_invited_recipient
        if self.recipient == nil and self.invited_recipient_email.blank? and self.invited_recipient_phone_number.blank?
          self.errors[:base] << "Battles need an opponent"
        end
      end
      
      def was_not_given_invalid_recipient_screenname
        unless @invalid_recipient_screenname.blank?
          self.errors.add(:recipient_screenname, "not found: #{@invalid_recipient_screenname}")
        end
      end
      
      def outcome_valid_for_type(outcome)
        return true if outcome == Battle::Outcome::TBD
        
        if self.battle_type == Battle::BattleType::CHALLENGE
          return [Battle::Outcome::INITIATOR_WIN, Battle::Outcome::INITIATOR_LOSS, Battle::Outcome::NO_CONTEST].include? outcome
          
        elsif self.battle_type == Battle::BattleType::DARE
          return [Battle::Outcome::RECIPIENT_DARE_WIN, Battle::Outcome::RECIPIENT_DARE_LOSS].include? outcome
        else
          #assertion failure
          return false
        end
      end
end
