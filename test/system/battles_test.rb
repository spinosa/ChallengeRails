require "application_system_test_case"

class BattlesTest < ApplicationSystemTestCase
  setup do
    @battle = battles(:one)
  end

  test "visiting the index" do
    visit battles_url
    assert_selector "h1", text: "Battles"
  end

  test "creating a Battle" do
    visit battles_url
    click_on "New Battle"

    fill_in "Description", with: @battle.description
    fill_in "Disputed At", with: @battle.disputed_at
    fill_in "Disputed By", with: @battle.disputed_by_id
    fill_in "Initiator", with: @battle.initiator_id
    fill_in "Invited Recipient Email", with: @battle.invited_recipient_email
    fill_in "Invited Recipient Phone Number", with: @battle.invited_recipient_phone_number
    fill_in "Outcome", with: @battle.outcome
    fill_in "Recipient", with: @battle.recipient_id
    fill_in "State", with: @battle.state
    click_on "Create Battle"

    assert_text "Battle was successfully created"
    click_on "Back"
  end

  test "updating a Battle" do
    visit battles_url
    click_on "Edit", match: :first

    fill_in "Description", with: @battle.description
    fill_in "Disputed At", with: @battle.disputed_at
    fill_in "Disputed By", with: @battle.disputed_by_id
    fill_in "Initiator", with: @battle.initiator_id
    fill_in "Invited Recipient Email", with: @battle.invited_recipient_email
    fill_in "Invited Recipient Phone Number", with: @battle.invited_recipient_phone_number
    fill_in "Outcome", with: @battle.outcome
    fill_in "Recipient", with: @battle.recipient_id
    fill_in "State", with: @battle.state
    click_on "Update Battle"

    assert_text "Battle was successfully updated"
    click_on "Back"
  end

  test "destroying a Battle" do
    visit battles_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Battle was successfully destroyed"
  end
end
