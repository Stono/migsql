require 'spec_helper'
require 'fileutils'

describe 'MigSql' do

  before :each do
    FileUtils.rm_rf './db'
    @app = MigSql.new
  end

  it '#handle_argv Should return a helpful message when you specify no parameters' do
    result = capture_stdout { @app.handle_argv([]) }
    expect(result).to include('Usage: ')
  end

  it '#handle_init Should not allow init if current dir is already initted' do
    FileUtils.mkdir_p './db'
    result = capture_stdout { @app.handle_argv(['init']) }
    expect(result).to include('Error: the ./db directory already exists')
  end

  it '#handle_init Should init the default template' do
    result = capture_stdout { @app.handle_argv(['init']) }
    expect(File.file?('./db/config.yml')).to eq(true)
    expect(result).to include('Default configuration created in ./db/config.yml')
  end

  it '#handle_create_migration Should create a migration with the default server' do
    capture_stdout { @app.handle_argv(['init']) }
    result = capture_stdout { @app.handle_argv(['create-migration', 'initial']) }
    expect(result).to include('Up: ') && include('Down: ')
  end
 
  it '#handle_create_migration Should return an error if no config found' do
    result = capture_stdout { @app.handle_argv(['create-migration', 'initial']) }
    expect(result).to include('Error: Please run migsql init first')
  end
 
  it '#handle_create_migration should return an error if the specified server doesnt exist' do
    capture_stdout { @app.handle_argv(['init']) }
    result = capture_stdout { @app.handle_argv(['create-migration', 'initial', 'unknownserver']) }
    expect(result).to include('Error: No server named unknownserver found in your config')
  end

  it '#handle_create_migration Should return an error if multiple servers defined but one not passed' do
    capture_stdout do
      @app.handle_argv(['init'])
      tmp_migration = Migration.new './db/config.yml'
      tmp_migration.load
      tmp_migration.create_server 'example_two', '1', '1', '1', '1'
      tmp_migration.save
      @app = MigSql.new
    end
    result = capture_stdout { @app.handle_argv(['create-migration', 'initial']) }
    expect(result).to include('Error: Your config has multiple servers')
  end
  
  it '#handle_migrate Should return an error if multiple servers defined but one not passed' do
    capture_stdout do
      @app.handle_argv(['init'])
      tmp_migration = Migration.new './db/config.yml'
      tmp_migration.load
      tmp_migration.create_server 'example_two', '1', '1', '1', '1'
      tmp_migration.save
      @app = MigSql.new
    end
    result = capture_stdout { @app.handle_argv(['migrate']) }
    expect(result).to include('Error: Your config has multiple servers')
  end

end
