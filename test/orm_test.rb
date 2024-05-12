require "minitest/autorun"
require "minitest/reporters"
require_relative '../lib/orm'

Minitest::Reporters.use!

class OrmTest < Minitest::Test
  def setup
    @orm = ORM
  end

  def test_orm_exist
    assert(@orm)
  end

  def test_connection
    con = ORM.establish_db_connection(:postgres, "db_test_orm")
    assert(con)
  end

  def test_create_table
  end

  def test_create
  end

  def test_all
  end

  def test_first
  end

  def test_find_by
  end

  def test_where
  end

  def test_update
  end

  def test_delete
  end

  def test_delete_all
  end
end