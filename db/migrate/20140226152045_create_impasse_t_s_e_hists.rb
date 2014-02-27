class CreateImpasseTSEHists < ActiveRecord::Migration
  def change
    create_table :impasse_t_s_e_hists do |t|
      t.belongs_to :test_steps
      t.belongs_to :execution_histories
      t.belongs_to :executions
      t.integer :author_id, default: 0, null: false
      t.integer :project_id, default: 0, null: false

      t.timestamps
    end
    add_index :impasse_t_s_e_hists, :test_steps_id
    add_index :impasse_t_s_e_hists, :execution_histories_id
    add_index :impasse_t_s_e_hists, :executions_id
    add_index :impasse_t_s_e_hists, :author_id
    add_index :impasse_t_s_e_hists, :project_id
  end
end
