module game_ctx;

import std::io;
import gl;
import rl;

import timer;

enum GameState {
  TITLE_SCREEN,
  GAMEPLAY,
  END_SCREEN
}

struct GameContext {
  Texture2D entity_atlas; // Pacman, ghosts and fruits
  Timer timer;

  Gameplay gameplay;
  TitleScreen title_screen;
  DeathScreen death_screen;
}

fn void? GameContext.init(&self) {
  const String ATLAS_FILENAME = "assets/textures/entity.png";
  
  self.entity_atlas = rl::load_texture(ATLAS_FILENAME);
  if(!rl::is_texture_valid(self.entity_atlas)) {
    io::printn("Entity texture was not loaded!");
    return io::FILE_NOT_FOUND?;
  }
  
  self.timer.init();
  self.gameplay.init(&self.entity_atlas, &self.timer)!!;
  self.title_screen.init(&self.entity_atlas, &self.timer)!!;
  self.death_screen.init(&self.timer)!!;
}

<*
 @param [&inout] state : "Game state was passed as null!"
 @param [&inout] pause : "Pause was passed as null!"
 @param [&out] end_game : "End game was passed as null!"
*>
fn void GameContext.advance_game_state(&self, GameState *state, TimeSpan *pause, bool *end_game) {
  if(*state == TITLE_SCREEN) {
    self.title_screen.update(state);
    return;
  }
  
  if(*state == GAMEPLAY) {
    self.gameplay.update(state, pause);
    return;
  }

  self.death_screen.update(state);
}

fn void GameContext.draw(&self, GameState state, TimeSpan pause) {
  if(state == TITLE_SCREEN) {
    self.title_screen.draw(self.timer.dt);
    return;
  }
  
  if(state == GAMEPLAY) {
    self.gameplay.draw(pause);
    return;
  }

  self.death_screen.draw();
}

fn void GameContext.clean(&self) {
  rl::unload_texture(self.entity_atlas);
  self.gameplay.clean();
}
