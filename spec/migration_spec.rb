require 'spec_helper'
require 'yaml'
require 'fileutils'

describe 'Migration' do
  after :each do
    FileUtils.rm_rf './db'
  end

  before :each do
    FileUtils.mkdir_p './db'
    @migration   = Migration.new './db/config.yml'
    @test_server = get_test_server
  end

  # Helper Methods
  def create_example_server
    @migration.create_server(
      @test_server['name'],
      @test_server['address'],
      @test_server['database'],
      @test_server['username'],
      @test_server['password']
    )
  end

  it '#get_first_server_name should return the name of the first server' do
    create_example_server
    expect(@migration.get_first_server_name).to eq(@test_server['name'])
  end

  it '#new Should create a new instance of the Migration class' do
    expect(@migration).to be_an_instance_of Migration
  end

  it '#create_server Should add a server to the list' do
    create_example_server
    server = @migration.get_server(@test_server['name'])
    expect(server.address).to eq(@test_server['address'])
    expect(server.database).to eq(@test_server['database'])
    expect(server.username).to eq(@test_server['username'])
    expect(server.password).to eq(@test_server['password'])
  end

  it '#save Should write the settings to a yaml file' do
    create_example_server
    @migration.save
    expect(File.file?('./db/config.yml')).to eq(true)
    file = File.open('./db/config.yml')
    expect(file.read.length).to eq(147)
  end

  it '#load Should load settings from a yaml file' do
    example = {}
    example['example'] = {
      :address => '127.0.0.1',
      :database => 'example_db',
      :username => 'username',
      :password => 'password'
    }
    File.open('./db/config.yml', 'w') { |f| f.write example.to_yaml }
    @migration.load
    server = @migration.get_server('example')
    expect(server[:address]).to eq('127.0.0.1')
    expect(server[:database]).to eq('example_db')
    expect(server[:username]).to eq('username')
    expect(server[:password]).to eq('password')
  end

  it '#create_migration should create up/down sql scripts' do
    create_example_server
    @migration.create_migration @test_server['name'], 'test_migration'
    expect(File.directory?("./db/#{@test_server['name']}")).to eq(true)
    expect(Dir["./db/#{@test_server['name']}/*.sql"].length).to eq(2)
  end
 
  it '#create_migration should force unique names' do
    create_example_server
    @migration.create_migration @test_server['name'], 'test_migration'
    result = capture_stdout { @migration.create_migration @test_server['name'], 'test_migration' }
    expect(result).to include('Error: migration name already in use')
  end
    
  it '#get_latest_migration should return the latest migration' do
    create_example_server
    @migration.create_migration @test_server['name'], 'test_migration'
    sleep 0.1
    @migration.create_migration @test_server['name'], 'test_migration2'
    result = @migration.get_latest_migration @test_server['name']
    expect(result).to include('test_migration2')
  end
 
  it '#get_migration_plan should return all migrations when new db' do
    create_example_server
    @migration.create_migration @test_server['name'], 'test_migration'
    sleep 0.1
    @migration.create_migration @test_server['name'], 'test_migration2'
    result = @migration.get_migration_plan @test_server['name'], nil, '0'
    expect(result.length).to eq(2)
    expect(result[0]).to include('test_migration_up.sql')
    expect(result[1]).to include('test_migration2_up.sql')
  end

  it '#get_migration_plan should return only the difference in migrations when going up' do
    create_example_server
    @migration.create_migration @test_server['name'], 'test_migration'
    sleep 0.1
    @migration.create_migration @test_server['name'], 'test_migration2'
    current_migration = @migration.get_migration_by_name @test_server['name'], 'test_migration'
    result = @migration.get_migration_plan @test_server['name'], nil, current_migration
    expect(result.length).to eq(1)
    expect(result[0]).to include('test_migration2_up.sql')
  end

  it '#get_migration_plan should return the correct migrations when going down' do
    create_example_server
    @migration.create_migration @test_server['name'], 'test_migration'
    sleep 0.1
    @migration.create_migration @test_server['name'], 'test_migration2'
    sleep 0.1
    @migration.create_migration @test_server['name'], 'test_migration3'
    sleep 0.1
    @migration.create_migration @test_server['name'], 'test_migration4'
    target_migration = @migration.get_migration_by_name @test_server['name'], 'test_migration2'
    current_migration = @migration.get_migration_by_name @test_server['name'], 'test_migration4'
    result = @migration.get_migration_plan @test_server['name'], target_migration, current_migration
    expect(result.length).to eq(2)
    expect(result[0]).to include('test_migration4_down.sql')
    expect(result[1]).to include('test_migration3_down.sql')
  end

  it '#apply_migration_plan should run the migrations against the database' do
    create_example_server
    server = SqlServer.new(
      @test_server['name'],
      @test_server['address'],
      @test_server['database'],
      @test_server['username'],
      @test_server['password']
    )
    server.remove_migration

    @migration.create_migration @test_server['name'], 'test_migration'
    sleep 0.1
    @migration.create_migration @test_server['name'], 'test_migration2'
    sleep 0.1
    # Update these migrations to actually do something...
    first_migration = @migration.get_migration_by_name @test_server['name'], 'test_migration'
    first_migration_path = "./db/#{@test_server['name']}/#{first_migration}"

    second_migration = @migration.get_migration_by_name @test_server['name'], 'test_migration2'
    second_migration_path = "./db/#{@test_server['name']}/#{second_migration}"

    tmp_server = @migration.get_server(@test_server['name'])
    sql1 = tmp_server.get_sql('create_test_table')
    sql2 = tmp_server.get_sql('populate_test_table')
    File.open(first_migration_path, 'w') { |f| f.write sql1 }
    File.open(second_migration_path, 'w') { |f| f.write sql2 }

    migration_plan = @migration.get_migration_plan @test_server['name'], nil, '0'
    @migration.apply_migration_plan @test_server['name'], migration_plan, second_migration

    expect(second_migration).to include(@migration.get_migration_status(@test_server['name']))
  end

end
