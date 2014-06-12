require 'colorize'
class MigSql
  def initialize(migration)
    @migration = migration || Migration.new('./db/config.yml')
    @migration.load
  end

  def handle_argv(argv)
    if argv.length == 0
      puts 'Usage: migsql {init|create-migration|migrate|apply}'.white
    else
      case argv[0]
      when 'init'
        handle_init
      when 'create-migration'
        handle_create_migration argv
      when 'migrate'
        handle_migrate argv
      when 'apply'
        handle_apply argv
      end
    end
  end

  def enforce_arg(value, name)
    if value.nil?
      puts "Error: You must specify a value for #{name}".red
      return true
    end
    false
  end

  def handle_apply(argv)
    return if enforce_arg(argv[1], 'migration name')
    return if enforce_arg(argv[2], 'up/down')
    migration_server = get_migration_server(argv[4])
    migration_name = get_migration_target(migration_server, argv[1])
    return if migration_name.nil?
    migration_name = "#{migration_name}_#{argv[2]}.sql"
    @migration.apply_migration(migration_server, migration_name)\
      unless migration_server.nil? || migration_name.nil?
  end

  def handle_init
    if File.directory?('./db')
      puts 'Error: the ./db directory already exists'.red
    else
      @migration.create_server(
       'example_database',
       '127.0.0.1',
       'dbname',
       'username',
       'password'
      )
      @migration.save
      puts 'Default configuration created in ./db/config.yml'.green
    end
  end

  def handle_create_migration(argv)
    migration_name = argv[1]
    migration_server = get_migration_server(argv[2])
    @migration.create_migration migration_server, migration_name\
      unless migration_server.nil?
  end

  def handle_migrate(argv)
    if argv[1] == 'to'
      migration_server = @migration.get_first_server_name
      migration_target = argv[2]
    else
      migration_server = get_migration_server(argv[1])
      migration_target = argv[3]
    end
    return if migration_server.nil?
    migration_target = get_migration_target(migration_server, migration_target)
    return if migration_target.nil?
    from = @migration.get_migration_status(migration_server)
    plan = calculate_migration_plan(migration_server, migration_target, from)
    @migration.apply_migration_plan(migration_server, plan, migration_target)\
      unless plan.nil?
  end

  def calculate_migration_plan(migration_server, to, from)
    @migration.get_migration_plan(
      migration_server,
      to,
      from
    )
  end

  def get_migration_target(migration_server, migration_target)
    if migration_target.nil?
      migration = @migration.get_latest_migration(migration_server)
    else
      migration = @migration.get_migration_by_name(migration_server, migration_target)
      puts "Error: No migration found with name: #{migration_target}".red if migration.nil?
    end
    migration
  end

  def get_migration_server(server_name)
    if @migration.count_servers == 0
      puts 'Error: Please run migsql init first'.red
      server_name = nil
    elsif @migration.count_servers > 1 && server_name.nil?
      puts 'Error: Your config has multiple servers,
            please specify which server to create the migration on'.red
    elsif !server_name.nil? && @migration.get_server(server_name).nil?
      puts "Error: No server named #{server_name} found in your config".red
      server_name = nil
    elsif @migration.count_servers == 1
      server_name = @migration.get_first_server_name
    end
    server_name
  end
end
