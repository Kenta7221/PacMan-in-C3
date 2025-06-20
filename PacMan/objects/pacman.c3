module pacman;

import std::io;
import std::math;

import gl;
import rl;
import animator;
import maze;

const CURR_DIR_MASK @private = 0x0F;
const TURN_DIR_MASK @private = 0xF0;

enum PacManState : Uint8 (inline Uint8 state) {
  DEAD                 = 1 << 1,
  TURN_180             = 1 << 0
}

struct PacMan (AnimatorHandler) {
  Int16[<2>] pos;
  Uint8 lives;  
  TimeSpan lerp_amount;
  
  // Bit layout:
  // Bit 4-7 - early turn
  // Bit 3-0 - curr dir
  Uint8 dirs;

  // Bit 1 - Dead
  // Bit 0 - Can turn 180
  Uint8 state_flags;
  
  Texture2D texture;
  Animator animation;
}

fn void? PacMan.init(&self) {
  const String ATLAS_FILENAME = "assets/textures/pacman.png";

  self.texture = rl::load_texture(ATLAS_FILENAME);
  if(!rl::is_texture_valid(self.texture)) {
    io::printn("PacMan texture was not loaded!");
    return io::FILE_NOT_FOUND?;
  }
 
  self.set_at_start_pos();
  self.lives = 3;
  self.state_flags = 0;  

  self.animation.init(&self.texture, 0, 12, 0.08f);

  self.lerp_amount = 0.0f;
}

fn void PacMan.set_at_start_pos(&self) {
  const Int16[<2>] BASE_POS = {
    13 * gl::TILE_SCALED + (gl::TILE_SCALED / 2),
    26 * gl::TILE_SCALED
  };

  self.pos = BASE_POS;
  self.state_flags = 0;
  
  self.dirs = (Direction.NONE.type << 4) | (Direction.NONE.type);

  self.update_animation(dt: 0);
}

<*
 @param [&in] tiles : "Tiles was passed as null"
*>
fn void PacMan.move(&self, Tile *tiles, TimeSpan dt, float speed) {  
  Uint8 input_dir = Direction.NONE;
  Int16[<2>] next_pos;
  Tile next_tile;

  defer {
    if(!(self.state_flags & PacManState.TURN_180)) {
      if(gl::is_aligned(self.pos) || self.lerp_amount >= 1.f) self.lerp_amount = 0.0f;
      self.lerp_amount += 1 - math::exp(-speed * dt);

      self.pos = gl::tween_pos_by_dir(self.pos, self.dirs & CURR_DIR_MASK, self.lerp_amount);
    }
  }
  
  if((self.dirs & CURR_DIR_MASK) == Direction.NONE) self.lerp_amount = 0.5f;
  
  if(gl::in_tunnel((Int8[<2>])(self.pos / gl::TILE_SCALED))) {
    gl::handle_tunnel_wrap(&self.pos);
    return;
  }

  // Change input_dir if user did a early_turn
  if((self.dirs & TURN_DIR_MASK) != TURN_DIR_MASK) input_dir = (self.dirs & TURN_DIR_MASK) >> 4;
  
  if(rl::is_key_down(rl::KEY_W))      { input_dir = Direction.UP;    }
  else if(rl::is_key_down(rl::KEY_A)) { input_dir = Direction.LEFT;  }
  else if(rl::is_key_down(rl::KEY_D)) { input_dir = Direction.RIGHT; }
  else if(rl::is_key_down(rl::KEY_S)) { input_dir = Direction.DOWN;  }
  
  // PacMan is forbiden from turning 180 deg while moving
  if(input_dir != Direction.NONE && !gl::is_reverse_dir(self.dirs, input_dir) ||
     self.state_flags & PacManState.TURN_180 && input_dir != Direction.NONE) {
    next_pos = gl::get_tile_offset(self.pos, input_dir);
    next_tile = maze::get_tile_at(tiles, next_pos);
 
    if((gl::is_aligned(self.pos) || (self.dirs & CURR_DIR_MASK) == Direction.NONE) && next_tile.type != WALL) {
      self.dirs = Direction.NONE.type << 4; // Reset it in case it was a pre turn
      self.dirs = (self.dirs & TURN_DIR_MASK) | (input_dir & CURR_DIR_MASK);
    }
    
    if(is_early_turn(tiles, self.pos, self.dirs, input_dir)) {
      self.dirs = (self.dirs & CURR_DIR_MASK) | (input_dir << 4);
    }
  }
  
  next_pos = gl::get_tile_offset(self.pos, self.dirs);
  next_tile = maze::get_tile_at(tiles, next_pos);
  if(next_tile.type == WALL) {
    self.state_flags = PacManState.TURN_180;
    return;
  }

  if(self.state_flags & PacManState.TURN_180) self.state_flags ^= PacManState.TURN_180;
}

fn void PacMan.update_animation(&self, TimeSpan dt) @dynamic {
  Uint8 row = 0;
  Uint8 flip = 0;

  defer self.animation.update_frame(row, dt, flip);
  
  if(self.state_flags & PacManState.DEAD) {
    row = 3;
    return;
  }
  
  if(self.dirs & CURR_DIR_MASK == Direction.NONE || self.state_flags & PacManState.TURN_180) {
    row = 0;
    return;
  }
  
  switch(self.dirs & CURR_DIR_MASK) {
    case Direction.UP		: row = 2; flip = animator::FLIP_VERTICALLY;   break;
    case Direction.LEFT	        : row = 1; flip = animator::FLIP_HORIZONTALLY; break;
    case Direction.RIGHT	: row = 1;                                     break;
    case Direction.DOWN	        : row = 2;                                     break;
    default			: break;
  }
}

<*
 @param [&in] tiles : "Tiles was passed as null"
*>
fn void PacMan.update(&self, uint level, Tile *tiles, TimeSpan dt) {
  if(!(self.state_flags & PacManState.DEAD)) {
    self.move(tiles, dt, get_speed(level));
  }
  
  self.update_animation(dt);
}

fn void PacMan.draw(&self) {
                                // Pacman in atlas is not centered 
  Rectangle dest = {            //                 ⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄
    (float)self.pos.x - gl::SPRITE_SIZE_SCALED / 4 + gl::SCALE / 2,
    (float)self.pos.y - gl::SPRITE_SIZE_SCALED / 4,
    gl::SPRITE_SIZE_SCALED,
    gl::SPRITE_SIZE_SCALED,
  };
            
  rl::draw_texture_pro(*self.animation.atlas_ptr,
		       self.animation.uv_rect,
		       dest,
		       {0, 0},
		       0,
		       {255, 255, 255, 255}
  );
}

//===========================================================================================
// Helper functions
//============================================================================================

fn float get_speed(uint level) @private {
  if(level == 1) return 9.6f; // 80%

  if(level < 5) return 10.8f; // 90%

  return 12.f; // 100%
}

<*
 @param [&in] tiles
*>
fn bool is_early_turn(Tile *tiles, Int16[<2>] pos, Uint8 curr, Uint8 desired) @private {
  const BASE_SPEED = 4;
  curr &= CURR_DIR_MASK;
  
  if(curr == desired) return false;

  Uint8 tile_x =  (Uint8)(pos.x / gl::TILE_SCALED);
  Uint8 tile_y = (Uint8)((pos.y / gl::TILE_SCALED) - gl::TOP_UI_SIZE);
  
  for(Uint8 i = 0; i < BASE_SPEED; i++) {
    Uint8 tx = tile_x;
    Uint8 ty = tile_y;

    switch (curr) {
      case Direction.UP:    ty -= i; break;
      case Direction.LEFT:  tx -= i; break;
      case Direction.RIGHT: tx += i; break;
      case Direction.DOWN:  ty += i; break;
    }

    switch (desired) {
      case Direction.UP:    ty -= 1; break;
      case Direction.LEFT:  tx -= 1; break;
      case Direction.RIGHT: tx += 1; break;
      case Direction.DOWN:  ty += 1; break;
    }

    if (tx >= gl::MAZE_WIDTH || ty >= gl::MAZE_HEIGHT) continue;

    Tile t = tiles[tx + ty * gl::MAZE_WIDTH];
    if (t.type != WALL) return true;
  }
  
  return false;
}
