require 'active_record'

configurations = {
  'default' => {
    'adapter'  => 'sqlite3',
    'database' => ':memory:'
  }
}
ActiveRecord::Base.configurations = configurations
ActiveRecord::Base.establish_connection :default

##
# Creates a database schema for the test, in memory, builds up models, and
# removes them once finished.
#
# Example:
#
#  ```
#  describe "Book#where", :with_active_record_schema
#  end
#  ```
#
shared_context 'with active_record', :with_active_record do
  before(:all) { active_record_setup }
  after(:all)  { active_record_teardown }

  private

  def active_record_setup
    create_base_class
    create_schema_and_models
  end

  def active_record_teardown
    BaseClass.remove_connection
    remove_ar_model_classes
  end

  def create_base_class
    # Can't use an abstract object here with Object.const_set I guess, since it
    # doesn't work will with the `self.abstract_class = true`.
    load_class "base_class"
  end

  # Calling load should always execute the code in the file and the constant
  # is removed as part of an `after` block.
  def load_class class_underscore
    root = File.dirname __FILE__
    file = "#{class_underscore}.rb"
    load File.expand_path File.join("..", "active_record", file), root
  end

  def create_schema_and_models
    # Define schema
    this = self
    ActiveRecord::Schema.define do
      self.verbose = false

      def self.connection
        BaseClass.connection
      end

      def self.set_pk_sequence!(*); end

      create_table :authors, &this.send(:_author_schema)
      create_table :books, &this.send(:_book_schema)
    end

    _author_model_create
    _book_model_create
  end

  def _author_schema
    proc do |t|
      t.string   :first_name
      t.string   :last_name
      t.datetime :created_on
      t.datetime :updated_on
    end
  end

  def _book_schema
    proc do |t|
      t.string   :name
      t.text     :description
      t.integer  :author_id
      t.datetime :created_on
      t.datetime :updated_on
    end
  end

  def _author_model_create
    Object.const_set :Author, Class.new(BaseClass) do
      def self.connection; BaseClass.connection; end
    end
  end

  def _book_model_create
    Object.const_set :Book, Class.new(BaseClass) do
      def self.connection; BaseClass.connection; end
    end
  end

  def remove_ar_model_classes
    Object.send :remove_const, :BaseClass

    Object.send :remove_const, :Author
    Object.send :remove_const, :Book
  end
end

RSpec.configure do |rspec|
  rspec.include_context 'with active_record',
                        :with_active_record => true
end
