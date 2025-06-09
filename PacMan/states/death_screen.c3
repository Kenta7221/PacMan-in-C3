module game_ctx::death_screen;

import std::io;

import rl;
import gl;

import maze;
import timer;

const FONT_BASE_SIZE = 64;
const CHAR_SIZE = 32;
const DRAW_FONT_SIZE = 36;

struct DeathScreen {
  Font font;
  Timer *timer;
  Maze maze;
}

fn void? DeathScreen.init(&self, Timer *timer) {
  const String FONT_DIR = "assets/fonts/emulogic.ttf";

  self.font = rl::load_font_ex(FONT_DIR, FONT_BASE_SIZE, null, 0);
  if(!rl::is_font_valid(self.font)) {
    io::printn("Font has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }
  
  self.timer = timer;
  self.maze.init()!!;
}

<*
 @param [&out] state : "Game state passed as null!"
*>
fn void DeathScreen.update(&self, GameState *state) {
  static TimeSpan total_time = 0.0f;
  total_time += self.timer.dt;

  if(total_time < 2.0f) return;

  *state = TITLE_SCREEN;
  total_time = 0.0f;
}

fn void DeathScreen.draw(&self) {
  self.maze.draw(dt: 0);

  rl::draw_text_ex(self.font,
		   "Game   Over",
		   { (Uint16)(gl::MAZE_WIDTH / 2 * gl::PIXEL_SCALED - 5 * CHAR_SIZE), 20 * gl::PIXEL_SCALED - 5 },
		   DRAW_FONT_SIZE, 0.f,
		   (Color){255, 0, 0, 255}
  );
}
