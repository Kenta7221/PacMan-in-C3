import std::io;

import gl;
import rl;
import game_ctx;

fn void main() {
  const WIDTH  = gl::SCALE * gl::TILE_SIZE * gl::MAZE_WIDTH;
  const HEIGHT = gl::SCALE * gl::TILE_SIZE * (gl::MAZE_HEIGHT + gl::TOP_UI_SIZE + gl::BOTTOM_UI_SIZE);
  
  rl::init_window(WIDTH, HEIGHT, "PacMan with C3");
  rl::set_target_fps(60); // TODO

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
