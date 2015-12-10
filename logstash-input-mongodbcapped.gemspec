Gem::Specification.new do |s|
  s.name = 'logstash-input-mongodbcapped'
  s.version = '0.4.0'
  s.licenses = ['Apache License (2.0)']
  s.summary = "This logstash input plugin streams events from mongodb."
  s.description = "This gem is a logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/plugin install logstash-input-mongodbcapped. This gem is not a stand-alone program"
  s.authors = ["Steven Karas"]
  s.email = 'steven.karas@gmail.com'
  s.homepage = "http://www.github.com/stevenkaras/logstash-input-mongodbcapped"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 2.0.0", "< 3.0.0"
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'stud', '>= 0.0.22'
  s.add_runtime_dependency 'mongo', '= 2.1.2'
  s.add_development_dependency 'logstash-devutils', '>= 0.0.16'
end
