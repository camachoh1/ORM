module DatabaseActionsHelpers
  def format_order_by_statement(data)
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

  def format_where_statement(data)
    result = ''
    if data.length == 1
      result = "WHERE #{data[0]}"
    else
      result = "WHERE #{data.join("\n AND \n")}"
    end
    result
  end

  def format_set_statement(data)
    "SET #{data[0]}"
  end

  def format_columns(data)
    columns = data.map do |column_data|
      col_name = column_data[:col_name]
      col_type = column_data[:type]
      not_null = column_data[:not_null] ? "NOT NULL" : ""
      "\"#{col_name}\" #{col_type} #{not_null}"
    end.join(",\n")

    columns
  end

  def format_key_placeholder_str(col_names, placeholders)
    result = []
    if col_names.size == 1 && placeholders =~ /[\$d+]/
      result.push("#{col_names[0]} = #{placeholders}")
    else 
      col_names.each_with_index do |_, index|
        result.push("#{col_names[index]} = #{placeholders[index]}")
      end
    end
    result
  end

  def format_col_names(data)
    data.map do |column_data|
      "\"#{column_data[:col_name]}\""
    end
  end

  def format_placeholders(data)
    num = 0
    data.map do |column_data|
      if column_data[:value]
        num += 1
      end
      "$#{num}"
    end
  end

  def process_records(records)
    records.map do |rec|
      result = {}
      rec.each_pair do |key, value|
        sym_key = key.to_sym
        result[sym_key] = value
      end
      result
    end
  end
end