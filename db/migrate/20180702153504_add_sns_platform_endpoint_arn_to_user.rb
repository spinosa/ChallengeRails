class AddSnsPlatformEndpointArnToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :sns_platform_endpoint_arn, :string
  end
end
