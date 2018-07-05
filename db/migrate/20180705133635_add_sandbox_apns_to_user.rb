class AddSandboxApnsToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :apns_sandbox_device_token, :string
    add_column :users, :sns_sandbox_platform_endpoint_arn, :string
  end
end
