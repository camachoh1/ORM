require_relative './db_actions_helpers'
class DatabaseActions
  include DatabaseActionsHelpers
  def initialize(db_connection, table_name)
    @db_connection = db_connection
    @table_name = table_name
  end

  def create_table(data)
    

    columns = format_columns(data)

    if !table_exist?(@table_name)
    sql = <<~SQL
    CREATE TABLE \"#{@table_name}\" (
      id serial PRIMARY KEY,
      #{columns}
    );
    SQL

    begin
      result = @db_connection.exec_params(sql, [])
    rescue PG::Error => error
      raise error
    end

    p "Table '#{@table_name}' Created!"
    else
      p "Table: '#{@table_name}' Already Exist!"
    end
  end

  def create(data)
    
    value_placeholders = format_placeholders(data).join(',')
    
    values = data.map do |col_data|
      col_data[:value]
    end

    col_names = format_col_names(data)
    
    sql = <<~SQL
      INSERT INTO \"#{@table_name}\" (#{col_names.join(',')})
      VALUES (#{value_placeholders})
    SQL

    begin
      result = @db_connection.exec_params(sql, values)
    rescue PG::Error => error
      raise error
    end

    p "Records added to table: '#{@table_name}'!"
  end

  def all()
    

    sql = <<~SQL
      SELECT * FROM \"#{@table_name}\"
    SQL

    begin
      records = @db_connection.exec_params(sql, [])
    rescue PG::Error => error
      raise error
    end
    records = process_records(records)
  end

  def first(limit=1)
    

    sql = <<~SQL
      SELECT * FROM \"#{@table_name}\"
      ORDER BY \"#{@table_name}\".id ASC
      LIMIT $1
    SQL

    begin
      records = @db_connection.exec_params(sql, [limit])
    rescue PG::Error => error
      raise error
    end
    records = process_records(records)
  end

  def find_by(col_name, query)
    

    sql = <<~SQL
      SELECT * FROM \"#{@table_name}\"
      WHERE \"#{col_name}\" = $1
      ORDER BY persons.id ASC
      LIMIT 1
    SQL

    begin
      records = @db_connection.exec_params(sql, [query])
    rescue PG::Error => error
      raise error
    end

    records = process_records(records)
    
    if records.size == 0
      "Unable to find provided data!"
    else 
      records
    end
  end

  def where(filters, order={})
    

    col_names = format_col_names(filters)
    values = filters.map do |col_data|
      col_data[:value]
    end

    placeholders = format_placeholders(filters)

    key_val_str = format_key_placeholder_str(col_names, placeholders)

    where_str = format_where_statement(key_val_str)
    order_str = format_order_by_statement(order)

    sql = <<~SQL
      SELECT id,#{col_names.join(',')} FROM \"#{@table_name}\"
      #{where_str}
      #{order_str};
    SQL

    begin
      records = @db_connection.exec_params(sql, values)
    rescue PG::Error => error
      raise error
    end

    records = process_records(records)
    if records.size == 0
      p "No records found with the provided data."
      records
    else
      records
    end
  end

  def update(values_to_update, condition)
    

    all_values = [values_to_update, condition].flatten
    values = all_values.map do |col_data|
      col_data[:value]
    end

    col_names_to_update = format_col_names(values_to_update)
    col_names_condition = format_col_names(condition)

    all_values_placeholders = format_placeholders(all_values)

    to_update_place_holder, condition_place_holder = all_values_placeholders

    to_update_key_val_str = format_key_placeholder_str(col_names_to_update, to_update_place_holder)

    condition_key_val_str = format_key_placeholder_str(col_names_condition, condition_place_holder)

    set_str = format_set_statement(to_update_key_val_str)
    where_str = format_where_statement(condition_key_val_str)
    
    sql = <<~SQL
      UPDATE \"#{@table_name}\" #{set_str}
      #{where_str};
    SQL

    begin
      @db_connection.exec_params(sql, values)
    rescue PG::Error => error
      raise error
    end

    p 'Successfully Updated Records!'
  end

  def delete(values_to_delete)
    

    col_name = format_col_names(values_to_delete)

    value = values_to_delete.map do |col_data|
      col_data[:value]
    end

    value_placeholder = format_placeholders(values_to_delete)
    key_val_str = format_key_placeholder_str(col_name, value_placeholder)

    where_str = format_where_statement(key_val_str)

    sql = <<~SQL
      DELETE FROM \"#{@table_name}\" #{where_str}
    SQL

    begin
      result = @db_connection.exec_params(sql, value)
    rescue PG::Error => error
      raise error
    end

    p 'Row Deleted!'
  end

  def delete_all()
    

    sql = <<~SQL
      DELETE FROM \"#{@table_name}\"
    SQL

    begin
      @db_connection.exec_params(sql, [])
    rescue PG::Error => error
      raise error
    end
    
    p "All Rows Deleted!"
  end

  def table_exist?(table_name) 
    begin
      sql = <<~SQL
      SELECT * FROM \"#{table_name}\"
    SQL
    table = @db_connection.exec_params(sql, [])
    rescue PG::UndefinedTable => error
      return false if error.message
      raise error
    end
    true
  end
end