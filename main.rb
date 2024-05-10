require 'pg'

SUPPORTED_ADAPTERS = {
  postgres: PG,
}

class ORM
  @@defaultdb = 'postgres'
  @@config = {
    adapter: PG,  # Default adapter
    dbname: @@defaultdb
  }

  # Connection object
  @@connection = nil

  def self.establish_db_connection(adapter=@@defaultdb, db_name)
    adapter_class = get_adapter_class(adapter)
    @@config[:adapter] = adapter_class
    @@config[:dbname] = db_name
    self.connect()
  end

  def self.connect
    if @@connection.nil?
      adapter_class = @@config[:adapter]
      @@connection = adapter_class.connect(dbname: @@defaultdb)

      if !self.db_exists?(@@config[:dbname])
        @@connection.exec("CREATE DATABASE #{@@config[:dbname]};")
        puts "Database '#{@@config[:dbname]}' created!"
      end
      @@connection = adapter_class.connect(dbname: @@config[:dbname])
      puts "connected to database: '#{@@config[:dbname]}'"
    end
    @@connection
  end

  def self.create_table(table_name, data)
    raise ArgumentError, "Invalid table name!" unless is_valid_table_name?(table_name)

    columns = self.format_columns(data)

    if !self.table_exist?(table_name)
    sql = <<~SQL
    CREATE TABLE #{table_name} (
      id serial PRIMARY KEY,
      #{columns}
    );
    SQL

    @@connection.exec_params(sql, [])
    p "Table '#{table_name}' Created!"
    else
      p "Table: '#{table_name}' Already Exist!"
    end
  end

  def self.create(table_name, data)
    raise ArgumentError, "Invalid Table Name: #{table_name}" unless self.table_exist?(table_name) && self.is_valid_table_name?(table_name)

    value_placeholders = create_placeholders(data).join(',')
    
    values = data.map do |col_data|
      col_data[:value]
    end

    col_names = get_col_names(data)
    
    sql = <<~SQL
      INSERT INTO \"#{table_name}\" (#{col_names.join(',')})
      VALUES (#{value_placeholders})
    SQL

    @@connection.exec_params(sql, values)

    p "Records added to table: '#{table_name}'!"
  end

  def self.all(table_name)
    raise ArgumentError, "Invalid Table Name: #{table_name}" unless self.table_exist?(table_name) && is_valid_table_name?(table_name)

    sql = <<~SQL
      SELECT * FROM \"#{table_name}\"
    SQL

    records = @@connection.exec_params(sql, [])
    records = records.map do |rec|
      res = {}
      rec.each_pair do |key, value|
        sym_key = key.to_sym
        res[key] = value
      end
      res
    end
    records
  end

  def self.first(table_name, limit=1) # get the first number of records expecified by the limit. They are returned in ascending order. If no limit specified, returns the first element in the collection. 
    raise ArgumentError, "Invalid Table Name: #{table_name}" unless self.table_exist?(table_name) && is_valid_table_name?(table_name)

    sql = <<~SQL
      SELECT * FROM \"#{table_name}\"
      ORDER BY \"#{table_name}\".id ASC
      LIMIT $1
    SQL

    records = @@connection.exec_params(sql, [limit])
    records = records.map do |rec|
      res = {}
      rec.each_pair do |key, value|
        sym_key = key.to_sym
        res[key] = value
      end
      res
    end
    records
  end

  def self.find_by(table_name,col_name, query)
    raise ArgumentError, "Invalid Table Name: #{table_name}" unless self.table_exist?(table_name) && is_valid_table_name?(table_name)

    records = self.all(table_name)
    records = records.select do |rec|
      rec[col_name] == query
    end[0]
    
    if !records
      "Unable to find provided data!"
    else 
      records
    end
  end

  def self.where(table_name, filters, order={})
    raise ArgumentError, "Invalid Table Name: #{table_name}" unless self.table_exist?(table_name) && is_valid_table_name?(table_name)
    

    col_names = get_col_names(filters)
    values = filters.map do |col_data|
      col_data[:value]
    end

    placeholders = create_placeholders(filters)

    key_val_str = format_key_placeholder_str(col_names, placeholders)

    where_str = format_where_statement(key_val_str)
    order_str = format_order_by_statement(order)

    sql = <<~SQL
      SELECT id,#{col_names.join(',')} FROM \"#{table_name}\"
      #{where_str}
      #{order_str};
    SQL

    result = @@connection.exec_params(sql, values)
    result = result.map do |res|
      res
    end
    
    result.size == 0 ? 
      "No results found with the provided data." :
      result
  end

  def self.update(table_name, values_to_update, condition)
    raise ArgumentError, "Invalid Table Name: #{table_name}" unless self.table_exist?(table_name) && is_valid_table_name?(table_name)

    col_names_to_update = get_col_names(values_to_update)
    col_names_condition = get_col_names(condition)

    all_values = [values_to_update, condition].flatten
    values = all_values.map do |col_data|
      col_data[:value]
    end
    all_values_placeholders = create_placeholders(all_values)
    to_update_place_holder, condition_place_holder = all_values_placeholders

    to_update_key_val_str = format_key_placeholder_str(col_names_to_update, to_update_place_holder)
    condition_key_val_str = format_key_placeholder_str(col_names_condition, condition_place_holder)

    set_str = format_set_statement(to_update_key_val_str)
    where_str = format_where_statement(condition_key_val_str)
    sql = <<~SQL
      UPDATE \"#{table_name}\" #{set_str}
      #{where_str};
    SQL

    result = @@connection.exec_params(sql, values)
    p 'Updated!'
  end


  def self.delete(table_name, values_to_delete)
    raise ArgumentError, "Invalid Table Name: #{table_name}" unless self.table_exist?(table_name) && is_valid_table_name?(table_name)

    col_name = get_col_names(values_to_delete)
    value = values_to_delete.map do |col_data|
      col_data[:value]
    end
    value_placeholder = create_placeholders(values_to_delete)
    key_val_str = format_key_placeholder_str(col_name, value_placeholder)
    where_str = format_where_statement(key_val_str)

    sql = <<~SQL
      DELETE FROM \"#{table_name}\" #{where_str}
    SQL

    result = @@connection.exec_params(sql, value)
    p 'Row Deleted!'
  end

  def self.delete_all(table_name)
    raise ArgumentError, "Invalid Table Name: #{table_name}" unless self.table_exist?(table_name) && is_valid_table_name?(table_name)

    sql = <<~SQL
      DELETE FROM \"#{table_name}\"
    SQL

    @@connection.exec_params(sql, [])
    p "All Rows Deleted!"
  end

  def self.get_adapter_class(adapter_name)
    raise ArgumentError, "Unsupported adapter: #{adapter_name}" unless self.is_supported_adapter(adapter_name)
    SUPPORTED_ADAPTERS[adapter_name]
  end

  def self.is_supported_adapter(adapter_name)
    SUPPORTED_ADAPTERS.key?(adapter_name)
  end

  def self.db_exists?(dbname)
    begin
      @@connection = PG.connect(dbname: dbname)
    rescue PG::ConnectionBad => error
      return false if error.message
      raise error
    end
    true
  end

  def self.table_exist?(table_name) 
    begin
      sql = <<~SQL
      SELECT * FROM \"#{table_name}\"
    SQL
    table = @@connection.exec_params(sql, [])
    rescue PG::UndefinedTable => error
      return false if error.message
      raise error
    end
    true
  end

  def self.is_valid_table_name?(table_name)
    table_name =~ /\A[a-zA-Z0-9_]+\z/
  end

  def self.format_order_by_statement(data)
    by = "\"#{data[:by]}\""
    order = ''
    res = ''
    if data[:order] == "desc"
      order = "DESC"
    elsif data[:order] == "asc" 
      order = "ASC"
    else
      return "Invalid Order Criteria"
    end
    
    res = "ORDER BY #{by} #{order}"
  end

  def self.format_where_statement(data)
    result = ''
    if data.length == 1
      result = "WHERE #{data[0]}"
    else
      result = "WHERE #{data.join("\n AND \n")}"
    end
    result
  end

  def self.format_set_statement(data)
    "SET #{data[0]}"
  end

  def self.format_columns(data)
    columns = data.map do |column_data|
      col_name = column_data[:col_name]
      col_type = column_data[:type]
      not_null = column_data[:not_null] ? "NOT NULL" : ""
      "\"#{col_name}\" #{col_type} #{not_null}"
    end.join(",\n")

    columns
  end

  def self.format_key_placeholder_str(col_names, placeholders)
    result = []
    if col_names.size == 1 && placeholders =~ /[\$d+]/
      result.push("#{col_names[0]} = #{placeholders}")
    else 
      col_names.each_with_index do |_, index|
        result.push("#{col_names[index]} = #{placeholders[index]}")
      end
    end
    return result
  end

  def self.create_placeholders(data)
    num = 0
    data.map do |column_data|
      if column_data[:value]
        num += 1
      end
      "$#{num}"
    end
  end

  def self.get_col_names(data)
    data.map do |column_data|
      "\"#{column_data[:col_name]}\""
    end
  end
end