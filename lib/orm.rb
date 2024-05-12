require_relative './db_actions'
require 'pg'


SUPPORTED_ADAPTERS = {
  postgres: PG,
}

class ORM
  @@table_name = nil
  @@defaultdb = 'postgres'
  @@config = {
    adapter: PG,  # Default adapter
    dbname: @@defaultdb
  }

  # Connection object
  @@db_connection = nil

  def self.db #
    @@table_name = self.to_s.downcase + 's'
    @@db_actions = DatabaseActions.new(@@db_connection,@@table_name) # collaborator object allows interaction with the database action methods.
  end

  def self.establish_db_connection(adapter=@@defaultdb, db_name)
    adapter_class = get_adapter_class(adapter)
    @@config[:adapter] = adapter_class
    @@config[:dbname] = db_name
    self.connect()
  end

  def self.connect
    if @@db_connection.nil?
      adapter_class = @@config[:adapter]
      @@db_connection = adapter_class.connect(dbname: @@defaultdb)

      if !self.db_exists?(@@config[:dbname])
        @@db_connection.exec("CREATE DATABASE \"#{@@config[:dbname]}\";")
  
        puts "Database '#{@@config[:dbname]}' created!"
      end

      @@db_connection = adapter_class.connect(dbname: @@config[:dbname])

      puts "connected to database: '#{@@config[:dbname]}'"
    end
    @@db_connection
  end

  def self.get_adapter_class(adapter_name)
    raise ArgumentError, "Unsupported adapter: #{adapter_name}" unless self.is_supported_adapter?(adapter_name)
    SUPPORTED_ADAPTERS[adapter_name]
  end

  def self.is_supported_adapter?(adapter_name)
    SUPPORTED_ADAPTERS.key?(adapter_name)
  end

  def self.db_exists?(dbname)
    begin
      @@db_connection = PG.connect(dbname: dbname)
    rescue PG::ConnectionBad => error
      return false if error.message
      raise error
    end
    true
  end
end

class Person < ORM
end

con = Person.establish_db_connection(:postgres, "db_test_orm")

Person.db.create_table([
    {col_name: "name", type: 'varchar(50)', not_null: true},
    {col_name: "age", type: "INTEGER", not_null: true}
  ]
);

Person.db.create([
  {col_name: "name", value: "John Doe"},
  {col_name: "age", value: 30}
])
p "#{Person.db.all}"

Person.db.update([
  {col_name: "name", value: "Jane Doe"}
], [{col_name: "id", value: 17}])

p "after update: #{Person.db.all}"

# #Delete a person by ID
Person.db.delete([{col_name: "id", value: 10}])


Person.db.delete_all