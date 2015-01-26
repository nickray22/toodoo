class CreateTodoList < ActiveRecord::Migration
  def self.up
    create_table :todo_lists do |t|
      t.integer :user_id
      t.string :title
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :todo_lists
  end
end
