require 'rake'
require 'fileutils'
require 'yaml'
require 'tiny_tds'
require 'colorize'
require_relative 'sqlserver'

class Migration
  def initialize(path) 
    @path = path
    @root = File.dirname(@path)
    @servers = Hash.new
  end  

  def create_server(name, address, database, username, password)
     @servers[name] = SqlServer.new name, address, database, username, password
  end

  def get_server(name)
    @servers[name]
  end

  def get_first_server_name
    @servers.keys.first
  end
   
  def save
    FileUtils::mkdir_p @root
    File.open(@path, 'w') { |f| f.write @servers.to_yaml }
  end

  def load
    if File.file?(@path) 
      @servers = YAML.load_file(@path)
    end
  end

  def count_servers 
    @servers.length
  end

  def create_migration(server_name, migration_name)
    if get_migration_by_name(server_name, migration_name).nil?
      migration_name = "#{DateTime.now.strftime('%Q')}_#{migration_name}"
      server_root    = "#{@root}/#{server_name}"
      up 	     = "#{server_root}/#{migration_name}_up.sql"
      down           = "#{server_root}/#{migration_name}_down.sql"
      FileUtils::mkdir_p server_root
      FileUtils::touch up
      FileUtils::touch down 

      puts "Migration '#{migration_name}' created.".green
      puts "Up:   #{up}".white
      puts "Down: #{down}".white
      return true
    else
      puts 'Error: migration name already in use'.red
      return false
    end
  end

  def get_latest_migration(server_name)
    server_root = "#{@root}/#{server_name}"
    latest_mig  = File.basename(Dir["#{server_root}/*_up.sql"].sort.reverse[0])
    /([0-9]+_.*)(_up|_down)\.sql/.match(latest_mig).captures[0]
  end

  def get_migration_plan(server_name, to, from)
    to = to || get_latest_migration(server_name)
    to_i  = /([0-9]+)_?.*/.match(to).captures[0]
  
    from_i = /([0-9]+)_?.*/.match(from).captures[0]

    if to_i > from_i 
      plan = get_up_plan server_name, to_i, from_i
    elsif to_i < from_i
      plan = get_down_plan server_name, to_i, from_i
    else
      puts 'No migration needed, database already at current level'.green
    end
    return plan
  end

  def get_up_plan(server_name, to, from)
    plan = Array.new
    server_root = "#{@root}/#{server_name}"
    Dir["#{server_root}/*_up.sql"].sort.each {|migration| 
      current_item = /([0-9]+)_?.*/.match(migration).captures[0]
      if current_item > from && current_item <= to
        plan.push(migration)
      end
    }
    plan
  end

  def get_down_plan(server_name, to, from)
    plan = Array.new
    server_root = "#{@root}/#{server_name}"
    Dir["#{server_root}/*_down.sql"].sort.reverse.each {|migration| 
      current_item = /([0-9]+)_?.*/.match(migration).captures[0]
      if current_item > to && current_item <= from
        plan.push(migration)
      end
    }
    plan
  end

  def get_migration_by_name(server_name, name)
    server_root = "#{@root}/#{server_name}"  
    migration = Dir["#{server_root}/*#{name}_up.sql"][0]
    if !migration.nil?
      migration = /([0-9]+_.*)(_up|_down)\.sql/.match(migration).captures[0]
    else
      puts "Error:  No migration found with name: #{name}".red
    end
    return migration
  end

  def apply_migration_plan(server_name, migration_plan, final_state)
    puts "Applying migration to: #{server_name}".yellow
    migration_plan.each {|migration| 
      apply_migration server_name, migration
    }
    server = get_server(server_name)
    server.set_migration_status(final_state)
    puts "Migration Complete, current state: #{final_state}".green
  end

  def apply_migration(server_name, migration)
    migration_name, updown = /([0-9]+.*)_(.*)\.sql/.match(migration).captures
    puts " - #{migration_name} #{updown}".white
    server = get_server(server_name)
    server.apply_migration(migration)
  end
 
  def get_migration_status(server_name) 
    get_server(server_name).get_migration_status
  end

end

