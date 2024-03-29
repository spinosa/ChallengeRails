class User < ApplicationRecord
  include Snsable
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtBlacklist
         
  has_many :battles_initiated, class_name: "Battle", foreign_key: "initiator_id"
  has_many :battles_received, class_name: "Battle", foreign_key: "recipient_id"
  has_many :battles_disputed, class_name: "Battle", foreign_key: "disputed_by_id"
  
  validates :screenname, presence: :true, uniqueness: { case_sensitive: false }
  validates :email, presence: :true, uniqueness: { case_sensitive: false }
  validates_format_of :screenname, with: /\A[a-zA-Z0-9.]+\z/, :message => "may only contain letters and numbers"
  validates_length_of :screenname, in: 4..21
  
  after_update :update_sns_push_arn, if: -> { saved_change_to_apns_device_token? }
  after_update :update_sandbox_sns_push_arn, if: -> { saved_change_to_apns_sandbox_device_token? }
  
  def can_update_battle?(battle)
    return self.is_root || self == battle.initiator || self == battle.recipient
  end
  
  # Update AWS SimpleNotificationService ARN (App Resource Name)
  def update_sns_push_arn
    register_device_token_for_sandbox(false)
  end
  
  def update_sandbox_sns_push_arn
    register_device_token_for_sandbox(true)
  end
  
end
