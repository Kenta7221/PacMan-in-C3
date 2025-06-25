module maze;

import gl;
import rl;

import file_loader;
import pacman;

/*

Index of this module:
// Struct, enums and methods definitions
// Helper functions

*/

//------------------------------------------------------------------------------------
// Struct, enums and methods definitions
//------------------------------------------------------------------------------------

enum TileType : uint (Uint16 points) {
  BLANK		= 0,
  WALL		= 0,
  DOT		= 10,
  ENERGIZER	= 50,
}

struct Tile  {
  Uint8[<2>] uv;
  Uint8[<2>] pos;
  
  TileType type;
}

struct Maze {
  Tile[gl::MAZE_WIDTH * gl::MAZE_HEIGHT] tiles;
  ZString file_data;
  Texture2D texture;
  TimeSpan elapsed_time;
}

fn void? Maze.init(&self) {
  const ATLAS_DIR = "assets/textures/maze-spritesheet.png";

  self.texture = rl::load_texture(ATLAS_DIR);
  if(!rl::is_texture_valid(self.texture)) return gl::TEXTURE_NOT_FOUND?;

  create_tilemap(&self.tiles);
}

fn void Maze.reset_maze(&self) {
  create_tilemap(&self.tiles);
}

<*
 @param [&in] pacman
*>
fn EventType Maze.update(&self, PacMan *pacman) {
  if(pacman.state_flags & PacManState.TURN_180) return NONE;

  Uint8[<2>] tile = {
    (Uint8)(pacman.pos.x / gl::TILE_SCALED),
    (Uint8)((pacman.pos.y / gl::TILE_SCALED) - gl::TOP_UI_SIZE),
  };

  Tile* curr_tile = &self.tiles[tile.x + tile.y * gl::MAZE_WIDTH];
  
  if(curr_tile.type == BLANK || curr_tile.type == WALL) return NONE;
  
  if(curr_tile.type == ENERGIZER) {
    update_tile_to_blank(curr_tile);
    return ENERGIZE_EATEN;
  }
  
  update_tile_to_blank(curr_tile);
  return SCORE_INCREASE;
}

fn void Maze.draw(&self, bool finished_level = false, bool blinking_energizer = false) {
  static bool is_white = false;
  static bool blank_energizer = false;

  if(!finished_level && is_white) is_white = false;
  
  for(int i = 0; i < gl::MAZE_WIDTH * gl::MAZE_HEIGHT; i++) {
    if(finished_level && self.elapsed_time >= 0.15f) change_tile_around(&self.tiles[i], is_white);

    if(blinking_energizer && blank_energizer && self.tiles[i].type == TileType.ENERGIZER) continue;
    
    Rectangle src = {
      (float)self.tiles[i].uv.x,
      (float)self.tiles[i].uv.y,
      gl::TILE_SIZE,
      gl::TILE_SIZE
    };

    Rectangle dest = {
      (float)(self.tiles[i].pos.x * gl::TILE_SCALED),
      (float)(self.tiles[i].pos.y * gl::TILE_SCALED),
      gl::TILE_SCALED,
      gl::TILE_SCALED
    };
            
    rl::draw_texture_pro(self.texture, src, dest, {0, 0}, 0, {255, 255, 255, 255});
  }

  if(self.elapsed_time >= 0.15f) {
    if(finished_level) is_white = !is_white;    
    if(blinking_energizer) blank_energizer = !blank_energizer;
    
    self.elapsed_time = 0.0f;
  }
}

fn void Maze.free(&self) {
  rl::unload_texture(self.texture);
}

//------------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------------

fn maze::Tile get_tile_at(Tile *tiles, Int16[<2>] pos) {
  int[<2>] tile = {
     pos.x / gl::TILE_SCALED,
    (pos.y / gl::TILE_SCALED) - gl::TOP_UI_SIZE,
  };
    
  return tiles[tile.x + tile.y * gl::MAZE_WIDTH];
}

fn void create_tilemap(Tile* tiles) @private {
  for(int i = 1; i < file_loader::MAZE_DATA.len; i += 2) {
    Uint8[] slice = file_loader::MAZE_DATA[i - 1 .. i];
    Uint8 num =  (slice[0] - '0') * 10 + slice[1] - '0';

    switch(num) {
      case 48:
        tiles[i/2].type = ENERGIZER;
        break;
      case 45:
        tiles[i/2].type = BLANK;
        break;
      case 46:
        tiles[i/2].type = DOT;
        break;
      default:
        tiles[i/2].type = WALL;
        break;
    }
    
    Uint8[<2>] pos;
    pos.x = (Uint8)(   (i / 2) % gl::MAZE_WIDTH);
    pos.y = (Uint8)(  ((i / 2) / gl::MAZE_WIDTH) + gl::TOP_UI_SIZE);
        
    Uint8[<2>] uv;
    uv.x = (Uint8)(( (num - 1) % 16) * gl::TILE_SIZE + ( (num - 1) % 16) * gl::PADDING + gl::PADDING);
    uv.y = (Uint8)(( (num - 1) / 16) * gl::TILE_SIZE + ( (num - 1) / 16) * gl::PADDING + gl::PADDING);
    
    tiles[i / 2].uv = uv;
    tiles[i / 2].pos = pos;
  }
}

fn void update_tile_to_blank(Tile* tile) @private @inline {
  tile.uv.x = (Uint8)(( (45 - 1) % 16) * gl::TILE_SIZE + ( (45 - 1) % 16) * gl::PADDING + gl::PADDING);
  tile.uv.y = (Uint8)(( (45 - 1) / 16) * gl::TILE_SIZE + ( (45 - 1) / 16) * gl::PADDING + gl::PADDING);
  tile.type = BLANK;
}

<*
 I have no idea how to call it. It just switching the color of the wall of the maze from white to blue and so on
 @param [&out] tile : "Tile was passed as null!"
*>
fn void change_tile_around(Tile* tile, bool is_white) @private @inline {
  if(is_white) {
    tile.uv.y -= 27;
    return;
  }
    
  tile.uv.y += 27;
}
