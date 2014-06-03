require 'rake'
require 'fileutils'
require 'yaml'
require 'tiny_tds'
require 'colorize'

class SqlServer
  def initialize(name, address, database, username, password) 
    @name     = name
    @address  = address
    @database = database
    @username = username
    @password = password
  end

  def name 
    return @name
  end
  def address
    return @address
  end
  def database
    return @database
  end
  def username 
    return @username
  end
  def password
    return @password
  end

  def get_sql(name)
    File.read("#{File.dirname(__FILE__)}/../../sql/#{name}.sql")
  end

  def get_client
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
      results = client.execute("SELECT migration FROM _migration")
      result = results.each(:first => true)[0]['migration']
      if result.length == 0 
        return '0'
      else
        return result
      end
    rescue Exception => ex
      return '0'
    end
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
    client.execute(sql)
  end

end
