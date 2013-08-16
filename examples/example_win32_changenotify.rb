#######################################################################
# example_win32_changenotify.rb
#
# An example script for general futzing and demonstration. You can
# run this program via the 'rake example' task.
#
# Modify as you see fit.
#######################################################################
require 'win32/changenotify'
include Win32

puts "VERSION: " + ChangeNotify::VERSION
sec = 10
dir = "C:\\Users"

puts "This will timeout after #{sec} seconds of inactivity on #{dir}."

flags = ChangeNotify::FILE_NAME | ChangeNotify::DIR_NAME
flags |= ChangeNotify::LAST_WRITE

cn = ChangeNotify.new(dir, true, flags)

# Wait up to 'sec' seconds for something to happen
begin
  cn.wait(sec) do |events|
    events.each { |event|
	    puts "Something changed"
	    puts "File: " + event.file_name
	    puts "Action: " + event.action
    }
  end
rescue
  cn.close
end

puts "ChangeNotify example program done"
