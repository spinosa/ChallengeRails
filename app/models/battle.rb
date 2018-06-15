# 1) A Battle is brought by the initiator.
# 2) It may be accepted or declined by the recipient.
# 3) If accepted, it moves to pending
# 4) The recipient (only!) then records the outcome and the Battle moves to complete
# 5) The initiator may then dispute the recorded outcome
class Battle < ApplicationRecord
  belongs_to :initiator,   class_name: "User"  
  belongs_to :recipient,   class_name: "User", optional: true
  belongs_to :disputed_by, class_name: "User", optional: true
  
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
  
end
