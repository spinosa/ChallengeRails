class CreateBattles < ActiveRecord::Migration[5.2]
  def change
    create_table :battles do |t|
      t.references :initiator, references: :users, type: :uuid, null: false
      t.references :recipient, references: :users, type: :uuid
      t.text :description
      t.integer :outcome, default: 0
      t.integer :state, default: 0
      t.datetime :disputed_at
      t.references :disputed_by, references: :users, type: :uuid
      t.string :invited_recipient_email
      t.string :invited_recipient_phone_number

      t.timestamps
    end
    
    add_foreign_key :battles, :users, column: :initiator_id, type: :uuid
    add_foreign_key :battles, :users, column: :recipient_id, type: :uuid
    add_foreign_key :battles, :users, column: :disputed_by_id, type: :uuid
    
    add_index :battles, :invited_recipient_phone_number
    add_index :battles, :invited_recipient_email
    
    add_index :battles, :state
    add_index :battles, :outcome
  end
end
