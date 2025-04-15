class ChangeRoleToIntegerInUsers < ActiveRecord::Migration[8.0]
  def change
    change_column :users, :role, :integer, using: 'role::integer', default: 0, null: false
  end
end