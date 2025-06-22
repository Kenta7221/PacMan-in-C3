module ui;

import gl;
import rl;

import file_loader;

import libc;
import std::io;

/*

Index of this module:
// Struct and methods definitions
// Helper functions

*/

//------------------------------------------------------------------------------------
// Struct and methods definitions
//------------------------------------------------------------------------------------

struct GameUI {
  Font font;
  Texture2D texture;
  
  uint high_score;
  uint score;

  // Bit layout:
  // Bit 4-7 - left to right indexing fruits
  // Bit 3-0 - right to left indexing fruits
  Uint8 fruit_display_index;
  uint[7] fruit_table;
}

fn void? GameUI.init(&self) {
  const String FONT_DIR = "assets/fonts/emulogic.ttf";
  const String ATLAS_FILENAME = "assets/textures/fruits.png";
  
  self.font = rl::load_font_ex(FONT_DIR, gl::FONT_BASE_SIZE, null, 0);
  if(!rl::is_font_valid(self.font)) {
    io::eprintn("Font for ui was not loaded!");
    return io::FILE_NOT_FOUND?;
  }

  self.texture = rl::load_texture(ATLAS_FILENAME);
  if(!rl::is_texture_valid(self.texture)) {
    io::eprintn("Fruits texture was not loaded!");
    return io::FILE_NOT_FOUND?;
  }

  load_high_score(&self.high_score);
  self.score = 0;

  self.fruit_display_index = 0;
  self.fruit_table = { 0, 0, 0, 0, 0, 0, 0 };

  self.add_fruit(level: 1);
}

<*
 Because the fruits / items shown below of the current and previous levels goes from
 first right to left and then only from left to right we have to change fruit table
 differently
*>
fn void GameUI.add_fruit(&self, uint level) {
  const EXCEED_LEFT_INDEXING  = 0x07;
  
  if(level == 1) {
    self.fruit_table[0] = level;
    return;
  }
  
  Uint8 index = self.fruit_display_index & EXCEED_LEFT_INDEXING;
  
  if(index + 1 < EXCEED_LEFT_INDEXING) {
    self.fruit_display_index += 1;
    self.fruit_table[self.fruit_display_index] = level;
    return;
  }
  
  // Push every fruit to the left
  for(Uint8 i = 0; i < 6; i++) {
    self.fruit_table[i] = self.fruit_table[i + 1];
  }
  
  self.fruit_table[6] = level;
}

<*
 @param [in] pacman_texture
*>
fn void GameUI.draw(&self, Texture2D *pacman_texture, Uint8 pacman_lives, bool draw_lives_fruits = true) {
  ZString str = (ZString)mem::new_array(char, 12);
  Uint16 padding;
  
  if(self.score >= self.high_score) self.high_score = self.score;
  
  // High Score    
  libc::sprintf(str, "%d", self.high_score);
  
  padding = (Uint16)str.char_len() - 1;
  Vector2 high_score_pos = {
    (float)(15 * gl::TILE_SCALED + 3 * gl::TILE_SCALED / 5 - padding * gl::TILE_SCALED + padding * (gl::SCALE + 3) - gl::SCALE / 2),
    gl::TEXT_SIZE
  };

  rl::draw_text_ex(self.font,
		   "High Score",
		   {
		     10 * gl::TILE_SCALED,
		     0
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   {255, 255, 255, 255}
  );
  
  rl::draw_text_ex(self.font, str, high_score_pos, gl::TEXT_SIZE, 0.f, {255, 255, 255, 255});

  // Player score
  libc::sprintf(str, "%d", self.score);
  padding = (Uint16)str.char_len() - 1;
  Vector2 player_score_pos = {
    (float)(6 * gl::TILE_SCALED + gl::TILE_SCALED / 3 - padding * gl::TILE_SCALED + padding * (gl::SCALE + 3) - gl::SCALE / 2),
    gl::TEXT_SIZE
  };

  rl::draw_text_ex(self.font,
		   "1UP",
		   {
		     4 * gl::TILE_SCALED,
		     0
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   {255, 255, 255, 255}
  );

  rl::draw_text_ex(self.font, str, player_score_pos, gl::TEXT_SIZE, 0.f, {255, 255, 255, 255});

  free(str);

  if(!draw_lives_fruits) return;
  
  // Lives
  for(Uint8 i = 0; i < pacman_lives; i++) {
    rl::draw_texture_pro(*pacman_texture,
			 { /*src*/
 			   2.f + gl::SPRITE_SIZE,
			   2.f + gl::SPRITE_SIZE,
			   -1 * gl::SPRITE_SIZE,
			   gl::SPRITE_SIZE
			 },
			  
			 { /*destination*/
			   (float)(2 * gl::TEXT_SIZE + 2 * i * gl::TEXT_SIZE),
			   (gl::MAZE_HEIGHT + gl::TOP_UI_SIZE) * gl::TILE_SCALED,
			   gl::SPRITE_SIZE_SCALED,
			   gl::SPRITE_SIZE_SCALED,
			 },
			  
			 {0, 0}, 0, {255, 255, 255, 255}
    );
  }
  
  Rectangle src = {
    0,
    1,
    gl::SPRITE_SIZE,
    gl::SPRITE_SIZE
  };
        
  // Fruits list
  foreach(idx, fruit : self.fruit_table) {
    if(fruit == 0) continue;

    switch(fruit) {
      // Cherry
      case 1:
	src.x = 0 * gl::SPRITE_SIZE + 0 * gl::PADDING + gl::PADDING;
	break;
      // Strawberry
      case 2:
	src.x = 1 * gl::SPRITE_SIZE + 1 * gl::PADDING + gl::PADDING;
	break;
      // Peach
      case 3:
      case 4:
	src.x = 2 * gl::SPRITE_SIZE + 2 * gl::PADDING + gl::PADDING;
	break;
      // Apple
      case 5:
      case 6:
	src.x = 3 * gl::SPRITE_SIZE + 3 * gl::PADDING + gl::PADDING;
	break;
      // Grapes
      case 7:
      case 8:
	src.x = 4 * gl::SPRITE_SIZE + 4 * gl::PADDING + gl::PADDING;
	break;
      // Galaxian
      case 9:
      case 10:
	src.x = 5 * gl::SPRITE_SIZE + 5 * gl::PADDING + gl::PADDING;
	break;
      // Bells
      case 11:
      case 12:
	src.x = 6 * gl::SPRITE_SIZE + 6 * gl::PADDING + gl::PADDING;
	break;
      // Keys
      default:
	src.x = 7 * gl::SPRITE_SIZE + 7 * gl::PADDING + gl::PADDING;
	break;
    }

    Rectangle dest = {
      (float)(gl::MAZE_WIDTH * gl::TILE_SCALED - (2 * gl::TEXT_SIZE + 2 * idx * gl::TEXT_SIZE) - gl::TEXT_SIZE),
      (gl::MAZE_HEIGHT + gl::TOP_UI_SIZE) * gl::TILE_SCALED,
      gl::SPRITE_SIZE_SCALED,
      gl::SPRITE_SIZE_SCALED,
    };

    rl::draw_texture_pro(self.texture, src, dest, {0, 0}, 0, {255, 255, 255, 255});
  }
}

fn void GameUI.free(&self) {
  ui::save_high_score(self.high_score);
  rl::unload_font(self.font);
  rl::unload_texture(self.texture);
}

//------------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------------

<*
 @param [&out] high_score : "High Score passed as null!"
*>
fn void load_high_score(uint *high_score) @inline @private {
  String temp = file_loader::HIGHEST_SCORE;
  *high_score = temp.to_uint()!!;
}

fn void save_high_score(uint high_score) {
  File file;
  ZString str = (ZString)mem::new_array(char, 12);
  libc::sprintf(str, "%d", high_score);
  
  file = file::open("assets/high_score.bin", "wb")!!;
  file.write(str.str_view())!!;
  
  free(str);
  file.close()!!;
}
