module rl;

extern fn void set_config_flags(uint flags) @extern("SetConfigFlags");

extern fn void init_window(CInt width, CInt height, char *title) @extern("InitWindow");

extern fn void close_window() @extern("CloseWindow");

extern fn bool window_should_close() @extern("WindowShouldClose");

extern fn void begin_drawing() @extern("BeginDrawing");

extern fn void clear_background(Color color) @extern("ClearBackground");

extern fn void end_drawing() @extern("EndDrawing");

extern fn void set_target_fps(CInt fps) @extern("SetTargetFPS");

extern fn bool is_key_down(CInt key) @extern("IsKeyDown");

extern fn bool is_key_released(CInt key) @extern("IsKeyReleased");
