require 'rake'
require 'rspec'
require_relative '../lib/migsql'

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  original_stderr = $stderr
  original_stdout = $stdout
  config.before(:each) do
    # Redirect stderr and stdout
    $stderr = File.new('/tmp/rspec-err', 'w')
    $stdout = File.new('/tmp/rspec-out', 'w')
  end
  config.after(:each) do 
    $stderr = original_stderr
    $stdout = original_stdout
  end
end

# Please update this to your local test configuration
def get_test_server
 return {
   'name'    => 'test_db',
   'address' => '172.19.108.5',
   'database'=> 'MigrationTest',
   'username'=> 'jenkins',
   'password'=> 'QDfVkyVn8tk6'
  }
end

def capture_stdout
  s = StringIO.new
  $stdout = s
  yield
  s.string
ensure
  $stdout = STDOUT
end
