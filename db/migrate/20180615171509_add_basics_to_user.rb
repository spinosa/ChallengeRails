class AddBasicsToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :phone, :string
    add_column :users, :phone_confirmed, :boolean, default: false
    add_column :users, :screenname, :string
    
    add_column :users, :wins_total, :int, default: 0
    add_column :users, :losses_total, :int, default: 0
    add_column :users, :wins_when_initiator, :int, default: 0
    add_column :users, :losses_when_initiator, :int, default: 0
    add_column :users, :wins_when_recipient, :int, default: 0
    add_column :users, :losses_when_recipient, :int, default: 0
    
    add_column :users, :disputes_brought_total, :int, default: 0
    add_column :users, :disputes_brought_against_total, :int, default: 0
    
    add_column :users, :is_root, :boolean, default: false
    
    add_index :users, :screenname, unique: true
  end
end
