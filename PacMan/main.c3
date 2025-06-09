import std::io;

import gl;
import rl;
import game_ctx;

const WIDTH  = gl::SCALE * gl::PIXEL_SIZE * gl::MAZE_WIDTH;
const HEIGHT = gl::SCALE * gl::PIXEL_SIZE * (gl::MAZE_HEIGHT + gl::TOP_UI_SIZE + gl::BOTTOM_UI_SIZE);

// Check if works on windows
// Ship the game
// Tsoding cmake smth git tip 

fn void main() {
  rl::init_window(WIDTH, HEIGHT, "PacMan with C3");
  rl::set_target_fps(60);

  GameState state = TITLE_SCREEN;
  GameContext ctx;
  ctx.init()!!;

  TimeSpan pause = 0.0f; // Handles all the pauses in gameplay and end screen
  bool end_game = false;
  while(!rl::window_should_close() && !end_game) {
    ctx.timer.update();
    
    ctx.advance_game_state(&state, &pause, &end_game);
    
    rl::begin_drawing();
    rl::clear_background((Color){0, 0, 0, 255});
    
    ctx.draw(state, pause);
    
    rl::end_drawing();
  }

  ctx.clean();
  rl::close_window();
}
