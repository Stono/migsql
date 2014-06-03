guard :rspec, cmd: 'rspec -f doc' do
  watch(%r{^spec/(.+)\.rb$})
  watch('bin/migsql') {'spec/migsql_spec.rb'}
  watch(%r{^lib/migsql/(.+)\.rb$})    { |m| "spec/#{m[1]}_spec.rb" }
end

