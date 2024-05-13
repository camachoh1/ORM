require_relative './db_actions'
require 'pg'


SUPPORTED_ADAPTERS = {
  postgres: PG,
}

class ORM
  @@db_connection = nil
  @@table_name = nil
  @@defaultdb = 'postgres'
  @@config = {
    adapter: PG,  # Default adapter
    dbname: @@defaultdb
  }

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
      temp_connection = adapter_class.connect(dbname: @@defaultdb)

      if !self.db_exists?(@@config[:dbname])
        temp_connection.exec("CREATE DATABASE \"#{@@config[:dbname]}\";")
  
        puts "Database '#{@@config[:dbname]}' created!"
      end

      temp_connection.close if temp_connection

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
      temp_connection = PG.connect(dbname: dbname)
      temp_connection.exec("SELECT 1")
    rescue PG::ConnectionBad => error
      return false if error.message
      raise error
    ensure
      temp_connection&.close if temp_connection
    end
    true
  end
end


class Person < ORM
end

# Person.establish_db_connection(:postgres, "db_test_orm")
# Person.db.create_table(
#   [
#     {col_name: "name", type: 'varchar(50)', not_null: true},
#     {col_name: "age", type: "INTEGER", not_null: true}
#   ]
# );



# Person.db.create([
#   {col_name: "name", value: "John Doe"},
#   {col_name: "age", value: 30}
# ])


# p all_persons = Person.db.all

# # Find a person by name
# p person = Person.db.find_by("id", 16)

# persons = Person.db.where([{col_name: "age", value: 30}], {by: "name", order: "asc"})

# p persons

# Person.db.update([
#   {col_name: "name", value: "Jane Doe"},
# ], [{col_name: "id", value: 16}])

# p all_persons = Person.db.all