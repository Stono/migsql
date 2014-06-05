require 'spec_helper'

describe 'SqlServer' do

  before :all do
    @test_server = get_test_server
  end

  before :each do
    @server = SqlServer.new(
      @test_server['name'],
      @test_server['address'],
      @test_server['database'],
      @test_server['username'],
      @test_server['password']
    )
    @server.remove_migration
  end

  it '#new Should create a new instance of the SqlServer class' do
    expect(@server).to be_an_instance_of SqlServer
  end

  it '#get_migration_status Should return 0 for an uninitialized database' do
    expect(@server.get_migration_status).to eq('0')
  end

  it '#set_migration_status Should set the migration status to a specific value' do
    @server.set_migration_status '12345678_migration'
    expect(@server.get_migration_status).to eq('12345678_migration')
  end

end
