require 'rake'
require 'fileutils'
require 'yaml'
require 'colorize'

class SqlServer
  def initialize(name, address, database, username, password)
    @name     = name
    @address  = address
    @database = database
    @username = username
    @password = password
  end

  attr_reader :name, :address, :database, :username, :password

  def get_sql(name)
    File.read("#{File.dirname(__FILE__)}/../../sql/#{name}.sql")
  end

  def username
    ENV['migsql_username'] || @username
  end

  def password
    ENV['migsql_password'] || @password
  end

  def address
    ENV['migsql_address'] || @address
  end

  def get_client
    require 'tiny_tds'
    TinyTds::Client.new(
      :username => username,
      :password => password,
      :host     => address,
      :database => database
    )
  end

  def get_migration_status
    client = get_client
    begin
      results = client.execute('SELECT migration FROM _migration')
      result = results.each(:first => true)[0]['migration']
      result = '0' if result.length == 0
    rescue
      result = '0'
    end
    result
  end

  def set_migration_status(to)
    client = get_client
    sql = [
      get_sql('create_migration_table'),
      "UPDATE _migration SET migration = '#{to}'"
    ].join(' ')
    client.execute(sql).each
  end

  def remove_migration
    client = get_client
    client.execute('DROP TABLE _migration')
  end

  def apply_migration(path)
    client = get_client
    sql    = File.read(path)
    client.execute(sql).each
  end
end
