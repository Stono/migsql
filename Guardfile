guard :rspec, cmd: 'rspec -f doc' do
  watch(%r{^spec/(.+)\.rb$})
  watch('bin/migsql') {'spec/migsql_spec.rb'}
  watch(%r{^lib/migsql/(.+)\.rb$})    { |m| "spec/#{m[1]}_spec.rb" }
end

guard :rubocop do
  watch(%r{.+\.rb$})
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
