module rl;

enum TraceLogLevel : CInt (inline CInt state) {
  LOG_ALL     = 0,          // Display all logs
  LOG_TRACE   = 1,          // Trace logging, intended for internal use only
  LOG_DEBUG   = 2,          // Debug logging, used for internal debugging, it should be disabled on release builds
  LOG_INFO    = 3,          // Info logging, used for program execution info
  LOG_WARNING = 4,          // Warning logging, used on recoverable failures
  LOG_ERROR   = 5,          // Error logging, used on unrecoverable failures
  LOG_FATAL   = 6,          // Fatal logging, used to abort program: exit(EXIT_FAILURE)
  LOG_NONE    = 7           // Disable logging
}

extern fn void set_trace_log_level(CInt log_level) @extern("SetTraceLogLevel");
