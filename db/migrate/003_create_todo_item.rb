class CreateTodoItem < ActiveRecord::Migration
  def self.up
    create_table :todo_items do |t|
      t.integer :item_id
      t.string :name
      t.datetime :due_date
      t.boolean :finished
      t.timestamps null: false
    end
  end

  def self.down
    drop_table :todo_items
  end
end
