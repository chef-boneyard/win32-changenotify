#############################################################################
# test_win32_changenotify.rb
#
# Test suite for the win32-changenotify package. You should run this
# test via the 'rake test' task.
#############################################################################
require 'test-unit'
require 'win32/changenotify'
include Win32

class TC_Win32_ChangeNotify < Test::Unit::TestCase
  def setup
    @filter = ChangeNotify::FILE_NAME | ChangeNotify::DIR_NAME
    @cn = ChangeNotify.new("c:\\", false, @filter)
  end

  test "version constant is set to expected value" do
    assert_equal('0.6.0', ChangeNotify::VERSION)
  end

  test "path basic functionality" do
    assert_respond_to(@cn, :path)
    assert_nothing_raised{ @cn.path }
    assert_kind_of(String, @cn.path)
  end

  test "path returns expected value" do
    assert_equal("c:\\", @cn.path)
  end

  test "recursive basic functionality" do
    assert_respond_to(@cn, :recursive?)
    assert_nothing_raised{ @cn.recursive? }
    assert_boolean(@cn.recursive?)
  end

  test "recursive returns expected value" do
    assert_equal(false, @cn.recursive?)
  end

  test "filter method basic functionality" do
    assert_respond_to(@cn, :filter)
    assert_nothing_raised{ @cn.filter }
    assert_kind_of(Numeric, @cn.filter)
  end

  test "filter method returns expected value" do
    assert_equal(@filter, @cn.filter)
  end

  test "wait basic functionality" do
    assert_respond_to(@cn, :wait)
  end

  test "an error is raised if a timeout occurs" do
    assert_raise(SystemCallError){ @cn.wait(0.001) }
    assert_raise(SystemCallError){ @cn.wait(0.001){} }
  end

  test "inherits wait_any method from Ipc parent" do
    assert_respond_to(@cn, :wait_any)
  end

  test "inherites wait_all method from Ipc parent" do
    assert_respond_to(@cn, :wait_all)
  end

  test "constructor requires the first argument to be a string" do
    assert_raises(TypeError){ ChangeNotify.new(1, true, @filter) }
  end

  test "constructor requires second argument to be a boolean" do
    assert_raises(TypeError){ ChangeNotify.new("C:\\", 'foo', @filter) }
  end

  test "constructor requires third argument to be numeric" do
    assert_raises(TypeError){ ChangeNotify.new("C:\\", false, "foo") }
  end

  test "constructor requires fourth argument to be a Win32::Event object" do
    assert_raises(TypeError){ ChangeNotify.new(1, true, @filter, 'bogus') }
  end

  test "ffi functions are private" do
    assert_not_respond_to(@cn, :ReadDirectoryChangesW)
    assert_not_respond_to(ChangeNotify, :ReadDirectoryChangesW)
  end

  def teardown
    @cn = nil
    @filter = nil
  end
end
