module game_ctx::death_screen;

import std::io;

import rl;
import gl;

import maze;
import timer;

struct DeathScreen {
  Font font;
  Timer *timer;
  Maze maze;
}

fn void? DeathScreen.init(&self, Timer *timer) {
  const String FONT_DIR = "assets/fonts/emulogic.ttf";

  self.font = rl::load_font_ex(FONT_DIR, gl::TEXT_SIZE, null, 0);
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
  //free(self.timer);
  self.maze.free();
}
