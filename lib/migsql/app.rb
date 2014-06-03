require 'colorize'
class MigSql

  def initialize
    @migration = Migration.new './db/config.yml'
    @migration.load
  end

  def handle_argv(argv)
    if argv.length == 0
      puts 'Usage: migsql {init|create-migration|migrate}'.white
    else 
      case argv[0]
        when 'init'
          handle_init
        when 'create-migration'
          handle_create_migration argv
        when 'migrate'
          handle_migrate argv
      end  
    end
  end

  def handle_init
    if File.directory?('./db')
      puts 'Error: the ./db directory already exists'.red
    else
      @migration.create_server 'example_database', '127.0.0.1', 'dbname', 'username', 'password'
      @migration.save
      puts 'Default configuration created in ./db/config.yml'.green
    end
  end 

  def handle_create_migration(argv)
    migration_name = argv[1]
    migration_server = get_migration_server(argv[2])
    if !migration_server.nil?
      @migration.create_migration migration_server, migration_name
    end
  end

  def handle_migrate(argv)
    if argv[1] == 'to' 
      migration_server = @migration.get_first_server_name
      migration_target = argv[2]
    else
      migration_server = get_migration_server(argv[1])
      migration_target = argv[3]
    end
    o_target = migration_target
    if !migration_server.nil? 
      if migration_target.nil? 
        migration_target = @migration.get_latest_migration(migration_server)
      else
        migration_target = @migration.get_migration_by_name(migration_server, migration_target)
      end
      if !migration_target.nil? 
        from = @migration.get_migration_status(migration_server)
        plan = @migration.get_migration_plan(migration_server, migration_target, from) 
        if !plan.nil?
          @migration.apply_migration_plan(migration_server, plan, migration_target)
        end
      else
        puts "Error:  No migration found with name: #{o_target}".red
      end
    end
  end

  def get_migration_server(server_name)
    if @migration.count_servers == 0
      puts 'Error: Please run migsql init first'.red
    elsif @migration.count_servers > 1 && server_name.nil?
      puts 'Error: Your config has multiple servers, please specify which server to create the migration on'.red
    elsif !server_name.nil? && @migration.get_server(server_name).nil?
      puts "Error: No server named #{server_name} found in your config".red
      nil
    elsif @migration.count_servers == 1
      @migration.get_first_server_name
    else
      server_name
    end
  end

end
