require 'ffi'

module Windows
  module Functions
    extend FFI::Library
    ffi_lib :kernel32

    typedef :uintptr_t, :handle
    typedef :ulong, :dword
    typedef :pointer, :ptr

    attach_function :ReadDirectoryChangesW,
      [:handle, :ptr, :dword, :bool, :dword, :ptr, :ptr, :ptr],
      :bool

    attach_function :CreateIoCompletionPort,
      [:handle, :handle, :pointer, :dword],
      :handle

    attach_function :GetQueuedCompletionStatus,
      [:handle, :ptr, :ptr, :ptr, :dword],
      :bool,
      :nonblock => true

    attach_function :CreateFileA,
      [:string, :dword, :dword, :ptr, :dword, :dword, :handle],
      :handle

    attach_function :FormatMessage, :FormatMessageA,
      [:ulong, :pointer, :ulong, :ulong, :pointer, :ulong, :pointer], :ulong


    # Returns a nicer Windows error message
    def win_error(function, err=FFI.errno)
      flags = 0x00001000 | 0x00000200
      buf = FFI::MemoryPointer.new(:char, 1024)

      FormatMessage(flags, nil, err , 0x0409, buf, 1024, nil)

      function + ': ' + buf.read_string.strip
    end

    # Shortcut for win_error with raise builtin
    def raise_windows_error(function, err=FFI.errno)
      raise SystemCallError.new(win_error(function, err), err)
    end

    module_function :win_error
    module_function :raise_windows_error
  end
end
