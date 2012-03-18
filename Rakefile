require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rbconfig'
include RbConfig

CLEAN.include("**/*.gem")

namespace :gem do
  desc 'Create the win32-changenotify gem'
  task :create => [:clean] do
    spec = eval(IO.read('win32-changenotify.gemspec'))
    Gem::Builder.new(spec).build
  end

  desc 'Install the win32-changenotify gem'
  task :install => [:create] do
    ruby 'win32-changenotify.gemspec'
    file = Dir["*.gem"].first
    sh "gem install #{file}"
  end
end

desc 'Run the example program'
task :example do
  ruby '-Ilib examples/example_win32_changenotify.rb'
end

Rake::TestTask.new do |t|
  t.verbose = true
  t.warning = true
end

task :default => :test
