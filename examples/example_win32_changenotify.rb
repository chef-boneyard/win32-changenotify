#######################################################################
# example_win32_changenotify.rb
#
# An example script for general futzing and demonstration. You can
# run this program via the 'rake example' task.
#
# Modify as you see fit.
#######################################################################
require 'win32/changenotify'
require 'pp'
include Win32

puts "VERSION: " + ChangeNotify::VERSION

puts "This will run for 20 seconds"

flags = ChangeNotify::FILE_NAME | ChangeNotify::DIR_NAME
flags |= ChangeNotify::LAST_WRITE

cn = ChangeNotify.new("c:\\", true, flags)

# Wait up to 20 seconds for something to happen
begin
   cn.wait(20){ |events|
      events.each { |event|
	     puts "Something changed"
	     puts "File: " + event.file_name
	     puts "Action: " + event.action
      }
   }
rescue
   cn.close
end

puts "ChangeNotify example program done"