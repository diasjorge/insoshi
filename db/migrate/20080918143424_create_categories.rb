class CreateCategories < ActiveRecord::Migration
  def self.up
    create_table :categories do |t|
      t.string :name, :null => false
      t.string :description

      t.timestamps
    end
    category = Category.create!(:name => "General",
                                :description => "The most general category")

    add_column :events, :category_id, :integer, :null => false, :default => category.id
    
  end

  def self.down
    drop_table :categories
    remove_column :events, :category_id

  end
end
