require 'win32/event'

require File.join(File.dirname(__FILE__), 'changenotify', 'constants')
require File.join(File.dirname(__FILE__), 'changenotify', 'functions')
require File.join(File.dirname(__FILE__), 'changenotify', 'structs')

# The Win32 module serves as a namespace only
module Win32

  # The Win32::ChangeNotify class encapsulates filesystem change notifications
  class ChangeNotify < Ipc
    include Windows::Constants
    include Windows::Structs
    include Windows::Functions

    extend Windows::Functions

    # The version of the win32-changenotify library
    VERSION = '0.6.0'

    # Filter: Attribute changes
    ATTRIBUTES = FILE_NOTIFY_CHANGE_ATTRIBUTES

    # Filter: Directory name changes
    DIR_NAME = FILE_NOTIFY_CHANGE_DIR_NAME

    # Filter: File name changes
    FILE_NAME = FILE_NOTIFY_CHANGE_FILE_NAME

    # Filter: Write changes
    LAST_WRITE = FILE_NOTIFY_CHANGE_LAST_WRITE

    # Filter: File security changes
    SECURITY = FILE_NOTIFY_CHANGE_SECURITY

    # Filter: File size changes
    SIZE = FILE_NOTIFY_CHANGE_SIZE

    # :stopdoc:

    # Yielded by the ChangeNotify#wait method
    ChangeNotifyStruct = Struct.new('ChangeNotifyStruct', :action, :file_name)

    # :startdoc:

    # The path that was provided to the constructor
    attr_reader :path

    # The value of the filter (OR'd constants) passed to the constructor
    attr_reader :filter

    # Returns a new ChangeNotify object and places a monitor on +path+.
    # The +path+ argument may be a file or a directory.
    #
    # If +recursive is true and +path+ is a directory, then the monitor
    # applies to all subdirectories of +path+.
    #
    # The +filter+ tells the monitor what to watch for, such as file
    # changes, attribute changes, etc.
    #
    # If the +event+ option is specified, it must be a Win32::Event object.
    # It is then set as the event that will be set to the signaled state
    # when a notification has been completed.
    #
    # Yields itself if a block is provided, and automatically closes itself
    # when the block terminates.
    #
    def initialize(path, recursive, filter, event=nil)
      @path      = path
      @recursive = recursive
      @filter    = filter
      @overlap   = OVERLAPPED.new

      # Because Win32API doesn't do type checking, we do it expicitly here.
      raise TypeError unless path.is_a?(String)
      raise TypeError unless [true, false].include?(recursive)
      raise TypeError unless filter.is_a?(Fixnum)

      if event
        raise TypeError unless event.respond_to?(:handle)
        @handle = event.handle
      else
        event = Win32::Event.new
        @handle = event.handle
      end

      @event = event

      @overlap[:hEvent] = @handle

      super(@handle)

      if block_given?
        begin
          yield self
        ensure
          close
        end
      end
    end

    # Returns whether or not the ChangeNotify object is monitoring
    # subdirectories of the path being monitored.
    #
    def recursive?
      @recursive
    end

    alias ipc_wait wait

    # Waits up to 'seconds' for a notification to occur, or infinitely
    # if no value is specified.
    #
    # Yields an array of ChangeNotifyStruct's that contains two
    # members: file_name and action.
    #
    def wait(seconds = INFINITE)
      seconds *= 1000 unless seconds == INFINITE

      fni_ptr = FFI::MemoryPointer.new(FILE_NOTIFY_INFORMATION, 4096)
      rbytes  = FFI::MemoryPointer.new(:ulong)
      qbytes  = FFI::MemoryPointer.new(:ulong)

      dir_handle = get_dir_handle(@path)

      comp_key = FFI::MemoryPointer.new(:ulong)
      comp_key.write_ulong(12345)

      begin
        comp_port = CreateIoCompletionPort(dir_handle, 0, comp_key, 0)

        if comp_port == 0
          raise SystemCallError.new('CreateIoCompletionPort', FFI.errno)
        end

        bool = ReadDirectoryChangesW(
           dir_handle,
           fni_ptr,
           fni_ptr.size,
           @recursive,
           @filter,
           rbytes,
           @overlap,
           nil
        )

        raise_windows_error('ReadDirectoryChangesW') unless bool

        while true
          bool = GetQueuedCompletionStatus(
            comp_port,
            qbytes,
            comp_key,
            @overlap,
            seconds
          )

          raise_windows_error('GetQueuedCompletionStatus') unless bool

          @signaled = true
          @event.signaled = true

          break if comp_key.read_ulong == 0

          yield get_file_action(fni_ptr) if block_given?

          bool = ReadDirectoryChangesW(
            dir_handle,
            fni_ptr,
            fni_ptr.size,
            @recursive,
            @filter,
            rbytes,
            @overlap,
            nil
          )

          raise_windows_error('ReadDirectoryChangesW') unless bool
        end
      ensure
        CloseHandle(dir_handle)
      end
    end

    private

    # Returns an array of ChangeNotify structs, each containing a file name
    # and an action.
    #
    def get_file_action(fni_ptr2)
      fni_ptr = fni_ptr2.dup # Will segfault otherwise
      array  = []

      while true
        str_action = 'unknown'
        fni = FILE_NOTIFY_INFORMATION.new(fni_ptr)

        case fni[:Action]
          when FILE_ACTION_ADDED
            str_action = 'added'
          when FILE_ACTION_REMOVED
            str_action = 'removed'
          when FILE_ACTION_MODIFIED
            str_action = 'modified'
          when FILE_ACTION_RENAMED_OLD_NAME
            str_action = 'renamed old name'
          when FILE_ACTION_RENAMED_NEW_NAME
            str_action = 'renamed new name'
        end

        len  = fni[:FileNameLength]
        file = (fni[:FileName].to_ptr.read_string(len) + "\0\0").force_encoding('UTF-16LE')
        file.encode!(Encoding.default_external)

        struct = ChangeNotifyStruct.new(str_action, file)
        array.push(struct)

        break if fni[:NextEntryOffset] == 0
        fni_ptr += fni[:NextEntryOffset]
        break if fni.null?
      end

      array
    end

    # Returns a HANDLE to the directory +path+ created via CreateFile().
    #
    def get_dir_handle(path)
      handle = CreateFileA(
        path,
        FILE_LIST_DIRECTORY,
        FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,
        nil,
        OPEN_EXISTING,
        FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED,
        0
      )

      if handle == INVALID_HANDLE_VALUE
        raise_windows_error('CreateFileA')
      end

      handle
    end
  end
end
