require 'ffi'

module Windows
  module Structs
    extend FFI::Library

    class OVERLAPPED < FFI::Struct
      layout(
        :Internal, :uintptr_t,
        :InternalHigh, :uintptr_t,
        :Offset, :ulong,
        :OffsetHigh, :ulong,
        :hEvent, :uintptr_t
      )
    end

    class FILE_NOTIFY_INFORMATION < FFI::Struct
      layout(
        :NextEntryOffset, :ulong,
        :Action, :ulong,
        :FileNameLength, :ulong,
        :FileName, [:uint8, 1024]
      )
    end
  end
end
