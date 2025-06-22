module game_ctx::death_screen;

import std::io;

import rl;
import gl;

import maze;
import timer;

/*

Index of this module:
// Struct and methods definitions

*/

//------------------------------------------------------------------------------------
// Struct and methods definitions
//------------------------------------------------------------------------------------

struct DeathScreen {
  Font font;
  Maze maze;
}

fn void? DeathScreen.init(&self) {
  const String FONT_DIR = "assets/fonts/emulogic.ttf";

  self.font = rl::load_font_ex(FONT_DIR, gl::TEXT_SIZE, null, 0);
  if(!rl::is_font_valid(self.font)) {
    io::printn("Font has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }
  
  self.maze.init()!!;
}

<*
 @param [&out] state : "Game state passed as null!"
*>
fn void DeathScreen.update(&self, GameState *state, TimeSpan dt) {
  static TimeSpan total_time = 0.0f;
  total_time += dt;
  
  if(total_time < 3.0f) return;

  *state = TITLE_SCREEN;
  total_time = 0.0f;
}

fn void DeathScreen.draw(&self) {
  self.maze.draw();

  rl::draw_text_ex(self.font,
		   "Game   Over",
		   {
		     10 * gl::TEXT_SIZE - gl::TEXT_SIZE / 2,
		     20 * gl::TEXT_SIZE
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   (Color){255, 0, 0, 255}
  );
}

fn void DeathScreen.free(&self) {
  rl::unload_font(self.font);
  self.maze.free();
}
