module game_ctx::gameplay;

import std::io;

import gl;
import rl;

import timer;

import ui;

import maze;
import pacman;
import ghost;
import fruit;
import score_popup;

enum GameplayState : Uint8 (inline Uint8 state) {
  START_LEVEL         = 1 << 0,
  RESET_LEVEL         = 1 << 1,
  NEXT_LEVEL          = 1 << 2,
  CHASE_MODE          = 1 << 3,
  FRIGHTEN_MODE       = 1 << 4,
  USE_GLOBAL_COUNTER  = 1 << 5,
  PACMAN_DIED         = 1 << 6,
  GHOST_EATEN         = 1 << 7
}

struct Gameplay {
  // Bit layout:
  // Bit 0 - Start level
  // Bit 1 - Reset level
  // Bit 2 - Next level
  // Bit 3 - chase mode, if 0 scatter mode
  // Bit 4 - frighten mode
  // Bit 5 - use global dot counter;
  // Bit 6 - pacman died
  // Bit 7 - ghost eaten
  Uint8 flags;
  
  Uint8 eaten_dots;
  Uint8 eaten_ghosts;
  Uint8 global_ghosts_dot_counter;

  Timer *timer;
  GameUI ui;
    
  Maze maze;
  PacMan pacman;
  Ghost[4] ghosts;
  Fruit* fruit;
  ScorePopup *score_popup;
}

<*
 @param [&in] entity_atlas : "Entity atlas passed as null!"
 @param [&in] entity_atlas : "Timer passed as null!"
*>
fn void? Gameplay.init(&self, Texture2D *entity_atlas, Timer *timer) {  
  self.global_ghosts_dot_counter = 0;
  self.eaten_dots = 0;
  self.eaten_ghosts = 0;
  self.flags |= GameplayState.START_LEVEL;

  self.timer = timer;
  self.ui.init(entity_atlas)!;
    
  self.pacman.init(entity_atlas);

  self.ghosts[0].init(GhostType.BLINKY, entity_atlas);
  self.ghosts[1].init(GhostType.PINKY , entity_atlas);
  self.ghosts[2].init(GhostType.INKY  , entity_atlas);
  self.ghosts[3].init(GhostType.CLYDE , entity_atlas);

  self.fruit = null;
  self.score_popup = null;
  
  self.maze.init()!;
}

fn void Gameplay.reset_level(&self) {
  self.flags = 0;
  self.eaten_ghosts = 0;
  self.eaten_dots = 0;
  self.global_ghosts_dot_counter = 0;

  self.timer.reset();
  
  if(self.score_popup != null) score_popup::handler(&self.score_popup, {0, 0}, 0, 0, PopupState.DESTROY, EventType.FRUIT_EATEN);
  if(self.fruit != null) {
    rl::unload_texture(self.fruit.texture);
    free(self.fruit);
    self.fruit = null;
  }
  
  self.ghosts[0].set_at_start_pos(GhostType.BLINKY);
  self.ghosts[1].set_at_start_pos(GhostType.PINKY );
  self.ghosts[2].set_at_start_pos(GhostType.INKY  );
  self.ghosts[3].set_at_start_pos(GhostType.CLYDE );
  
  self.pacman.set_at_start_pos();

  self.maze.reset_maze();
}

<*
 Updates everythink based on set flags. Handles all the pauses between start of the level,
 eating a ghost, death of pacman etc.
 @param [&out]   state : "Game state was passed as null!"
 @param [&inout] pause : "Pause was passed as null!"
*>
fn void Gameplay.update(&self, GameState *state, TimeSpan *pause) {
  if(self.flags & GameplayState.START_LEVEL) {
    if(*pause < 2.f) {
      *pause += self.timer.dt;
      return;
    }

    self.flags ^= GameplayState.START_LEVEL;
    *pause = 0.0f;
    return;
  }

  if(self.flags & GameplayState.GHOST_EATEN) {
    if(*pause < 1.f) {
      *pause += self.timer.dt;
      return;
    }

    *pause = 0.0f;
    self.flags ^= GameplayState.GHOST_EATEN;
    return;
  }

  if(self.flags & GameplayState.RESET_LEVEL) {
    if(*pause > 1.f && self.flags & GameplayState.PACMAN_DIED) {
      self.pacman.animation.update_everything(0, 11, 0.2); // Death animation
      self.flags ^= GameplayState.PACMAN_DIED;
      return;
    }
      
    if(*pause < 3.f) {
      *pause += self.timer.dt;
      return;
    }

    self.pacman.animation.update_everything(0, 3, 0.06f); // Normal animation

    *pause = 0.0f;

    self.flags ^= GameplayState.RESET_LEVEL;
    self.flags |= GameplayState.USE_GLOBAL_COUNTER;
    self.pacman.lives--;

    if(self.pacman.lives == 0) {
      ui::save_high_score(self.ui.high_score);      
      *state = END_SCREEN;
      return;
    }
      
    self.reset_level();
    return;
  }

  if(self.flags & GameplayState.NEXT_LEVEL) {
    if(*pause < 3.f) {
      *pause += self.timer.dt;
      return;
    }

    *pause = 0.f;
    
    self.timer.level++;
    self.ui.add_fruit(self.timer.level);
    self.flags ^= GameplayState.NEXT_LEVEL;
    self.reset_level();
    return;
  }

  self.game_loop();
}

fn void Gameplay.game_loop(&self) {
  if(self.eaten_dots >= 244) {
    self.flags |= GameplayState.NEXT_LEVEL;
    return;
  }
  
  if(self.timer.new_cycle() && !(self.flags & GameplayState.FRIGHTEN_MODE)) {
    self.flags ^= GameplayState.CHASE_MODE;
      
    self.timer.cycle = 0.f;
    self.timer.which_cycle++;
    
    io::print("New cycle: ");
    self.flags & GameplayState.CHASE_MODE
      ? io::printn("Chase Mode")
      : io::printn("Scatter Mode");
  }
 
  if(self.timer.end_frighten_mode((bool)(self.flags & GameplayState.FRIGHTEN_MODE))) {
    self.flags ^= GameplayState.FRIGHTEN_MODE;
    self.timer.frighten_mode = 0.f;
    
    self.eaten_ghosts = 0;
    foreach(&ghost : self.ghosts) { ghost.state_flags &= (Uint8)~GhostState.FRIGHTEN.state; }
    
    io::printn("Frighten Mode disabled");
  }

  // 2. PacMan interaction
  self.pacman.move(&self.maze.tiles);

  bool dot_eaten = false;
  EventType e = self.maze.update(&self.pacman);
  if(e == ENERGIZE_EATEN) {
    dot_eaten = true;
    self.eaten_dots++;
    self.ui.score += 50;
    
    // All ghosts turn 180 degrees upon the begging of the frighten mode
    self.flags |= GameplayState.FRIGHTEN_MODE;
    foreach(&ghost : self.ghosts) {
      if(~ghost.state_flags & GhostState.IN_SPAWN && ~ghost.state_flags & GhostState.DEAD) {
	ghost.state_flags |= GhostState.FRIGHTEN;
	ghost.turn_180();
      }
    }
    
    io::printn("Frighten Mode enabled");
  }

  fruit_handler(&self.fruit, &self.score_popup, self);

  if(e == SCORE_INCREASE) {
    dot_eaten = true;
    self.eaten_dots++;
    self.ui.score += 10;
    
    if(self.flags & GameplayState.USE_GLOBAL_COUNTER) { self.global_ghosts_dot_counter++; }
  }

  foreach(idx, &ghost : self.ghosts) {
    if(dot_eaten && idx != GhostType.BLINKY) ghost::increase_counter((Uint8)idx, &ghost.dot_counter, self.timer.level);
    
    if(ghost::spawn_handler((Uint8)idx, ghost, self, dot_eaten)) continue;
    
    Ghost *other_ghost = null;
    if(idx == GhostType.INKY) { other_ghost = &self.ghosts[0]; }
    else if(idx == GhostType.CLYDE) { other_ghost = &self.ghosts[3]; }

    ghost.move(&self.maze.tiles, ghost.get_target(&self.pacman, other_ghost), self.flags);
  
    if(ghost.collision(self.pacman.pos)) {
      if(ghost.state_flags & GhostState.FRIGHTEN) {
	self.eaten_ghosts += 1;
	score_popup::handler(&self.score_popup, ghost.pos, self.eaten_ghosts, 0, PopupState.INIT, EventType.GHOST_EATEN);

	ghost.turn_180();
	ghost.state_flags ^= GhostState.FRIGHTEN;
	ghost.state_flags |= GhostState.DEAD;
	
	self.flags |= GameplayState.GHOST_EATEN;
	continue;
      }

      self.flags |= GameplayState.PACMAN_DIED;
      self.flags |= GameplayState.RESET_LEVEL;
      return;
    }
  }  
}

fn void Gameplay.draw(&self, TimeSpan pause) {
  if(self.flags & GameplayState.START_LEVEL) {
    self.maze.draw(dt: 0, finished_level: false);
    
    draw_ready_player_text(&self.ui.font, pause);
      
    if(pause > 1.f) {
      foreach(i, &ghost : self.ghosts) self.ghosts[i].draw(ghost::GhostType.values[i], dt: 0);
    }
      
    self.pacman.draw(dt: 0);
    return;
  }

  if(self.flags & GameplayState.GHOST_EATEN) {
    self.maze.draw(dt: 0, finished_level: false);
      
    if(self.fruit != null) self.fruit.draw();

    foreach(i, &ghost : self.ghosts) self.ghosts[i].draw(ghost::GhostType.values[i], dt: 0);
    self.pacman.draw(dt: 0);
      
    self.ui.draw_ui(self.pacman.lives);
      
    if(self.score_popup == null) return;
    self.score_popup.can_drawn(self.timer.dt)
      ? self.score_popup.draw()
      : score_popup::handler(&self.score_popup, {0, 0}, 0, 0, PopupState.DESTROY, EventType.NONE);
    return;
  }

  if(self.flags & GameplayState.RESET_LEVEL) { // aka PacMan died
    self.maze.draw(dt: 0, finished_level: false);
      
    if(self.fruit != null) self.fruit.draw();

    if(pause < 1.f) {
      foreach(i, &ghost : self.ghosts) self.ghosts[i].draw(ghost::GhostType.values[i], dt: 0);
      self.pacman.draw(0, dead: false);
    } else {
      self.pacman.draw(self.timer.dt, dead: true);
    }
      
    self.ui.draw_ui(self.pacman.lives);      
    return;
  }

  // TODO: Add flashing maze
  if(self.flags & GameplayState.NEXT_LEVEL) {
    if(self.fruit != null) self.fruit.draw();
    
    if(pause < 1.f) {
      self.maze.draw(dt: 0, finished_level: false);
      foreach(i, &ghost : self.ghosts) self.ghosts[i].draw(ghost::GhostType.values[i], dt: 0);
    } else {
      self.maze.draw(self.timer.dt, finished_level: true);
    }

    self.pacman.draw(dt: 0);
    return;
  }

  // Game loop draw
  self.maze.draw(self.timer.dt, finished_level: false, flash: true);
      
  if(self.fruit != null) self.fruit.draw();
      
  foreach(i, &ghost : self.ghosts) self.ghosts[i].draw(ghost::GhostType.values[i], self.timer.dt);
      
  self.pacman.draw(self.timer.dt);
      
  self.ui.draw_ui(self.pacman.lives);
      
  if(self.score_popup == null) return;
  self.score_popup.can_drawn(self.timer.dt)
    ? self.score_popup.draw()
    : score_popup::handler(&self.score_popup, {0, 0}, 0, 0, PopupState.DESTROY, EventType.NONE);    
}

fn void Gameplay.clean(&self) {
  self.ui.free();
  self.maze.free();

  if(self.score_popup != null) score_popup::handler(&self.score_popup, {0, 0}, 0, 0, PopupState.DESTROY, EventType.NONE);
  if(self.fruit != null) {
    self.fruit.free();
    free(self.fruit);
  }
}

//============================================================================================
// Helper functions
//============================================================================================

<*
 @param [inout] fruit : "Fruit was passed as null!"
 @param [inout] score_popup : "Score Popup was passed as null!"
 @param [&in] ctx : "Game Context was passed as null!"
*>
fn void fruit_handler(Fruit **fruit, ScorePopup **score_popup, Gameplay *ctx) {
  if((ctx.eaten_dots == 70 || ctx.eaten_dots == 170) && (*fruit) == null) {
    io::printn("Fruit appeared");
    *fruit = mem::new(Fruit);
    (*fruit).init(ctx.timer.level)!!;
  }
  
  if((*fruit) != null) {
    (*fruit).elapsed_time += ctx.timer.dt;

    if((*fruit).elapsed_time > 9.5f) {
      io::printn("Fruit dissapeared");
      
      rl::unload_texture((*fruit).texture);
      free((*fruit));
      (*fruit) = null;
      return;
    }

    if((*fruit).collision(ctx.pacman.pos)) {
      score_popup::handler(score_popup, (*fruit).pos, 0, (*fruit).points, PopupState.INIT, EventType.FRUIT_EATEN);
      
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
  const CHAR_SIZE = 32;
  const DRAW_FONT_SIZE = 40;
    
  rl::draw_text_ex(*font,
		   "Ready!",
		   { (Uint16)(gl::MAZE_WIDTH / 2 * gl::PIXEL_SCALED - 3 * CHAR_SIZE) + 10, 20 * gl::PIXEL_SCALED - 5 },
		   DRAW_FONT_SIZE, 0.f,
		   (Color){255, 255, 0, 255}
  );

  if(pause < 1.f) {
    rl::draw_text_ex(*font,
		     "Player One!",
		     { (Uint16)(gl::MAZE_WIDTH / 2 * gl::PIXEL_SCALED - 5 * CHAR_SIZE - 22) + 10, 14 * gl::PIXEL_SCALED - 5 },
		     DRAW_FONT_SIZE, 0.f,
		     (Color){0, 255, 255, 255}
    );
  }
}
