class AddDomainHashToResultSets < ActiveRecord::Migration
  def change
    add_column :result_sets, :domain_hash, :text
  end
end
