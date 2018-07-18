class AddBattleTypeToBattle < ActiveRecord::Migration[5.2]
  def change
    add_column :battles, :battle_type, :int, default: Battle::BattleType::CHALLENGE
  end
end
