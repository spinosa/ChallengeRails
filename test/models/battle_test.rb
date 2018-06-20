require 'test_helper'

class BattleTest < ActiveSupport::TestCase
  
  test "can add a valid recipient by screenname" do
    initiator = users(:one)
    recipient = users(:two)
    
    @battle = Battle.new({initiator: initiator, recipient_screenname: recipient.screenname, description: "=)"})
    
    assert @battle.valid?
  end
  
  test "errors if recipient screenname does not exist" do
    initiator = users(:one)

    @battle = Battle.new({initiator: initiator, recipient_screenname: "cretainlydoesntexist089245lnjk", description: "=("})
    
    assert !@battle.valid?
  end
  
  # ------------ State Machinations ------------
  
  test "Open battle can be Cancelled" do
    battle = battles(:open_battle)
    
    battle.cancel(battle.initiator)
    
    assert_equal Battle::BattleState::CANCELLED_BY_INITIATOR, battle.state
  end
  
  test "Open battle can be Declined" do
    battle = battles(:open_battle)
    
    battle.decline(battle.recipient)
    
    assert_equal Battle::BattleState::DECLINED_BY_RECIPIENT, battle.state
  end
  
  test "Open battle can be Accepted by recipient" do
    battle = battles(:open_battle)
    
    battle.accept(battle.recipient)
    
    assert_equal Battle::BattleState::PENDING, battle.state
  end
  
  test "Open battle cannot be Accepted by initiator" do
    battle = battles(:open_battle)
    
    battle.accept(battle.initiator)
    
    assert_equal Battle::BattleState::OPEN, battle.state
  end
  
  test "Pending battle can be Completed (and won) by recipieint" do
    battle = battles(:pending_battle)
    
    assert_difference('battle.recipient.wins_when_recipient', 1) do
      assert_difference('battle.recipient.wins_total', 1) do
        assert_difference('battle.initiator.losses_when_initiator', 1) do
          assert_difference('battle.initiator.losses_total', 1) do
            battle.set_outcome(Battle::Outcome::INITIATOR_LOSS, battle.recipient)
            battle.save
          end
        end
      end
    end
    
    assert_equal Battle::Outcome::INITIATOR_LOSS, battle.outcome
    assert_equal Battle::BattleState::COMPLETE, battle.state
  end
  
  test "Pending battle can be Completed (and lost) by recipieint" do
    battle = battles(:pending_battle)
    
    assert_difference('battle.recipient.losses_when_recipient', 1) do
      assert_difference('battle.recipient.losses_total', 1) do
        assert_difference('battle.initiator.wins_when_initiator', 1) do
          assert_difference('battle.initiator.wins_total', 1) do
            battle.set_outcome(Battle::Outcome::INITIATOR_WIN, battle.recipient)
            battle.save
          end
        end
      end
    end
    
    assert_equal Battle::Outcome::INITIATOR_WIN, battle.outcome
    assert_equal Battle::BattleState::COMPLETE, battle.state
  end
  
  test "Pending battle can be Completed (and NC'd) by recipieint" do
    battle = battles(:pending_battle)
    
    assert_difference('battle.recipient.wins_when_recipient', 0) do
      assert_difference('battle.recipient.wins_total', 0) do
        assert_difference('battle.recipient.losses_when_recipient', 0) do
          assert_difference('battle.recipient.losses_total', 0) do
            assert_difference('battle.initiator.losses_when_initiator', 0) do
              assert_difference('battle.initiator.losses_total', 0) do
                assert_difference('battle.initiator.losses_when_initiator', 0) do
                  assert_difference('battle.initiator.losses_total', 0) do
                    battle.set_outcome(Battle::Outcome::NO_CONTEST, battle.recipient)
                    battle.save
                  end
                end
              end
            end
          end
        end
      end
    end
    
    assert_equal Battle::Outcome::NO_CONTEST, battle.outcome
    assert_equal Battle::BattleState::COMPLETE, battle.state
  end
  
  test "Pending battle cannot be Completed by initiator" do
    battle = battles(:pending_battle)
    assert_equal Battle::Outcome::TBD, battle.outcome
    assert_equal Battle::BattleState::PENDING, battle.state
    
    battle.set_outcome(Battle::Outcome::INITIATOR_WIN, battle.initiator)
    
    assert_equal Battle::Outcome::TBD, battle.outcome
    assert_equal Battle::BattleState::PENDING, battle.state
  end
  
  test "Completed battle can be disputed by initiator" do
    battle = battles(:completed_battle)
    original_outcome = battle.outcome
    
    assert_difference('battle.initiator.disputes_brought_total', 1) do
      assert_difference('battle.recipient.disputes_brought_against_total', 1) do
        battle.dispute(battle.initiator)
        battle.save
      end
    end
      
    assert_equal battle.state, Battle::BattleState::COMPLETE
    assert_equal battle.outcome, original_outcome
  end
  
  test "Completed battle cannot be disputed by recipient" do
    battle = battles(:completed_battle)
    original_outcome = battle.outcome
    
    assert_difference('battle.initiator.disputes_brought_total', 0) do
      assert_difference('battle.recipient.disputes_brought_against_total', 0) do
        battle.dispute(battle.recipient)
      end
    end
      
    assert_equal battle.state, Battle::BattleState::COMPLETE
    assert_equal battle.outcome, original_outcome
  end
  
end
