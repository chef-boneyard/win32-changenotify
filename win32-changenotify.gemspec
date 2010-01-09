require 'rubygems'

spec = Gem::Specification.new do |gem|
   gem.name        = 'win32-changenotify'
   gem.version     = '0.5.1'
   gem.author      = 'Daniel J. Berger'
   gem.license     = 'Artistic 2.0'
   gem.email       = 'djberg96@gmail.com'
   gem.homepage    = 'http://www.rubyforge.org/projects/win32utils'
   gem.platform    = Gem::Platform::RUBY
   gem.summary     = 'A way to monitor files and directories on MS Windows'
   gem.test_file   = 'test/test_win32_changenotify.rb'
   gem.has_rdoc    = true
   gem.files       = Dir['**/*'].reject{ |f| f.include?('CVS') }

   gem.rubyforge_project = 'win32utils'
   gem.extra_rdoc_files  = ['MANIFEST', 'README', 'CHANGES']

   gem.add_dependency('windows-pr', '>= 1.0.6')

   gem.description = <<-EOF
      The win32-changenotify library provides an interface for monitoring
      changes in files or diretories on the MS Windows filesystem. It not only
      tells you when a change occurs, but the nature of the change as well.
   EOF
end

Gem::Builder.new(spec).build
