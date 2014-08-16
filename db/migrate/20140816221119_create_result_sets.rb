class CreateResultSets < ActiveRecord::Migration
  def change
    create_table :result_sets do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.text :domains
      t.text :data

      t.timestamps
    end
  end
end
