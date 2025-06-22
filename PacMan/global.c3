module gl;

import rl;

import main;


/*

Index of this module:
// Aliases, const values, enums definitions
// Global functions and macro

*/

//------------------------------------------------------------------------------------
// Aliases, const values, enums definitions
//------------------------------------------------------------------------------------

alias Uint16 = ushort;
alias Uint8 = char;
alias Int16  = short;
alias Int8 = ichar;

alias TimeSpan = float;

// Actual scale used everywhere
const SCALE = main::SCREEN_SCALE;
const TILE_SIZE = 8;
const TILE_SCALED = SCALE * TILE_SIZE;

const TOP_UI_SIZE = 3;
const BOTTOM_UI_SIZE = 2;

const MAZE_HEIGHT = 31;
const MAZE_WIDTH = 28;

const FONT_BASE_SIZE = 128;
const TEXT_SIZE = SCALE * TILE_SIZE;

const SPRITE_SIZE = 2 * gl::TILE_SIZE;
const SPRITE_SIZE_SCALED = 2 * gl::TILE_SIZE * SCALE;
const PADDING = 1;

enum EventType : (inline Uint8 type) {
  NONE           = 0,
  SCORE_INCREASE = 0x01 << 1,
  ENERGIZE_EATEN = 0x01 << 2,
  FRUIT_EATEN    = 0x01 << 3,
  GHOST_EATEN    = 0x01 << 4
}

// Sequence based on higher priority directions of ghosts in chase or scatter mode
enum Direction : Uint8 (inline Uint8 type){
  NONE		= 0xF      ,
  UP		= 0x01     ,
  LEFT		= 0x01 << 1,
  DOWN	        = 0x01 << 2,
  RIGHT		= 0x01 << 3,
}


//------------------------------------------------------------------------------------
// Global functions and macro
//------------------------------------------------------------------------------------

macro check_scale($scale) {
  $if $scale >= 120:
    $error("Invalid scale value: exceeds range of 'short' type.");
  $endif  
}

fn Int16[<2>] tween_pos_by_tiles(Int16[<2>] s, Int16[<2>] e, float t) {
  if(t > 1.f) t = 1.f;
  if(t < 0.f) t = 0.f;

  return {
    (Int16)(s.x + (float)(e.x - s.x) * t),
    (Int16)(s.y + (float)(e.y - s.y) * t)
  };
}

fn Int16[<2>] tween_pos_by_dir(Int16[<2>] pos, Uint8 dir, float t) {
  Int16[<2>] next_tile = pos / gl::TILE_SCALED;
  Int16[<2>] prev_tile = pos / gl::TILE_SCALED;

  if(t > 1.f) t = 1.f;
  if(t < 0.f) t = 0.f;
  
  switch(dir) {
    case Direction.UP:
      if(!is_aligned(pos)) {
	prev_tile.y += 1;
	break;
      }
      
      next_tile.y -= 1;
      break;              // Checking if it is positive value for the tunnel wrapper to work properly 
    case Direction.LEFT:  // ⌄⌄⌄⌄⌄⌄⌄⌄⌄
      if(!is_aligned(pos) && pos.x > 0) {
	prev_tile.x += 1;
	break;
      }
      
      next_tile.x -= 1;
      break;
    case Direction.RIGHT	: next_tile.x += 1; break;
    case Direction.DOWN		: next_tile.y += 1; break;
    default			: return pos;
  }

  next_tile *= gl::TILE_SCALED;
  prev_tile *= gl::TILE_SCALED;
  
  return {
    (Int16)(prev_tile.x + (float)(next_tile.x - prev_tile.x) * t),
    (Int16)(prev_tile.y + (float)(next_tile.y - prev_tile.y) * t)
  };
}

fn Uint16[<2>] get_speed_vector(Uint8 dir, Uint8 velocity = 1) {
  dir &= 0x0F; 
  Uint16[<2>] speed = {0, 0};
  
  switch (dir) {
    case Direction.UP		: speed.y = -velocity; break;
    case Direction.LEFT		: speed.x = -velocity; break;
    case Direction.RIGHT	: speed.x =  velocity; break;
    case Direction.DOWN		: speed.y =  velocity; break;
    default			: break;
  }
  
  return speed;
}

fn Int16[<2>] get_tile_offset(Int16[<2>] pos, Uint8 dir) {
  dir &= 0x0F;
  
  switch(dir) {
    case Direction.UP		: pos.y -= 1; break;
    case Direction.LEFT		: pos.x -= 1; break;
    case Direction.RIGHT	: pos.x += gl::TILE_SCALED; break;
    case Direction.DOWN		: pos.y += gl::TILE_SCALED; break;
    default			: break;
  }

  return pos;
}

fn bool is_aligned(Int16[<2>] pos
) @inline {
  return pos.x % gl::TILE_SCALED == 0 &&
         pos.y % gl::TILE_SCALED == 0;
}

fn bool is_reverse_dir(Uint8 curr_dir, Uint8 potential_dir) {
  if((curr_dir & Direction.NONE) == Direction.NONE) return false;

  Uint8 combine = curr_dir ^ potential_dir;
  
  return (combine & 0x05) == 0x05 || (combine & 0x0A) == 0x0A;
}


fn bool in_tunnel(Int8[<2>] pos)  {  
  const Int8[<3>]LEFT_TUNNEL = {
    -2,  // x pos
     4,  // width
    17   // y pos
  };

  const Int8[<3>]RIGHT_TUNNEL = {
    22,  // x pos
    29,  // width
    17   // y pos
  };
  
  bool in_left_tunnel =
    pos.x >= LEFT_TUNNEL.x &&
    pos.x <= LEFT_TUNNEL.y &&
    pos.y == LEFT_TUNNEL.z;
  
  bool in_right_tunnel =
    pos.x >= RIGHT_TUNNEL.x &&
    pos.x <= RIGHT_TUNNEL.y &&
    pos.y == RIGHT_TUNNEL.z;

  return in_left_tunnel || in_right_tunnel;
}

<*
 @param [&inout] pos : "Pos was passed as null!"
*>
fn void handle_tunnel_wrap(Int16[<2>] *pos) {
  if(pos.x <= -2 * gl::TILE_SCALED) {
    pos.x = 28 * gl::TILE_SCALED;
    return;
  }

  if(pos.x >= 29.f * gl::TILE_SCALED) {
    pos.x = -(Int8)gl::TILE_SCALED;
    return;
  }
}
