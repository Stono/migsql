require 'spec_helper'
require 'fileutils'

describe 'MigSql' do

  before :each do
    FileUtils.rm_rf './db'
    @app = MigSql.new(nil)
  end

  it '#handle_argv Should return a helpful message when you specify no parameters' do
    result = capture_stdout { @app.handle_argv([]) }
    expect(result).to include('Usage: ')
  end

  it '#handle_init Should not allow init if current dir is already initted' do
    FileUtils.mkdir_p './db'
    result = capture_stdout { @app.handle_argv(%w(init)) }
    expect(result).to include('Error: the ./db directory already exists')
  end

  it '#handle_init Should init the default template' do
    result = capture_stdout { @app.handle_argv(%w(init)) }
    expect(File.file?('./db/config.yml')).to eq(true)
    expect(result).to include('Default configuration created in ./db/config.yml')
  end

  it '#handle_create_migration Should create a migration with the default server' do
    capture_stdout { @app.handle_argv(['init']) }
    result = capture_stdout { @app.handle_argv(%w(create-migration initial)) }
    expect(result).to include('Up: ') && include('Down: ')
  end

  it '#handle_create_migration Should return an error if no config found' do
    result = capture_stdout { @app.handle_argv(%w(create-migration initial)) }
    expect(result).to include('Error: Please run migsql init first')
  end

  it '#handle_create_migration should return an error if the specified server doesnt exist' do
    capture_stdout { @app.handle_argv(['init']) }
    result = capture_stdout { @app.handle_argv(%w(create-migration initial unknownserver)) }
    expect(result).to include('Error: No server named unknownserver found in your config')
  end

  it '#handle_create_migration Should return an error if\
      multiple servers defined but one not passed' do
    capture_stdout do
      @app.handle_argv(['init'])
      tmp_migration = Migration.new './db/config.yml'
      tmp_migration.load
      tmp_migration.create_server 'example_two', '1', '1', '1', '1'
      tmp_migration.save
      @app = MigSql.new(nil)
    end
    result = capture_stdout { @app.handle_argv(%w(create-migration initial)) }
    expect(result).to include('Error: Your config has multiple servers')
  end

  it '#handle_migrate Should return an error if multiple servers defined but one not passed' do
    capture_stdout do
      @app.handle_argv(['init'])
      tmp_migration = Migration.new './db/config.yml'
      tmp_migration.load
      tmp_migration.create_server 'example_two', '1', '1', '1', '1'
      tmp_migration.save
      @app = MigSql.new(nil)
    end
    result = capture_stdout { @app.handle_argv(['migrate']) }
    expect(result).to include('Error: Your config has multiple servers')
  end

  it '#handle_apply Should allow you to apply a specific migration' do
    mock_migration = instance_double('Migration')
    allow(mock_migration).to receive(:get_migration_by_name).and_return('123456_migration_up.sql')
    allow(mock_migration).to receive(:count_servers).and_return(1)
    allow(mock_migration).to receive(:get_first_server_name).and_return('test-server')
    allow(mock_migration).to receive(:load)
    allow(mock_migration).to receive(:apply_migration) { puts 'Migration \'migration\' applied.' }
    stubbed_app = MigSql.new(mock_migration)
    result = capture_stdout { stubbed_app.handle_argv(%w(apply migration up)) }
    expect(result).to include('Migration \'migration\' applied.')
  end

  it '#handle_apply Should enforce a migration name' do
    @app.handle_argv(%w(init))
    result = capture_stdout { @app.handle_argv(%w(apply)) }
    expect(result).to include('Error: You must specify a value for migration name')
  end

  it '#handle_apply Should enforce up/down' do
    @app.handle_argv(%w(init))
    result = capture_stdout { @app.handle_argv(%w(apply migration)) }
    expect(result).to include('Error: You must specify a value for up/down')
  end

  it '#handle_apply Should throw an error if the migration name doesnt exist' do
    @app.handle_argv(%w(init))
    result = capture_stdout { @app.handle_argv(%w(apply unknownmigration up)) }
    expect(result).to include('Error: No migration found with name: unknownmigration')
  end

end
