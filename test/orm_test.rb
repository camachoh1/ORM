require "minitest/autorun"
require "minitest/reporters"
require_relative '../lib/orm'

Minitest::Reporters.use!

class Person < ORM
end

class OrmTest < Minitest::Test
  def setup
    @person = Person
    @orm = ORM
    @person.establish_db_connection(:postgres, "db_test_orm")
    @db = @person.db.db_connection
    create_persons_table unless @person.db.table_exist?('persons')
  end

  def test_orm_exist
    assert(@orm)
  end

  def test_create_table
    if @person.db.table_exist?('persons')
      skip("Table 'persons' already exists, skipping test.")
    else
      result = @person.db.create_table(
        [
          {col_name: "name", type: 'varchar(50)', not_null: true},
          {col_name: "age", type: "INTEGER", not_null: true}
        ]
      )
      assert(result)
    end
  end

  def test_table_already_exist
    create_persons_table
    table_exists = @person.db.table_exist?('persons')
  
    assert(table_exists)
  end

  def test_create
    message = ''
    persons = [[
      {col_name: "name", value: "John Doe"},
      {col_name: "age", value: 30}
    ]]

    persons.each do |person|
      message = @person.db.create(person)
    end
    assert_equal("Records added to table: 'persons'!", message)
  end

  def test_all
    create_dummy_data

    all_persons = @person.db.all
    assert_equal(3, all_persons.size)
  end

  def test_first
    create_dummy_data

    first = @person.db.first(2)

    assert_equal([
      {:id=>"1", :name=>"John Doe", :age=>"30"},
      {:id=>"2", :name=>"Jane Doe", :age=>"30"}
    ], first)
  end

  def test_find_by
    create_dummy_data

    person = @person.db.find_by("id", "3")

    assert_equal([{:id=>"3", :name=>"Bob Doe", :age=>"40"}], person)
  end

  def test_where
    create_dummy_data

    persons = @person.db.where([{col_name: "age", value: 30}], {by: "id", order: "desc"})

    assert_equal([
      {:id=>"2", :name=>"Jane Doe", :age=>"30"},
      {:id=>"1", :name=>"John Doe", :age=>"30"}
    ], persons)
  end

  def test_update
    create_dummy_data

    @person.db.update([
      {col_name: "name", value: "Rob Doe"},
    ], [{col_name: "id", value: 1}])

    first = @person.db.first(1)
    assert_equal([{:id=>"1", :name=>"Rob Doe", :age=>"30"}], first)
  end

  def test_delete
    create_dummy_data

    @person.db.delete([{col_name: "id", value: 1}])
    all_persons = @person.db.all
    assert_equal(2, all_persons.size)
  end

  def test_delete_all
    create_dummy_data

    @person.db.delete_all
    all_persons = @person.db.all
    assert_equal(0, all_persons.size)
  end

  def teardown
    @person.db.delete_all
  end
  # helpers
  private
  def create_persons_table
    @person.db.create_table(
      [
        {col_name: "name", type: 'varchar(50)', not_null: true},
        {col_name: "age", type: "INTEGER", not_null: true}
      ]
    )
  end

  def create_dummy_data
    sql = <<~SQL
    INSERT INTO persons (id,name, age)
    VALUES (1,'John Doe', 30),
            (2,'Jane Doe', 30),
            (3,'Bob Doe', 40);
    SQL
    @db.exec(sql)
  end 
end