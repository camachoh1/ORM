## Simple Active Record ORM

This is a simple Object-Relational Mapper (ORM) built using Ruby. It follows the Active Record design pattern and provides basic functionalities for interacting with a PostgreSQL database.

**Features**

* Connects to a PostgreSQL database
* Creates and manages database tables
* Performs CRUD (Create, Read, Update, Delete) operations on data
* Uses prepared statements to prevent SQL injection vulnerabilities

**Installation**

Install all dependencies:

```
  bundle install
```

**Usage**

1. **Establish Database Connection:**

```ruby
class Person < ORM
end

Person.establish_db_connection(:postgres, "your_database_name")
```

Replace "your_database_name" with the actual name of your database.

2. **Create a Table:**

```ruby
Person.create_table(
  'persons', [
    {col_name: "name", type: 'varchar(50)', not_null: true},
    {col_name: "age", type: "INTEGER", not_null: true}
  ]
);
```

This creates a table named 'persons' with columns 'name' (string) and 'age' (integer).

3. **CRUD Operations**

* **Create:**

```ruby
Person.create("persons", [
  {col_name: "name", value: "John Doe"},
  {col_name: "age", value: 30}
])
```

* **Read:**

```ruby
# Get all persons
all_persons = Person.all("persons")

# Find a person by name
person = Person.find_by("persons", "name", "John Doe")

# Find persons with specific criteria (and sort)
persons = Person.where("persons", [{col_name: "age", value: 25}], {by: "name", order: "asc"})
```

* **Update:**

```ruby
Person.update("persons", [
  {col_name: "name", value: "Jane Doe"},
], [{col_name: "id", value: 1}])
```

* **Delete:**

```ruby
# Delete a person by ID
Person.delete("persons", [{col_name: "id", value: 1}])

# Delete all persons from the table
Person.delete_all("persons")
```
