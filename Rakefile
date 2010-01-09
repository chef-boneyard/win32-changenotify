require 'rake'
require 'rake/testtask'
require 'rbconfig'
include Config

desc 'Install the win32-changenotify package (non-gem)'
task :install do
   sitelibdir = CONFIG['sitelibdir']
   installdir = File.join(sitelibdir, 'win32')
   file = 'lib\win32\changenotify.rb'

   Dir.mkdir(installdir) unless File.exists?(installdir)
   FileUtils.cp(file, installdir, :verbose => true)
end

desc 'Install the win32-changenotify library as a gem'
task :install_gem do
   ruby 'win32-changenotify.gemspec'
   file = Dir["*.gem"].first
   sh "gem install #{file}"
end

desc 'Run the example program'
task :example do
   ruby '-Ilib examples/example_win32_changenotify.rb'end

Rake::TestTask.new do |t|
   t.verbose = true
   t.warning = true
end
