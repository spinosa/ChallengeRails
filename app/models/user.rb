class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtBlacklist
         
  has_many :battles_initiated, class_name: "Battle", foreign_key: "initiator_id"
  has_many :battles_received, class_name: "Battle", foreign_key: "recipient_id"
  has_many :battles_disputed, class_name: "Battle", foreign_key: "disputed_by_id"
  
  validates_presence_of :email, :screenname
  
  def can_update_battle?(battle)
    return self.is_root || self == battle.initiator || self == battle.recipient
  end
  
  def as_json(*)
      super.except("is_root")
    end
end
