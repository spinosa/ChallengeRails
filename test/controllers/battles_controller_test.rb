require 'test_helper'

class BattlesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @battle = battles(:one)
  end

  test "should get index" do
    sign_in users(:one)
    
    get battles_url
    assert_response :success
  end

  test "should get new" do
    sign_in users(:one)
    
    get new_battle_url
    assert_response :success
  end

  test "should create battle" do
    sign_in users(:one)
    
    assert_difference('Battle.count') do
      post battles_url, params: { battle: { description: @battle.description, invited_recipient_email: @battle.invited_recipient_email, invited_recipient_phone_number: @battle.invited_recipient_phone_number } }
    end

    assert_redirected_to battle_url(Battle.order(created_at: :desc).first)
  end

  test "should show battle" do
    sign_in users(:one)
    
    get battle_url(@battle)
    assert_response :success
  end

  test "should get edit" do
    sign_in users(:one)
    
    get edit_battle_url(@battle)
    assert_response :success
  end

  test "should update battle" do
    sign_in users(:one)
    
    patch battle_url(@battle), params: { battle: { description: @battle.description, disputed_at: @battle.disputed_at, disputed_by_id: @battle.disputed_by_id, initiator_id: @battle.initiator_id, invited_recipient_email: @battle.invited_recipient_email, invited_recipient_phone_number: @battle.invited_recipient_phone_number, outcome: @battle.outcome, recipient_id: @battle.recipient_id, state: @battle.state } }
    assert_redirected_to battle_url(@battle)
  end

  test "should destroy battle" do
    sign_in users(:root)
    
    assert_difference('Battle.count', -1) do
      delete battle_url(@battle)
    end

    assert_redirected_to battles_url
  end
  
  # -- Actions --
  
  test "should cancel" do
    sign_in users(:one)
    
    @battle = battles(:open_battle)
    
    post cancel_battle_url(@battle)
    
    assert_equal Battle::BattleState::CANCELLED_BY_INITIATOR, @battle.reload.state
  end
  
  test "should decline" do
    sign_in users(:two)
    
    @battle = battles(:open_battle)
    
    post decline_battle_url(@battle)
    
    assert_equal Battle::BattleState::DECLINED_BY_RECIPIENT, @battle.reload.state
  end
  
  test "should accept" do
    sign_in users(:two)
    
    @battle = battles(:open_battle)
    
    post accept_battle_url(@battle)
    
    assert_equal Battle::BattleState::PENDING, @battle.reload.state
  end
  
  test "should complete with initiator win" do
    sign_in users(:two)
    
    @battle = battles(:pending_battle)
    
    post complete_battle_url(@battle), params: { outcome: Battle::Outcome::INITIATOR_WIN }
    
    assert_equal Battle::BattleState::COMPLETE, @battle.reload.state
    assert_equal Battle::Outcome::INITIATOR_WIN, @battle.reload.outcome
  end
  
  test "should complete with initiator loss" do
    sign_in users(:two)
    
    @battle = battles(:pending_battle)
    
    post complete_battle_url(@battle), params: { outcome: Battle::Outcome::INITIATOR_LOSS }
    
    assert_equal Battle::BattleState::COMPLETE, @battle.reload.state
    assert_equal Battle::Outcome::INITIATOR_LOSS, @battle.reload.outcome
  end
  
  test "should dispute" do
    sign_in users(:one)
    
    @battle = battles(:completed_battle)
    
    post dispute_battle_url(@battle)
    
    assert_equal Battle::BattleState::COMPLETE, @battle.reload.state
    assert_equal users(:one), @battle.reload.disputed_by
  end
  
end
