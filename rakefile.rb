require 'rubygems'
require 'rubygems/package_task'

def get_version_number
  return File.read('rake_version').strip().to_s
end

files = Dir.glob("lib/**/*")
files.push(Dir.glob("bin/*"))
files.push(Dir.glob("sql/*"))

spec = Gem::Specification.new do |s|
  s.name         = 'migsql'
  s.homepage     = %q{https://github.com/Stono/migsql}
  s.version      = get_version_number()
  s.date         = Time.now.strftime("%Y-%m-%d")
  s.summary      = %q{Simple lightweight up/down MSSQL migrations} 
  s.description  = %q{Simple lightweight up/down MSSQL migrations}
  s.authors      = ["Karl Stoney"]
  s.email        = %q{karl@jambr.co.uk}
  s.files        = files
  s.require_path = 'lib'
  s.license      = 'MIT'
  s.executables  = %w(migsql)
  s.add_runtime_dependency 'tiny_tds'
  s.add_runtime_dependency 'colorize'
end
 
desc 'Generate a gemspec file.'
task :gemspec do
  File.open("#{spec.name}.gemspec", 'w') do |f|
    f.write spec.to_ruby
  end
end

desc 'Uninstall all versions of the Gem'
task :uninstall do
  sh "gem uninstall migsql -a"
end

desc 'Install the gem in your local machine, removing all other versions first'
task :install => [:uninstall, :package] do
  sh "gem install --local \"pkg/#{spec.name}-#{spec.version}.gem\""
end

Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = false
end
