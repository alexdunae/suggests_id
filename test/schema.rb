ActiveRecord::Schema.define(:version => 0) do
	create_table :pages, :force => true do |t|
		t.column :parent_id,    :int
    t.column :title,        :string, :null => false, :default => ''
    t.column :url,          :string, :null => false, :default => ''
	end
end