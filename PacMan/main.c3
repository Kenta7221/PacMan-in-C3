module main;

import std::io;

import gl;
import rl;
import game_ctx;

const SCREEN_SCALE = 4;

fn void main() {
  gl::check_scale(SCREEN_SCALE);
  const WIDTH  = SCREEN_SCALE * gl::TILE_SIZE * gl::MAZE_WIDTH;
  const HEIGHT = SCREEN_SCALE * gl::TILE_SIZE * (gl::MAZE_HEIGHT + gl::TOP_UI_SIZE + gl::BOTTOM_UI_SIZE);

  rl::set_trace_log_level(TraceLogLevel.LOG_NONE);
  rl::init_window(WIDTH, HEIGHT, "PacMan in C3");

  rl::init_audio_device();
  
  GameState state = TITLE_SCREEN;
  GameContext ctx;
  ctx.init()!!;

  bool end_game = false;
  while(!rl::window_should_close() && !end_game) {
    ctx.update(&state, &end_game);
    
    rl::begin_drawing();
    rl::clear_background({0, 0, 0, 255});
    
    ctx.draw(state);
    
    rl::end_drawing();
  }

  ctx.free();
  rl::close_audio_device();
  rl::close_window();
}
