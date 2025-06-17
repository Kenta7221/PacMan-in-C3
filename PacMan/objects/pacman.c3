module pacman;

import std::io;

import gl;
import rl;
import animator;
import maze;

const CURR_DIR_MASK @private = 0x0F;
const TURN_DIR_MASK @private = 0xF0;

const BASE_SPEED @private = 4;

struct PacMan {
  Int16[<2>] pos;
  Uint8 lives;  
  TimeSpan lerp_amount;
  
  // Bit layout:
  // Bit 4-7 - early turn
  // Bit 3-0 - curr dir
  Uint8 dirs;
  bool can_turn_180;
  
  Animator animation;
}

<*
 @param [&in] atlas_ptr : "Entity atlas was passed as null!"
*>
fn void PacMan.init(&self, Texture2D *atlas_ptr) {
  self.set_at_start_pos();
  self.lives = 3;

  self.animation.init(atlas_ptr, 0, 3, 0.05f);

  self.lerp_amount = 0.0f;
}

fn void PacMan.set_at_start_pos(&self) {
  const Int16[<2>] BASE_POS = {
    13 * gl::TILE_SCALED + (gl::TILE_SCALED / 2),
    26 * gl::TILE_SCALED
  };

  self.pos = BASE_POS;
  self.can_turn_180 = false;
  self.dirs = (Direction.NONE.type << 4) | (Direction.NONE.type);
}

<*
 @param [&in] tiles
*>
fn void PacMan.move(&self, Tile *tiles) {  
  Uint8 input_dir = Direction.NONE;
  Int16[<2>] next_pos;
  Tile next_tile;

  defer {
    if(!self.can_turn_180) {
      if(gl::is_aligned(self.pos) || self.lerp_amount >= 1.f) self.lerp_amount = 0.0f;
      self.lerp_amount += 0.14f;

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
  if(input_dir != Direction.NONE && !gl::is_reverse_dir(self.dirs, input_dir) || self.can_turn_180 && input_dir != Direction.NONE) {
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
    self.can_turn_180 = true;
    return;
  }

  self.can_turn_180 = false;
}

fn void PacMan.draw(&self, TimeSpan dt, bool dead = false) {
  Rectangle src;
                                // Pacman in atlas is not centered 
  Rectangle dest = {            //                 ⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄
    (float)self.pos.x - gl::SPRITE_SIZE_SCALED / 4 + gl::SCALE / 2,
    (float)self.pos.y - gl::SPRITE_SIZE_SCALED / 4,
    gl::SPRITE_SIZE_SCALED,
    gl::SPRITE_SIZE_SCALED,
  };

  if(dead) {
    src = src = self.animation.get_src(2, dt);
    rl::draw_texture_pro(*self.animation.atlas_ptr, src, dest, (float[<2>]){0, 0}, 0, (Color){255, 255, 255, 255});
    return;
  }
  
  if(self.dirs & CURR_DIR_MASK == Direction.NONE || self.can_turn_180) {
    self.animation.curr_image = 0;
    src = { 1.f, 1.f, gl::SPRITE_SIZE, gl::SPRITE_SIZE };
    rl::draw_texture_pro(*self.animation.atlas_ptr, src, dest, (float[<2>]){0, 0}, 0, (Color){255, 255, 255, 255});
    return;
  }
  
  switch(self.dirs & CURR_DIR_MASK) {
    case Direction.UP		: src = self.animation.get_src(1, dt, flip: animator::FLIP_VERTICALLY  ); break;
    case Direction.LEFT	        : src = self.animation.get_src(0, dt, flip: animator::FLIP_HORIZONTALLY); break;
    case Direction.RIGHT	: src = self.animation.get_src(0, dt                                   ); break;
    case Direction.DOWN	        : src = self.animation.get_src(1, dt                                   ); break;
    default			: break;
  }
            
  rl::draw_texture_pro(*self.animation.atlas_ptr, src, dest, (float[<2>]){0, 0}, 0, (Color){255, 255, 255, 255});
}

<*
 @param [&in] tiles
*>
fn bool is_early_turn(Tile *tiles, Int16[<2>] pos, Uint8 curr, Uint8 desired) @private {
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
