module game_ctx;

import std::io;
import std::time;
import gl;
import rl;

import timer;

enum GameState {
  TITLE_SCREEN,
  GAMEPLAY,
  DEATH_SCREEN
}

struct GameContext {
  Clock clock;
  TimeSpan dt;
  TimeSpan accumulator;
  TimeSpan curr_time;
  
  TitleScreen *title_screen;
  Gameplay *gameplay;
  DeathScreen *death_screen;
}

fn void? GameContext.init(&self) {
  self.clock.mark();
  self.dt = 0.01f;
  self.accumulator = 0.0f;
  self.curr_time = (TimeSpan)self.clock.to_now().to_sec();
  
  self.title_screen = mem::new(TitleScreen);
  self.title_screen.init()!!;
  self.gameplay = null;
  self.death_screen = null;
}

<*
 @param [&inout] state : "Game state was passed as null!"
*>
fn void GameContext.change_state(&self, GameState *state) {
  if(*state == TITLE_SCREEN) {
    self.title_screen = mem::new(TitleScreen);
    self.title_screen.init()!!;

    self.death_screen.free();
    free(self.death_screen);
    self.death_screen = null;
    return;
  }

  if(*state == GAMEPLAY) {
    self.gameplay = mem::new(Gameplay);
    self.gameplay.init()!!;

    self.title_screen.free();
    free(self.title_screen);
    self.title_screen = null;
    return;
  }

  if(*state == DEATH_SCREEN) {
    self.death_screen = mem::new(DeathScreen);
    self.death_screen.init()!!;

    self.gameplay.free();
    free(self.gameplay);
    self.gameplay = null;
    return;
  }
}

<*
 @param [&inout] state : "Game state was passed as null!"
 @param [&out] end_game : "End game was passed as null!"
*>
fn void GameContext.update(&self, GameState *state, bool *end_game) {
  GameState prev_state = *state;

  TimeSpan new_time = (TimeSpan)self.clock.to_now().to_sec();
  TimeSpan frame_time = new_time - self.curr_time;
  self.curr_time = new_time;
  
  self.accumulator += frame_time;

  while(self.accumulator >= self.dt) {
    bool update_game_loop = false;
    
    if(*state == TITLE_SCREEN) { self.title_screen.update(state, self.dt); }
    else if(*state == GAMEPLAY) {
      self.gameplay.update_state(state, &update_game_loop, self.dt);
      if(update_game_loop) self.gameplay.game_loop(new_time, self.dt);
    }
    else { self.death_screen.update(state, self.dt); }

    if(*state != prev_state) {
      self.change_state(state);
      prev_state = *state;
    }
    
    self.accumulator -= self.dt;
  }
}

fn void GameContext.draw(&self, GameState state) {
  if(state == TITLE_SCREEN) {
    self.title_screen.draw();
    return;
  }
  
  if(state == GAMEPLAY) {
    self.gameplay.draw();
    return;
  }

  if(state == DEATH_SCREEN) {
    self.death_screen.draw();
  }
}

fn void GameContext.free(&self) {
  if(self.title_screen != null) self.title_screen.free();
  if(self.gameplay     != null) self.gameplay.free();
  if(self.death_screen != null) self.death_screen.free();

  free(self.title_screen);
  free(self.gameplay);
  free(self.death_screen);
}
