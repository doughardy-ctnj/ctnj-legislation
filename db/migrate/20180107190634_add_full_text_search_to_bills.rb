class AddFullTextSearchToBills < ActiveRecord::Migration[5.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE INDEX billtext_fts ON bills
                         USING gin (( to_tsvector('english', text) ));
        SQL
      end
      dir.down do
        execute <<~SQL
          DROP INDEX IF EXISTS billtext_fts;
        SQL
      end
    end
  end
end
