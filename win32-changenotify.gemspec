require 'rubygems'

Gem::Specification.new do |spec|
  spec.name        = 'win32-changenotify'
  spec.version     = '0.6.0'
  spec.author      = 'Daniel J. Berger'
  spec.license     = 'Artistic 2.0'
  spec.email       = 'djberg96@gmail.com'
  spec.homepage    = 'http://github.com/djberg96/win32-changenotify'
  spec.summary     = 'A way to monitor files and directories on MS Windows'
  spec.test_file   = 'test/test_win32_changenotify.rb'
  spec.files       = Dir['**/*'].reject{ |f| f.include?('git') }

  spec.rubyforge_project = 'win32utils'
  spec.extra_rdoc_files  = ['MANIFEST', 'README', 'CHANGES']

  spec.add_dependency('ffi')
  spec.add_dependency('win32-event')

  spec.add_development_dependency('test-unit')
  spec.add_development_dependency('rake')

  spec.description = <<-EOF
    The win32-changenotify library provides an interface for monitoring
    changes in files or diretories on the MS Windows filesystem. It not only
    tells you when a change occurs, but the nature of the change as well.
  EOF
end
