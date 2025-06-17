module game_ctx;

import std::io;
import gl;
import rl;

import timer;

enum GameState {
  TITLE_SCREEN,
  GAMEPLAY,
  DEATH_SCREEN
}

struct GameContext {
  Texture2D entity_atlas; // Pacman, ghosts and fruits
  Timer timer;

  TitleScreen *title_screen;
  Gameplay *gameplay;
  DeathScreen *death_screen;
}

fn void? GameContext.init(&self) {
  const String ATLAS_FILENAME = "assets/textures/entity.png";
  
  self.entity_atlas = rl::load_texture(ATLAS_FILENAME);
  if(!rl::is_texture_valid(self.entity_atlas)) {
    io::printn("Entity texture was not loaded!");
    return io::FILE_NOT_FOUND?;
  }

  self.timer.init();
  
  self.title_screen = mem::new(TitleScreen);
  self.title_screen.init(&self.entity_atlas, &self.timer)!!;
  
  self.gameplay = null;

  self.death_screen = null;
}

<*
 @param [&inout] state : "Game state was passed as null!"
*>
fn void GameContext.change_state(&self, GameState *state) {
  if(*state == TITLE_SCREEN) {
    self.title_screen = mem::new(TitleScreen);
    self.title_screen.init(&self.entity_atlas, &self.timer)!!;

    self.gameplay.free();
    free(self.gameplay);
    self.gameplay = null;    
    return;
  }

  if(*state == GAMEPLAY) {
    self.gameplay = mem::new(Gameplay);
    self.gameplay.init(&self.entity_atlas, &self.timer)!!;

    self.title_screen.free();
    free(self.title_screen);
    self.title_screen = null;
    return;
  }

  if(*state == DEATH_SCREEN) {
    self.death_screen = mem::new(DeathScreen);
    self.death_screen.init(&self.timer)!!;

    self.gameplay.free();
    free(self.gameplay);
    self.gameplay = null;
    return;
  }
}

<*
 @param [&inout] state : "Game state was passed as null!"
 @param [&inout] pause : "Pause was passed as null!"
 @param [&out] end_game : "End game was passed as null!"
*>
fn void GameContext.update(&self, GameState *state, TimeSpan *pause, bool *end_game) {
  GameState prev_state = *state;

  defer if(*state != prev_state) self.change_state(state);
  
  if(*state == TITLE_SCREEN) {
    self.title_screen.update(state);
    return;
  }
  
  if(*state == GAMEPLAY) {
    self.gameplay.update(state, pause);
    return;
  }
  
  if(*state == DEATH_SCREEN) {
    self.death_screen.update(state);
  }
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

  if(state == DEATH_SCREEN) {
    self.death_screen.draw();
  }
}

fn void GameContext.free(&self) {
  rl::unload_texture(self.entity_atlas);
  
  if(self.title_screen != null) self.title_screen.free();
  if(self.gameplay     != null) self.gameplay.free();
  if(self.death_screen != null) self.death_screen.free();

  free(self.title_screen);
  free(self.gameplay);
  free(self.death_screen);
}
