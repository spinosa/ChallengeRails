class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         
  has_many :battles_initiated, class_name: "Battle", foreign_key: "initiator_id"
  has_many :battles_received, class_name: "Battle", foreign_key: "recipient_id"
  has_many :battles_disputed, class_name: "Battle", foreign_key: "disputed_by_id"
end
