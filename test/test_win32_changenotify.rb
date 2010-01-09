#############################################################################
# test_win32_changenotify.rb
#
# Test suite for the win32-changenotify package. You should run this
# test via the 'rake test' task.
#############################################################################
require 'test/unit'
require 'win32/changenotify'
include Win32

class TC_Win32_ChangeNotify < Test::Unit::TestCase
   def setup
      @filter = ChangeNotify::FILE_NAME | ChangeNotify::DIR_NAME
      @cn = ChangeNotify.new("c:\\", false, @filter)
   end
	
   def test_version
      assert_equal('0.5.1', ChangeNotify::VERSION)
   end
	
   def test_path
      assert_respond_to(@cn, :path)
      assert_equal("c:\\", @cn.path)
   end
   
   def test_recursive
      assert_respond_to(@cn, :recursive?)
      assert_equal(false, @cn.recursive?)
   end
   
   def test_filter
      assert_respond_to(@cn, :filter)
      assert_equal(@filter, @cn.filter)
   end

   # The errors here are expected because of the timeout.
   def test_wait
      assert_respond_to(@cn, :wait)
      assert_raises(ChangeNotify::Error){ @cn.wait(0.001) }
      assert_raises(ChangeNotify::Error){ @cn.wait(0.001){} }
   end
	
   def test_wait_any
      assert_respond_to(@cn, :wait_any)
   end
	
   def test_wait_all
      assert_respond_to(@cn, :wait_all)
   end
   
   def test_expected_errors
      assert_raises(TypeError){
         ChangeNotify.new(1, true, @filter)
      }
      assert_raises(TypeError){
         ChangeNotify.new("C:\\", 'foo', @filter)
      }
      assert_raises(TypeError){
         ChangeNotify.new("C:\\", false, "foo")
      }
      assert_raises(TypeError){
         ChangeNotify.new(1, true, @filter, 'bogus')
      }
   end
	
   def teardown
      @cn = nil
      @filter = nil
   end
end