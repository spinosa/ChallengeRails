class AddApnDeviceTokenToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :apns_device_token, :string
  end
end
