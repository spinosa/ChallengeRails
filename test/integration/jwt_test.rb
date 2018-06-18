require 'test_helper'

class JwtTest < ActionDispatch::IntegrationTest

  test "new user session should return jwt" do
    post user_session_url(:json), params: {user: { email: "user1@test.com", password: "password" }}
    
    assert_response :success
    assert_not_nil response.headers['Authorization']
    assert response.headers['Authorization'].starts_with?("Bearer")
  end
  
  test "create user should return jwt" do
    assert_difference('User.count') do
      post user_registration_url(:json), params: {user: { email: "a_brand_new_user@test.com", password: "password", screenname: "brand_new_SC0i24r" }}
    end
    
    assert_response :success
    assert_not_nil response.headers['Authorization']
    assert response.headers['Authorization'].starts_with?("Bearer")
  end

end