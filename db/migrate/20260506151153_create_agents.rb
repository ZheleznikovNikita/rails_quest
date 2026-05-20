class CreateAgents < ActiveRecord::Migration[8.1]
  def change
    create_table :agents do |t|
      t.string :codename
      t.integer :level
      t.boolean :active

      t.timestamps
    end

    add_index :agents, :codename, unique: true
  end
end
