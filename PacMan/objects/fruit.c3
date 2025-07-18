module fruit;

import gl;
import rl;

/*

Index of this module:
// Struct and methods definitions
// Helper function

*/

//------------------------------------------------------------------------------------
// Struct and methods definitions
//------------------------------------------------------------------------------------

struct Fruit {
  Uint16[<2>] pos;
  
  bool active;
  Uint16 points;
  TimeSpan elapsed_time;
  
  Texture2D texture;
  Uint8[<2>] uv;
}

fn void? Fruit.init(&self, uint level) {
  const String ATLAS_FILENAME = "assets/textures/fruits.png";
  
  self.texture = rl::load_texture(ATLAS_FILENAME);
  if(!rl::is_texture_valid(self.texture)) return gl::TEXTURE_NOT_FOUND?;

  self.pos = {
    13 * gl::TILE_SCALED + (gl::TILE_SCALED / 2) - gl::SPRITE_SIZE_SCALED / 4,
    20 * gl::TILE_SCALED - gl::SPRITE_SIZE_SCALED / 4
  };
  
  self.active = false;
  self.elapsed_time = 0.0f;

  set_which_fruit(&self.uv, &self.points, level);
}

fn void Fruit.set_which_fruit(&fruit, uint level) {
  Uint16 points;
  Uint8[<2>] uv;
  uv.y = 1;

  switch(level) {
    // Cherry
    case 1:
      points = 100;
      uv.x = 0 * gl::SPRITE_SIZE + 0 * gl::PADDING + gl::PADDING;
      break;
    // Strawberry
    case 2:
      points = 300;
      uv.x = 1 * gl::SPRITE_SIZE + 1 * gl::PADDING + gl::PADDING;
      break;
    // Peach
    case 3:
    case 4:
      points = 500;
      uv.x = 2 * gl::SPRITE_SIZE + 2 * gl::PADDING + gl::PADDING;
      break;
    // Apple
    case 5:
    case 6:
      points = 700;
      uv.x = 3 * gl::SPRITE_SIZE + 3 * gl::PADDING + gl::PADDING;
      break;
    // Grapes
    case 7:
    case 8:
      points = 1000;
      uv.x = 4 * gl::SPRITE_SIZE + 4 * gl::PADDING + gl::PADDING;
      break;
    // Galaxian
    case 9:
    case 10:
      points = 2000;
      uv.x = 5 * gl::SPRITE_SIZE + 5 * gl::PADDING + gl::PADDING;
      break;
    // Bells
    case 11:
    case 12:
      points = 3000;
      uv.x = 6 * gl::SPRITE_SIZE + 6 * gl::PADDING + gl::PADDING;
      break;
    // Keys
    default:
      points = 5000;
      uv.x = 7 * gl::SPRITE_SIZE + 7 * gl::PADDING + gl::PADDING;
      break;
  }

  fruit.points = points;
  fruit.uv = uv;
}

fn void Fruit.reset(&self) @inline {
  self.active = false;
  self.elapsed_time = 0.0f;
}

fn bool Fruit.collision(&self, Int16[<2>] pacman_pos) {
  return
  (13 * gl::TILE_SCALED == pacman_pos.x  ||
   14 * gl::TILE_SCALED == pacman_pos.x) &&
   20 * gl::TILE_SCALED == pacman_pos.y;
}

fn void Fruit.draw(&self) {
  Rectangle src = {
    self.uv.x,
    self.uv.y,
    gl::SPRITE_SIZE,
    gl::SPRITE_SIZE
  };
      
  Rectangle dest = {
    self.pos.x,
    self.pos.y,
    gl::SPRITE_SIZE_SCALED,
    gl::SPRITE_SIZE_SCALED,
  };
            
  rl::draw_texture_pro(self.texture, src, dest, {0, 0}, 0, {255, 255, 255, 255});
}

fn void Fruit.free(&self) {
  rl::unload_texture(self.texture);
}

//------------------------------------------------------------------------------------
// Helper function
//------------------------------------------------------------------------------------

<*
 Set the uv coord and the amount of points for fruit
 @param [&inout] uv : "Uv passed as null!"
 @param [&out] points : "Points passed as null!"
*>
fn void set_which_fruit(Uint8[<2>] *uv, Uint16 *points, uint level) @private {
  uv.y = 1;

  switch(level) {
    // Cherry
    case 1:
      *points = 100;
      uv.x = 0 * gl::SPRITE_SIZE + 0 * gl::PADDING + gl::PADDING;
      break;
    // Strawberry
    case 2:
      *points = 300;
      uv.x = 1 * gl::SPRITE_SIZE + 1 * gl::PADDING + gl::PADDING;
      break;
    // Peach
    case 3:
    case 4:
      *points = 500;
      uv.x = 2 * gl::SPRITE_SIZE + 2 * gl::PADDING + gl::PADDING;
      break;
    // Apple
    case 5:
    case 6:
      *points = 700;
      uv.x = 3 * gl::SPRITE_SIZE + 3 * gl::PADDING + gl::PADDING;
      break;
    // Grapes
    case 7:
    case 8:
      *points = 1000;
      uv.x = 4 * gl::SPRITE_SIZE + 4 * gl::PADDING + gl::PADDING;
      break;
    // Galaxian
    case 9:
    case 10:
      *points = 2000;
      uv.x = 5 * gl::SPRITE_SIZE + 5 * gl::PADDING + gl::PADDING;
      break;
    // Bells
    case 11:
    case 12:
      *points = 3000;
      uv.x = 6 * gl::SPRITE_SIZE + 6 * gl::PADDING + gl::PADDING;
      break;
    // Keys
    default:
      *points = 5000;
      uv.x = 7 * gl::SPRITE_SIZE + 7 * gl::PADDING + gl::PADDING;
      break;
  }
}
