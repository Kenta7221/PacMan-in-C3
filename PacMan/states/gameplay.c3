module game_ctx::gameplay;

import std::io;

import gl;
import rl;

import maze;
import pacman;
import ghost;
import fruit;
import ui;
import timer;
import audio_manager;
import score_popup;

/*

Index of this module:
// Struct, enum and methods definitions
// Helper functions

*/

//------------------------------------------------------------------------------------
// Struct, enum and methods definitions
//------------------------------------------------------------------------------------

enum GameplayState : Uint8 (inline Uint8 state) {
  START_LEVEL         = 1 << 0,
  RESET_LEVEL         = 1 << 1,
  NEXT_LEVEL          = 1 << 2,
  CHASE_MODE          = 1 << 3,
  FRIGHTEN_MODE       = 1 << 4,
  USE_GLOBAL_COUNTER  = 1 << 5,
  GHOST_EATEN         = 1 << 6
}

struct Gameplay {
  Texture2D ghost_atlas;
  AudioManager audio_manager;
  Music[2] musics;  // Pacman, Ghost speed
  Sound* sound; // Ghost, fruit eaten and death sfx 
  
  Uint8 flags; // Game play states
  Uint8 eaten_dots;
  Uint8 eaten_ghosts;
  Uint8 global_ghosts_dot_counter;
  Uint16 rng_index; // Decides the direction of frighten ghost
  TimeSpan pause; // For pausing the game when pacman dies etc.

  Timer timer;
  GameUI ui;
    
  Maze maze;
  PacMan pacman;
  Ghost[4] ghosts;
  Fruit* fruit;
  ScorePopup *score_popup;
}

fn void? Gameplay.init(&self) {
  const GHOST_ATLAS = "assets/textures/ghosts.png";
  
  self.ghost_atlas = rl::load_texture(GHOST_ATLAS);
  if(!rl::is_texture_valid(self.ghost_atlas)) {
    io::eprintn("Ghost atlas has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }

  self.audio_manager.init()!;
    
  self.sound = null;
  
  self.flags |= GameplayState.START_LEVEL;
  self.eaten_dots = 0;
  self.eaten_ghosts = 0;
  self.global_ghosts_dot_counter = 0;
  self.rng_index = 0;
  self.pause = 0.f;

  self.timer.init();
  self.ui.init()!;
    
  self.pacman.init()!;

  self.ghosts[0].init(GhostType.BLINKY, &self.ghost_atlas);
  self.ghosts[1].init(GhostType.PINKY , &self.ghost_atlas);
  self.ghosts[2].init(GhostType.INKY  , &self.ghost_atlas);
  self.ghosts[3].init(GhostType.CLYDE , &self.ghost_atlas);

  self.fruit = null;
  self.score_popup = null;
  
  self.maze.init()!;
}

fn void Gameplay.reset_level(&self) {
  self.flags = 0;
  self.eaten_dots = 0;
  self.eaten_ghosts = 0;
  self.global_ghosts_dot_counter = 0;
  self.rng_index = 0;
  self.pause = 0.f;

  self.timer.reset();
  self.audio_manager.update_ghost_music(0, GhostMusicType.NONE);
  
  if(self.score_popup != null) score_popup::handler(&self.score_popup, {0, 0}, 0, 0, PopupState.DESTROY, EventType.FRUIT_EATEN);
  if(self.fruit != null) {
    rl::unload_texture(self.fruit.texture);
    free(self.fruit);
    self.fruit = null;
  }
  
  self.ghosts[0].set_at_start_pos();
  self.ghosts[1].set_at_start_pos();
  self.ghosts[2].set_at_start_pos();
  self.ghosts[3].set_at_start_pos();
  
  self.pacman.set_at_start_pos();

  self.maze.reset_maze();
}

<*
 Updates everythink based on set flags. Handles all the pauses between start of the level,
 eating a ghost, death of pacman etc.
 @param [&out]   state : "Game state was passed as null!"
 @param [&out]   enter_game_loop : "Enter game loop was passed as null!"
*>
fn void Gameplay.update_state(&self, GameState *state, bool *enter_game_loop, TimeSpan dt) {
  if(self.flags & GameplayState.START_LEVEL) {
    if(self.pause < 2.f) {
      self.pause += dt;
      *enter_game_loop = false;
      return;
    }

    self.flags ^= GameplayState.START_LEVEL;
    self.pause = 0.0f;
    *enter_game_loop = false;
    return;
  }

  if(self.flags & GameplayState.GHOST_EATEN) {
    if(self.pause < 1.f) {
      self.pause += dt;
      *enter_game_loop = false;
      return;
    }

    self.pause = 0.0f;
    self.flags ^= GameplayState.GHOST_EATEN;
    *enter_game_loop = false;
    return;
  }

  if(self.flags & GameplayState.RESET_LEVEL) {
    if(self.pause < 1.f) {
      self.pause += dt;
      *enter_game_loop = false;
      return;
    }

    if(self.pause < 3.f) {
      if(self.pacman.animation.switch_time != 0.18f) {
	self.pacman.animation.update_swtich_time(0.18f);
      }
      
      self.pacman.update(self.timer.level, &self.maze.tiles, dt);
      self.pause += dt;
      *enter_game_loop = false;
      return;
    }

    self.pause = 0.0f;

    self.flags ^= GameplayState.RESET_LEVEL;
    self.flags |= GameplayState.USE_GLOBAL_COUNTER;

    self.pacman.lives--;
    self.pacman.state_flags ^= PacManState.DEAD;
    self.pacman.animation.update_swtich_time(0.08f);

    if(self.pacman.lives == 0) {
      ui::save_high_score(self.ui.high_score);      
      *state = DEATH_SCREEN;
      *enter_game_loop = false;
      return;
    }
      
    self.reset_level();
    *enter_game_loop = false;
    return;
  }

  if(self.flags & GameplayState.NEXT_LEVEL) {
    if(self.pause < 3.f) {
      self.pause += dt;
      *enter_game_loop = false;
      return;
    }

    self.pause = 0.f;
    
    self.timer.level++;
    self.ui.add_fruit(self.timer.level);
    self.flags ^= GameplayState.NEXT_LEVEL;
    self.reset_level();
    *enter_game_loop = false;
    return;
  }

  *enter_game_loop = true;
}

fn void Gameplay.game_loop(&self, TimeSpan new_time, TimeSpan dt) {
  self.timer.update(new_time);
  self.audio_manager.update();
  
  if(self.eaten_dots >= 244) {
    self.flags |= GameplayState.NEXT_LEVEL;
    return;
  }

  if(self.score_popup != null) self.score_popup.elapsed_time += dt;

  // TODO: Check if the actual timer in pacman doesn't progress if there is frighten mode
  if(self.timer.new_cycle(dt) && !(self.flags & GameplayState.FRIGHTEN_MODE)) {
    self.flags ^= GameplayState.CHASE_MODE;
      
    self.timer.cycle = 0.f;
    self.timer.which_cycle++;

    if(self.timer.which_cycle % 2 == 0) {
      self.audio_manager.update_ghost_music(0, GhostMusicType.values[self.timer.which_cycle + 1]);
    }    
  }
 
  if(self.timer.end_frighten_mode(dt, (bool)(self.flags & GameplayState.FRIGHTEN_MODE))) {
    self.flags ^= GameplayState.FRIGHTEN_MODE;
    self.timer.frighten_mode = 0.f;
    
    self.eaten_ghosts = 0;
    foreach(&ghost : self.ghosts) { ghost.state_flags &= (Uint8)~GhostState.FRIGHTEN.state; }

    self.audio_manager.update_ghost_music(0, GhostMusicType.values[self.timer.which_cycle + 1]);
  }

  // 2. PacMan interaction
  self.pacman.update(self.timer.level, &self.maze.tiles, dt);

  bool dot_eaten = false;
  EventType e = self.maze.update(&self.pacman);
  if(e == ENERGIZE_EATEN) {
    dot_eaten = true;
    self.eaten_dots++;
    self.ui.score += 50;
    self.flags |= GameplayState.FRIGHTEN_MODE;
    self.audio_manager.update_ghost_music(self.flags, GhostMusicType.values[self.timer.which_cycle + 1]);
    
    // All ghosts turn 180 degrees upon the begging of the frighten mode
    foreach(&ghost : self.ghosts) {
      if(~ghost.state_flags & GhostState.IN_SPAWN && ~ghost.state_flags & GhostState.DEAD) {
	ghost.state_flags |= GhostState.FRIGHTEN;
	ghost.turn_180();
      }
    }
  }

  fruit_handler(&self.fruit, &self.score_popup, self, dt);

  if(e == SCORE_INCREASE) {
    dot_eaten = true;
    self.eaten_dots++;
    self.ui.score += 10;
    self.audio_manager.update_sound(self.flags, fruit_eaten: false);
    
    if(self.flags & GameplayState.USE_GLOBAL_COUNTER) { self.global_ghosts_dot_counter++; }
  }

  self.audio_manager.update_pacman_music(dot_eaten, dt);

  if(self.audio_manager.go_home_playing) {
    bool stop_music = true;
    foreach(&ghost : self.ghosts) {
      if(ghost.state_flags & GhostState.DEAD || ghost.state_flags & GhostState.ENTERING_SPAWN) { stop_music = false; break; }
    }

    if(stop_music) {
      self.audio_manager.update_ghost_music(self.flags, GhostMusicType.values[self.timer.which_cycle + 1]);
      self.audio_manager.go_home_playing = false;
    }
  }

  // Checking this out of loop because only blinky can become elroy
  if(ghost::activate_elroy(self.timer.level, self.eaten_dots) &&
  !(self.ghosts[GhostType.BLINKY].state_flags & GhostState.ELROY)) {
    self.ghosts[GhostType.BLINKY].state_flags |= GhostState.ELROY;
  }
  
  foreach(idx, &ghost : self.ghosts) {
    bool collision = false;
    
    if(dot_eaten && idx != GhostType.BLINKY) ghost::increase_counter((Uint8)idx, &ghost.dot_counter, self.timer.level);

    ghost.update(self, &collision, dot_eaten, dt);

    if(collision) {      
      if(ghost.state_flags & GhostState.DEAD) {
	self.flags |= GameplayState.GHOST_EATEN;
	self.eaten_ghosts += 1;
	self.audio_manager.update_sound(self.flags, fruit_eaten: false);
	self.audio_manager.update_ghost_music(0, GhostMusicType.GO_HOME);
	self.audio_manager.go_home_playing = true;
	score_popup::handler(&self.score_popup, ghost.pos, self.eaten_ghosts, 0, PopupState.INIT, EventType.GHOST_EATEN);
	continue;
      }
      
      self.pacman.state_flags |= PacManState.DEAD;
      self.flags |= GameplayState.RESET_LEVEL;
      self.audio_manager.update_sound(self.flags, fruit_eaten: false);
      return;
    }    
  }
}

fn void Gameplay.draw(&self) {
  if(self.flags & GameplayState.START_LEVEL) {
    self.maze.draw();    
    draw_ready_player_text(&self.ui.font, self.pause);
      
    if(self.pause > 1.f) {
      foreach(i, &ghost : self.ghosts) self.ghosts[i].draw();
    }
      
    self.pacman.draw();
    return;
  }

  if(self.flags & GameplayState.GHOST_EATEN) {
    self.maze.draw();
      
    if(self.fruit != null) self.fruit.draw();

    foreach(i, &ghost : self.ghosts) self.ghosts[i].draw();
    self.pacman.draw();
    self.ui.draw(&self.pacman.texture, self.pacman.lives);
      
    if(self.score_popup == null) return;
    self.score_popup.can_drawn()
      ? self.score_popup.draw()
      : score_popup::handler(&self.score_popup, {0, 0}, 0, 0, PopupState.DESTROY, EventType.NONE);
    return;
  }

  if(self.flags & GameplayState.RESET_LEVEL) { // aka PacMan died
    self.maze.draw();
      
    if(self.fruit != null) self.fruit.draw();

    if(self.pause < 1.f) {
      foreach(i, &ghost : self.ghosts) self.ghosts[i].draw();
    }
    
    self.pacman.draw();
    self.ui.draw(&self.pacman.texture, self.pacman.lives);
    return;
  }

  if(self.flags & GameplayState.NEXT_LEVEL) {
    self.ui.draw(&self.pacman.texture, self.pacman.lives);
    
    if(self.pause < 1.f) {
      self.maze.draw(finished_level: false, blinking_energizer: false);
    } else {
      self.maze.draw(finished_level: true, blinking_energizer: false);
    }
    
    if(self.fruit != null) self.fruit.draw();
    
    if(self.pause < 1.1f) {
      foreach(i, &ghost : self.ghosts) self.ghosts[i].draw();
    }
    
    self.pacman.draw();
    return;
  }

  // Game loop draw
  self.maze.draw(finished_level: false, blinking_energizer: true);
      
  if(self.fruit != null) self.fruit.draw();
      
  foreach(i, &ghost : self.ghosts) self.ghosts[i].draw();
      
  self.pacman.draw();      
  self.ui.draw(&self.pacman.texture, self.pacman.lives);
      
  if(self.score_popup == null) return;
  self.score_popup.can_drawn()
    ? self.score_popup.draw()
    : score_popup::handler(&self.score_popup, {0, 0}, 0, 0, PopupState.DESTROY, EventType.NONE);    
}

fn void Gameplay.free(&self) {
  rl::unload_texture(self.ghost_atlas);
  
  self.ui.free();
  self.audio_manager.free();
  self.maze.free();

  if(self.score_popup != null) score_popup::handler(&self.score_popup, {0, 0}, 0, 0, PopupState.DESTROY, EventType.NONE);
  if(self.fruit != null) {
    self.fruit.free();
    free(self.fruit);
  }
}

//------------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------------

<*
 @param [inout] fruit : "Fruit was passed as null!"
 @param [inout] score_popup : "Score Popup was passed as null!"
 @param [&in] ctx : "Game Context was passed as null!"
*>
fn void fruit_handler(Fruit **fruit, ScorePopup **score_popup, Gameplay *ctx, TimeSpan dt) {
  if((ctx.eaten_dots == 70 || ctx.eaten_dots == 170) && (*fruit) == null) {
    *fruit = mem::new(Fruit);
    (*fruit).init(ctx.timer.level)!!;
  }
  
  if((*fruit) != null) {
    (*fruit).elapsed_time += dt;

    if((*fruit).elapsed_time > 9.5f) {
      rl::unload_texture((*fruit).texture);
      free((*fruit));
      (*fruit) = null;
      return;
    }

    if((*fruit).collision(ctx.pacman.pos)) {
      score_popup::handler(score_popup, (*fruit).pos, 0, (*fruit).points, PopupState.INIT, EventType.FRUIT_EATEN);
      ctx.audio_manager.update_sound(ctx.flags, fruit_eaten: true);
      
      ctx.ui.score += (*fruit).points;

      rl::unload_texture((*fruit).texture);
      free((*fruit));
      (*fruit) = null;
    }
  }
}

<*
 @param [&in] font : "Font was passed as null!"
*>
fn void draw_ready_player_text(Font *font, TimeSpan pause) {
  rl::draw_text_ex(*font,
		   "Ready!",
		   {
		     12 * gl::TEXT_SIZE - gl::TEXT_SIZE / 8,
		     20 * gl::TEXT_SIZE
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   {255, 255, 0, 255}
  );

  if(pause < 1.f) {
    rl::draw_text_ex(*font,
		     "Player One",
		     {
		       10 * gl::TEXT_SIZE,
		       14 * gl::TEXT_SIZE
		     },
		     gl::TEXT_SIZE,
		     0.f,
		     {0, 255, 255, 255}
    );
  }
}
