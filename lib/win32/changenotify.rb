require 'win32/event'
require 'windows/nio'
require 'windows/file'
require 'windows/directory'
require 'windows/unicode'
require 'windows/msvcrt/buffer'

# The Win32 module serves as a namespace only
module Win32
   
   # The Win32::ChangeNotify class encapsulates filesystem change notifications
   class ChangeNotify < Ipc
      include Windows::NIO
      include Windows::File
      include Windows::Directory
      include Windows::Unicode
      include Windows::MSVCRT::Buffer
      
      # The version of the win32-changenotify library
      VERSION = '0.5.1'
      
      # Aliased constants
 
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
      
      # Private constants
     
      # File was added
      FILE_ACTION_ADDED = 0x00000001
      
      # File was deleted 
      FILE_ACTION_REMOVED = 0x00000002
      
      # File was modified  
      FILE_ACTION_MODIFIED = 0x00000003
        
      # File was renamed, old (original) name  
      FILE_ACTION_RENAMED_OLD_NAME = 0x00000004
      
      # File was renamed, new (current) name  
      FILE_ACTION_RENAMED_NEW_NAME = 0x00000005
      
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
         @overlap   = 0.chr * 20 # OVERLAPPED struct

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
         
         @overlap[16,4] = [@handle].pack('L') # hEvent member
         
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
        
         fni    = 0.chr * 65536 # FILE_NOTIFY_INFORMATION struct buffer   
         rbytes = [0].pack('L')
         qbytes = [0].pack('L')

         subtree    = @recursive ? 1 : 0
         dir_handle = get_dir_handle(@path)        
         comp_key   = [12345].pack('L')
                  
         begin
            comp_port = CreateIoCompletionPort(dir_handle, 0, comp_key, 0)
            
            if comp_port == 0
               raise Error, get_last_error
            end

            bool = ReadDirectoryChangesW(
               dir_handle,
               fni,
               fni.size,
               subtree,
               @filter,
               rbytes,
               @overlap,
               0
            )
            
            unless bool
               raise Error, get_last_error
            end
            
            while true
               bool = GetQueuedCompletionStatus(
                  comp_port,
                  qbytes,
                  comp_key,
                  @overlap,
                  seconds
               )
               
               unless bool
                  raise Error, get_last_error
               end
               
               @signaled = true
               @event.signaled = true
              
               break if comp_key.unpack('L').first == 0
                        
               yield get_file_action(fni) if block_given?
                          
               bool = ReadDirectoryChangesW(
                  dir_handle,
                  fni,
                  fni.size,
                  subtree,
                  @filter,
                  rbytes,
                  @overlap,
                  0
               )
               
               unless bool
                  raise Error, get_last_error
               end
            end
         ensure 
            CloseHandle(dir_handle)
         end
      end
      
      private
      
      # Returns an array of ChangeNotify structs, each containing a file name
      # and an action.
      #
      def get_file_action(fni2)
         fni = fni2.dup
         array  = []       
        
         while true               
            int_action = fni[4,4].unpack('L')[0]
           
            str_action = 'unknown'
        
            case int_action
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
           
            len  = fni[8,4].unpack('L').first # FileNameLength struct member
            file = fni[12,len] + "\0\0"       # FileName struct member + null
            buf  = 0.chr * 260
           
            WideCharToMultiByte(CP_ACP, 0, file, -1, buf, 260, 0, 0)
           
            file = File.join(@path, buf.unpack('A*')[0])
        
            struct = ChangeNotifyStruct.new(str_action, file)
            array.push(struct)
            break if fni[0,4].unpack('L')[0] == 0
            fni = fni[fni[0,4].unpack('L').first .. -1] # Next offset
            break if fni.nil?
         end
        
         array
      end
      
      # Returns a HANDLE to the directory +path+ created via CreateFile().
      # 
      def get_dir_handle(path)
         handle = CreateFile(
            path,
            FILE_LIST_DIRECTORY,
            FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,
            0,
            OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED,
            0
         )
         
         if handle == INVALID_HANDLE_VALUE
            raise Error, get_last_error
         end
         
         handle
      end
   end
end
