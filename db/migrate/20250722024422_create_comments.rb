class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.string :status
      t.string :name
      t.string :email
      t.text :content

      t.timestamps
    end
  end
end
