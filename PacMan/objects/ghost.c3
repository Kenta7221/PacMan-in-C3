module ghost;

import std::io;

import gl;
import rl;

import animator;
import maze;
import pacman;
import game_ctx::gameplay;

const SPAWN_SPEED = 0.02f;
const FRIGHTEN_SPEED = 0.07f;
const NORMAL_SPEED = 0.13f;

enum GhostType : inline Uint8 {
  BLINKY,
  PINKY,
  INKY,
  CLYDE
}

enum GhostState : Uint8 (inline Uint8 state) {
  IN_SPAWN             = 1 << 0,
  ENTERING_SPAWN       = 1 << 1,
  LEAVING_SPAWN        = 1 << 2,
  FRIGHTEN             = 1 << 3,
  DEAD                 = 1 << 4,
}

alias TargetCallback = fn Int16[<2>](PacMan *pacman, Ghost *other = null);

struct Ghost {
  Int16[<2>] pos;
  Uint8 dir;
  TimeSpan lerp_amount;
  
  // Bit layout:
  // Bit 4 - dead
  // Bit 3 - frighten mode
  // Bit 2 - leaving spawn
  // Bit 1 - entering spawn
  // Bit 0 - in spawn
  Uint8 state_flags;
  Uint8 dot_counter;
  
  TargetCallback get_target;
  Int16[<2>] scatter_tile;
  
  Animator animation;
}

fn void Ghost.init(&self, Uint8 ghost_type = 0, Texture2D *atlas_ptr) {
  const Int16[<2>][4] FIXED_TILES_POS = {
    {  25 * gl::TILE_SCALED                        , 0 }, // Blinky
    {  2 * gl::TILE_SCALED                         , 0 }, // Pinky
    { (gl::MAZE_WIDTH - 1) * gl::TILE_SCALED       , (gl::TOP_UI_SIZE + gl::MAZE_HEIGHT) * gl::TILE_SCALED  }, // Inky
    {  0                                            , (gl::TOP_UI_SIZE + gl::MAZE_HEIGHT) * gl::TILE_SCALED  }, // Clyde
  };

  const TargetCallback[4] CALLBACK = { &blinky_target, &pinky_target, &inky_target, &clyde_target };
  
  self.animation.init(atlas_ptr, 0, 2, 0.15f);
  
  self.set_at_start_pos(ghost_type);
  
  self.scatter_tile = FIXED_TILES_POS[ghost_type];
  self.get_target = CALLBACK[ghost_type];
}

fn void Ghost.set_at_start_pos(&self, Uint8 ghost_type = 0) {
  const Int16[<2>][4] START_POS = {
    { 13 * gl::TILE_SCALED + gl::TILE_SCALED / 2, 14 * gl::TILE_SCALED }, // Blinky
    { 13 * gl::TILE_SCALED + gl::TILE_SCALED / 2, 17 * gl::TILE_SCALED }, // Pinky
    { 11 * gl::TILE_SCALED + gl::TILE_SCALED / 2, 17 * gl::TILE_SCALED }, // Inky
    { 15 * gl::TILE_SCALED + gl::TILE_SCALED / 2, 17 * gl::TILE_SCALED }, // Clyde
  };

  self.pos = START_POS[ghost_type];
  self.lerp_amount = 0.0f;
  
  switch(ghost_type) {
    case GhostType.BLINKY: self.dir = Direction.LEFT; break;
    case GhostType.INKY:
    case GhostType.CLYDE:  self.dir = Direction.UP;   break;
    case GhostType.PINKY:  self.dir = Direction.DOWN; break;
  }

  self.dot_counter = 0;
  
  self.state_flags = 0;
  if(ghost_type != GhostType.BLINKY) self.state_flags |= GhostState.IN_SPAWN;
}

fn bool Ghost.collision(&self, Int16[<2>] pacman_pos) {
  Int8[<2>] pacman_tile = (Int8[<2>])(pacman_pos / gl::TILE_SCALED);
  Int8[<2>] ghost_tile = (Int8[<2>])(self.pos / gl::TILE_SCALED);

  return ghost_tile == pacman_tile;
}


fn void Ghost.turn_180(&self) {
  Uint8 potential_dir = Direction.NONE;
  
  switch(self.dir) {
    case Direction.UP		:  potential_dir = Direction.DOWN;  break;
    case Direction.LEFT		:  potential_dir = Direction.RIGHT; break;
    case Direction.RIGHT	:  potential_dir = Direction.LEFT;  break;
    case Direction.DOWN		:  potential_dir = Direction.UP;    break;
    default			:  potential_dir = Direction.NONE;  break;
  }

  self.dir = potential_dir;
}

<*
 @param [&in] tiles
*>
fn void Ghost.roam_in_spawn(&self, Tile *tiles) {
  Int16 start_y;
  Int16 end_y;

  if(self.lerp_amount > 1.f) self.lerp_amount = 0.0f;
  self.lerp_amount += SPAWN_SPEED;
  
  if(self.pos.y == 16 * gl::TILE_SCALED + gl::TILE_SCALED / 2 && self.dir == Direction.UP) {
    self.dir = Direction.DOWN;
    self.lerp_amount = SPAWN_SPEED;
  } else if(self.pos.y == 18 * gl::TILE_SCALED - gl::TILE_SCALED / 2 && self.dir == Direction.DOWN) {
    self.dir = Direction.UP;
    self.lerp_amount = SPAWN_SPEED;
  }
    
  if(self.dir == Direction.UP) {
    start_y = 18 * gl::TILE_SCALED - gl::TILE_SCALED / 2;
    end_y = 16 * gl::TILE_SCALED + gl::TILE_SCALED / 2;
  } else if(self.dir == Direction.DOWN) {
    start_y =  16 * gl::TILE_SCALED + gl::TILE_SCALED / 2;
    end_y = 18 * gl::TILE_SCALED - gl::TILE_SCALED / 2;;
  }
  
  self.pos = gl::tween_pos_by_tiles(
    {
      self.pos.x,
      start_y
    },
    {
      self.pos.x,
      end_y
    },				 
    self.lerp_amount
  );
}

<*
 @param [&in] tiles
*>
fn void Ghost.return_to_spawn(&self, Tile *tiles) {
  const Int16[<2>] EXIT = {
    13 * gl::TILE_SCALED + gl::TILE_SCALED / 2,
    14 * gl::TILE_SCALED
  };
  
  const Int16[<2>] CENTER = {
    13 * gl::TILE_SCALED + gl::TILE_SCALED / 2,
    17 * gl::TILE_SCALED,
  };

  bool update = true;
  
  defer {
    if(update) {
      if(self.lerp_amount >= 1.f || gl::is_aligned(self.pos)) self.lerp_amount = 0.0f;  
    
      if(self.state_flags & GhostState.ENTERING_SPAWN) {
	self.lerp_amount += SPAWN_SPEED;
	self.pos = gl::tween_pos_by_tiles(EXIT, CENTER, self.lerp_amount);
      } else {
	self.lerp_amount += NORMAL_SPEED;
	self.pos = gl::tween_pos_by_dir(self.pos, self.dir, self.lerp_amount);
      }
    
      gl::handle_tunnel_wrap(&self.pos);
    }
  }

  // Entering Spawn
  Int16 overshoot = EXIT.x - self.pos.x;
  if(overshoot >= -(gl::TILE_SCALED / 2) && overshoot <= gl::TILE_SCALED / 2 && self.pos.y == EXIT.y) {
    self.state_flags |= GhostState.ENTERING_SPAWN;
    self.pos.x = EXIT.x;
  }
  
  if(self.state_flags & GhostState.ENTERING_SPAWN) {
    self.dir = Direction.DOWN;
    
    if(self.pos.y == CENTER.y) {
      self.lerp_amount = 0.f;
      self.state_flags |= GhostState.IN_SPAWN;
      self.state_flags ^= GhostState.DEAD;
      self.state_flags ^= GhostState.ENTERING_SPAWN;
      update = false;
      return;
    }
    
    return;
  }

  // Finding path to spawn
  if(!gl::is_aligned(self.pos)) return;
  
  Uint8 best_dir = self.dir;
  Uint16 min_dist = ushort.max;
  for(int i = 1; i < Direction.values.len; i++) {
    Uint8 potential_dir = gl::Direction.values[i];

    if(!is_valid_move(tiles, self.pos, self.dir, potential_dir)) continue;
    
    Int16[<2>] next_pos = gl::get_tile_offset(self.pos, potential_dir);
    Uint16 dist = sqrt_dist(next_pos / gl::TILE_SCALED, CENTER / gl::TILE_SCALED);
    if(dist < min_dist) {
      min_dist = dist;
      best_dir = potential_dir;
    }
  }
  
  self.dir = best_dir;
}

<*
 Operation of ghost leaving a spawn:
 1) Make a ghost y pos be centered
 2) Force him to go left or right to the pos of CENTER_X
 3) Force him to go up to the pos of EXIT_Y
 4) If he leaves spawn change dir to left or right
 @param [&in] tiles : "Tiles was passed as null!"
 @param [&inout] rng_index "Rng index was passed as null!"
*>
fn void Ghost.leave_spawn(&self, Tile *tiles, Uint16* rng_index) {
  const CENTER_X = 13 * gl::TILE_SCALED + gl::TILE_SCALED / 2;
  const CENTER_Y = 17 * gl::TILE_SCALED;
  const EXIT_Y  =  14 * gl::TILE_SCALED;
  
  Int16[<2>] start, end;
  defer {
    if(self.lerp_amount >= 1.f) self.lerp_amount = 0.0f;
    self.lerp_amount += SPAWN_SPEED;
    self.pos = gl::tween_pos_by_tiles(start, end, self.lerp_amount);
  }
  
  if(self.pos.y == EXIT_Y) {
    *rng_index = (5 * *rng_index + 1) % 8192;
    self.dir = get_rnd_dir(&self.pos, &self.dir, tiles, *rng_index);
    
    self.state_flags &= (Uint8)~GhostState.IN_SPAWN.state;
    self.state_flags &= (Uint8)~GhostState.LEAVING_SPAWN.state;

    // Make no decision on moving
    start = {CENTER_X, EXIT_Y};
    end   = {CENTER_X, EXIT_Y};
    return;
  }

  if(self.pos.x == CENTER_X) {
    // Because of floating point error after Clyde or Inky gets to the CENTER_X
    // their lerp amount won't count as being equal or greater they will be teleported
    // to the EXIT_Y. Therefore we reset everyones lerp if they are at the center of spawn
    if(self.pos.y == CENTER_Y && self.pos.x == CENTER_X) self.lerp_amount = 0.0f;
    
    self.dir = Direction.UP;
    start = {CENTER_X, CENTER_Y};
    end   = {CENTER_X, EXIT_Y};
    return;
  }
  
  // Just teleport ghost to the y center
  if(self.pos.y != CENTER_Y) {
    self.lerp_amount = 0.f;
    start = { self.pos.x, CENTER_Y };
    end   = { self.pos.x, CENTER_Y };
    return;
  }
  
  if(self.pos.x < CENTER_X) {
    self.dir = Direction.RIGHT;
    start = { 11 * gl::TILE_SCALED + gl::TILE_SCALED / 2, CENTER_Y };
    end   = { CENTER_X                                    , CENTER_Y };
    return;
  }

  if(self.pos.x > CENTER_X) {
    self.dir = Direction.LEFT;
    start = { 15 * gl::TILE_SCALED + gl::TILE_SCALED / 2, CENTER_Y };
    end   = { CENTER_X                                    , CENTER_Y };
    return;
  }
}

<*
 @param [&in] tiles : "Tiles was passed as null!"
 @param [&inout] rng_index "Rng index was passed as null!"
*>
fn void Ghost.move(&self, Tile *tiles, Int16[<2>] pacman_pos, Uint8 global_state, Uint16* rng_index) {
  defer {
    if(gl::is_aligned(self.pos) || self.lerp_amount >= 1.f) self.lerp_amount = 0.0f;

    if(self.state_flags & GhostState.FRIGHTEN ){ self.lerp_amount += FRIGHTEN_SPEED; }
    else { self.lerp_amount += NORMAL_SPEED; }

    self.pos = gl::tween_pos_by_dir(self.pos, self.dir, self.lerp_amount);
  }
  
  if(!gl::is_aligned(self.pos) && self.dir != Direction.NONE) return;

  if(gl::in_tunnel((Int8[<2>])(self.pos / gl::TILE_SCALED))) {
    gl::handle_tunnel_wrap(&self.pos);
    return;
  }
  
  if(self.state_flags & GhostState.FRIGHTEN) {
    *rng_index = (5 * *rng_index + 1) % 8192;
    self.dir = get_rnd_dir(&self.pos, &self.dir, tiles, *rng_index);
    return;
  }

  Int16[<2>] target_pos;
  if(global_state & GameplayState.CHASE_MODE) { target_pos = pacman_pos; }
  else { target_pos = self.scatter_tile; }
    
  bool tunnel_penalty;
  Uint8 best_dir = self.dir;
  Uint16 min_dist = ushort.max;
  for(int i = 1; i < Direction.values.len; i++) {
    Uint8 potential_dir = gl::Direction.values[i];
    
    if(!is_valid_move(tiles, self.pos, self.dir, potential_dir)) continue;
    
    Int16[<2>] next_pos = gl::get_tile_offset(self.pos, potential_dir);
    Uint16 dist = sqrt_dist(next_pos / gl::TILE_SCALED, target_pos / gl::TILE_SCALED);
    if(dist < min_dist) {
      min_dist = dist;
      best_dir = potential_dir;
    }
  }
  
  self.dir = best_dir;
}

fn void Ghost.draw(&self, Uint8 ghost_type, TimeSpan dt) {
  Uint8 row;

  if(self.state_flags & GhostState.FRIGHTEN) {
    row = 8;
    self.animation.update_count(0, 4);
  }
  else{
    if(self.state_flags & GhostState.DEAD) { row = 7; }
    else { row = ghost_type + 3; }
  
    switch(self.dir) {
      case Direction.UP		: self.animation.update_count(6, 8); break;
      case Direction.LEFT	: self.animation.update_count(4, 6); break;
      case Direction.RIGHT	: self.animation.update_count(0, 2); break;
      case Direction.DOWN	: self.animation.update_count(2, 4); break;
      default			: break;
    }
  }

  Rectangle src = self.animation.get_src(row, dt);
  
  Rectangle dest = {
    (float)self.pos.x - gl::SPRITE_SIZE_SCALED / 4,
    (float)self.pos.y - gl::SPRITE_SIZE_SCALED / 4,
    gl::SPRITE_SIZE_SCALED,
    gl::SPRITE_SIZE_SCALED,
  };
            
  rl::draw_texture_pro(*self.animation.atlas_ptr, src, dest, (float[<2>]){0, 0}, 0, (Color){255, 255, 255, 255});
}

fn Uint16 sqrt_dist(Int16[<2>] a, Int16[<2>] b) @private {
  Uint16 dx = a.x - b.x;
  Uint16 dy = a.y - b.y;
  return dx * dx + dy * dy;
}

fn bool inside_spawn(Int16[<2>] pos, Uint8 state_flags) {
  // Calculating for the center of ghost
  pos.y -= (Int8)gl::TILE_SCALED;
  
  const Uint16[<4>] SPAWN_AREA = {
    11 * gl::TILE_SCALED,  // x pos
    16 * gl::TILE_SCALED,  // width
    12 * gl::TILE_SCALED,  // y pos
    28 * gl::TILE_SCALED,  // height
  };
  
  return pos.x >= SPAWN_AREA.x &&
         pos.x <= SPAWN_AREA.y &&
         pos.y >= SPAWN_AREA.z && 
         pos.y <= SPAWN_AREA.w &&
        (state_flags & GhostState.IN_SPAWN) == GhostState.IN_SPAWN;
}

fn bool in_spawn_penalty(Int8[<2>] pos) @private {
  const Int8[<3>]GHOST_SPAWN_ENTRANCE = {
    11,  // x pos
    15,  // width
    14   // y pos
  };

  const Int8[<3>]PACMAN_SPAWN = {
    11,  // x pos
    16,  // width
    26   // y pos
  };
  
  bool in_ghost_spawn =
    pos.x >= GHOST_SPAWN_ENTRANCE.x &&
    pos.x <= GHOST_SPAWN_ENTRANCE.y &&
    pos.y == GHOST_SPAWN_ENTRANCE.z;
  
  bool in_pacman_spawn =
    pos.x >= PACMAN_SPAWN.x &&
    pos.x <= PACMAN_SPAWN.y &&
    pos.y == PACMAN_SPAWN.z;

  return in_pacman_spawn || in_ghost_spawn;
}

<*
 @param [&in] tiles
*>
fn bool is_valid_move(Tile *tiles,
		      Int16[<2>] pos,
		      Uint8 curr_dir,
		      Uint8 potential_dir,
		      bool frighten_mode = false,
		      bool dead = false) {
  if(gl::is_reverse_dir(curr_dir, potential_dir)) return false;
  
  Int16[<2>] next_pos = gl::get_tile_offset(pos, potential_dir);
  Tile next_tile = maze::get_tile_at(tiles, next_pos);
  
  if(next_tile.type == WALL) return false;

  if(in_spawn_penalty((Int8[<2>])(pos / gl::TILE_SCALED)) && !dead) {
    // Ghost in frighten mode temporarly can move up in these zones
    if(frighten_mode && potential_dir == Direction.DOWN) return false;
    if(!frighten_mode && (potential_dir == Direction.DOWN || potential_dir == Direction.UP)) return false;
  }
  
  return true;
}

fn bool should_leave_spawn(int ghost_type,
			   bool exceeds_dot_not_eaten_dur,
			   Uint8 ghost_counter,
			   Uint8 ghost_state_flags,
			   bool use_global_counter,
			   Uint8 global_counter,
			   uint level) {
  const Uint8[2][3] GHOSTS_DOT_COUNTER = {
    { 0,  0  },  // Pinky
    { 30, 0  }, // Inky
    { 60, 50 }  // Clyde
  };

  const Uint8[3] GLOBAL_DOT_COUNTER = {
    7,  // Pinky
    5,  // Inky
    32  // Clyde
  };

  if(ghost_type == GhostType.BLINKY) return true;
  
  if(ghost_state_flags & GhostState.LEAVING_SPAWN) return true;
  
  if(exceeds_dot_not_eaten_dur) return true;

  if(use_global_counter) return global_counter >= GLOBAL_DOT_COUNTER[ghost_type - 1];

  // All ghosts dot counter is zero after level 2 therefore all ghost can leave spawn
  if(level > 2) return true;
  
  if(level < 2) return ghost_counter >= GHOSTS_DOT_COUNTER[ghost_type - 1][0];
  
  return ghost_counter >= GHOSTS_DOT_COUNTER[ghost_type - 1][1];
}

fn void increase_counter(Uint8 curr_ghost, Uint8 *counter, int level) {
  const Uint8[2][3] DOTS_COUNTER = {
    { 0 ,  0 },  // Pinky
    { 30,  0 },  // Inky
    { 60, 50 }   // Clyde
  };
  
  if(level < 2 && *counter < DOTS_COUNTER[curr_ghost - 1][0]) {
    *counter += 1;
    return;
  }

  if(*counter < DOTS_COUNTER[curr_ghost - 1][1]) *counter += 1;
}

<*
 @param [&in] pos : "Pos passed as null!"
 @param [&in] dir : "Dir passed as null!"
 @param [&in] tiles : "Maze tiles passed as null!"
*>
fn Uint8 get_rnd_dir(Int16[<2>] *pos, Uint8 *dir, Tile *tiles, Uint16 rng_index) {
  Uint8 rng_output;
  
  if(rng_index <= 2064)                           { rng_output = 3; }
  else if(rng_index >= 2064 && rng_index <= 4402) { rng_output = 2; }
  else if(rng_index <= 6854)                      { rng_output = 1; }
  else                                            { rng_output = 0; }
  
  for(Uint8 i = rng_output; i < rng_output + 4; i++) {
    Uint8 potential_dir = Direction.values[i % 4 + 1]; // +1 for skipping none direction
    if(is_valid_move(tiles, *pos, *dir, potential_dir, frighten_mode: true)) return potential_dir;
  }

  // Never  will be called because for loop tests all directions
  return *dir;
}

<*
 @param [&inout] ghost : "ghost passed as null!"
 @param [&in] ctx : "game context passed as null!"
*>
fn bool spawn_handler(Uint8 ghost_type, Ghost *ghost, Gameplay *ctx, bool dot_eaten){
  static bool prev_ghost_leaves_spawn = false;
  
  if(ghost.state_flags & GhostState.DEAD) {
    ghost.return_to_spawn(&ctx.maze.tiles);
    return true;
  }

  bool exceeds_time = ctx.timer.exceeds_dot_not_eaten_dur(dot_eaten);
  if(!inside_spawn(ghost.pos, ghost.state_flags)) {
    prev_ghost_leaves_spawn = true;
    return false;
  }
  
  if(should_leave_spawn(ghost_type,
			exceeds_time,
			ghost.dot_counter,
			ghost.state_flags,
			(bool)(ctx.flags & GameplayState.USE_GLOBAL_COUNTER),
			ctx.global_ghosts_dot_counter,
			ctx.timer.level) && prev_ghost_leaves_spawn || ghost_type == GhostType.BLINKY
  ) {
      
    if(exceeds_time) ctx.timer.reset_dot_not_eaten();
      
    prev_ghost_leaves_spawn = true;
    ghost.state_flags |= GhostState.LEAVING_SPAWN;
    ghost.leave_spawn(&ctx.maze.tiles, &ctx.rng_index);
    return true;
  }

  prev_ghost_leaves_spawn = false;
  ghost.roam_in_spawn(&ctx.maze.tiles);
  return true;
}

<*
 @param [&in] pacman
*>
fn Int16[<2>] blinky_target(PacMan *pacman, Ghost *other = null) {  
  Int16[<2>] pacman_tile = {
    pacman.pos.x / gl::TILE_SCALED,
    pacman.pos.y / gl::TILE_SCALED
  };
  
  return (Int16[<2>]){
    pacman_tile.x * gl::TILE_SCALED,
    pacman_tile.y * gl::TILE_SCALED
  };
}

<*
 @param [&in] pacman
*>
fn Int16[<2>] pinky_target(PacMan *pacman, Ghost *other = null) {
  const char STEP_AHEAD = 4;
  
  Int16[<2>] pacman_tile = {
    pacman.pos.x / gl::TILE_SCALED,
    pacman.pos.y / gl::TILE_SCALED
  };

  char dir = pacman.dirs & 0x0F;
  switch(dir) {
    // Quirk of PacMan's code (link to it in README)
    case Direction.UP:
      pacman_tile.x -= STEP_AHEAD;
      pacman_tile.y -= STEP_AHEAD;
      break;
    case Direction.LEFT:
      pacman_tile.x -= STEP_AHEAD;
      break;
    case Direction.RIGHT:
      pacman_tile.x += STEP_AHEAD;
      break;
    case Direction.DOWN:
      pacman_tile.y += STEP_AHEAD;
      break;
    default:
      break;
  }

  return (Int16[<2>]){
    pacman_tile.x * gl::TILE_SCALED,
    pacman_tile.y * gl::TILE_SCALED
  };
}

<*
 @param [&in] pacman
 @param [&in] blinky
*>
fn Int16[<2>] inky_target(PacMan *pacman, Ghost *blinky) {
  const char STEP_AHEAD = 2;

  Int16[<2>] pacman_tile = {
    pacman.pos.x / gl::TILE_SCALED,
    pacman.pos.y / gl::TILE_SCALED
  };

  char dir = pacman.dirs & 0x0F;
  switch(dir) {
    // Quirk of PacMan's code (link to it in README)
    case Direction.UP:
      pacman_tile.x -= STEP_AHEAD;
      pacman_tile.y -= STEP_AHEAD;
      break;
    case Direction.LEFT:
      pacman_tile.x -= STEP_AHEAD;
      break;
    case Direction.RIGHT:
      pacman_tile.x += STEP_AHEAD;
      break;
    case Direction.DOWN:
      pacman_tile.y += STEP_AHEAD;
      break;
    default:
      break;
  }

  Int16[<2>] blinky_tile = {
    blinky.pos.x / gl::TILE_SCALED,
    blinky.pos.y / gl::TILE_SCALED
  };
  
  Int16[<2>] target_pos = {
    (2 * (pacman_tile.x - blinky_tile.x) + blinky_tile.x) * gl::TILE_SCALED,
    (2 * (pacman_tile.y - blinky_tile.y) + blinky_tile.y) * gl::TILE_SCALED
  };
  
  return target_pos;
}

<*
 @param [&in] pacman
 @param [&in] clyde
*>
fn Int16[<2>] clyde_target(PacMan *pacman, Ghost *clyde) {
  const int RADIUS = 8 * 8;
  const Int16[<2>] CLYDE_TARGET_POS = {
    0,
    (gl::TOP_UI_SIZE + gl::MAZE_HEIGHT) * gl::TILE_SCALED
  };
  
  Int8[<2>] pacman_tile = {
    (Int8)(pacman.pos.x / gl::TILE_SCALED),
    (Int8)(pacman.pos.y / gl::TILE_SCALED)
  };

  Int8[<2>] clyde_tile = {
    (Int8)(clyde.pos.x / gl::TILE_SCALED),
    (Int8)(clyde.pos.y / gl::TILE_SCALED)
  };
  
  int dist = sqrt_dist(pacman_tile, clyde_tile);
  if(dist > RADIUS) {
    return {
      pacman_tile.x * gl::TILE_SCALED,
      pacman_tile.y * gl::TILE_SCALED
    };
  }
  
  return CLYDE_TARGET_POS;
}
