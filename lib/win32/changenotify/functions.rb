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
  end
end
