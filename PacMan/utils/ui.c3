module ui;

import gl;
import rl;

import hack;

import libc;
import std::io;

<*
 @param [&out] high_score : "High Score passed as null!"
*>
fn void load_high_score(uint *high_score) @inline @private {
  String temp = hack::HIGHEST_SCORE;
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

struct GameUI {
  Font font;
  Texture2D *atlas_ptr;
  
  uint high_score;
  uint score;

  // Bit layout:
  // Bit 4-7 - left to right indexing fruits
  // Bit 3-0 - right to left indexing fruits
  Uint8 fruit_display_index;
  uint[7] fruit_table;
}

fn void? GameUI.init(&self, Texture2D *atlas) {
  const String FONT_DIR = "assets/fonts/emulogic.ttf";
  
  self.atlas_ptr = atlas;

  self.font = rl::load_font_ex(FONT_DIR, gl::FONT_BASE_SIZE, null, 0);
  if(!rl::is_font_valid(self.font)) {
    io::printn("Font for ui was not loaded!");
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

fn void GameUI.draw_ready_player(&self) {
  const CHAR_SIZE = 32;
  const DRAW_FONT_SIZE = 40;
    
  rl::draw_text_ex(self.font,
		   "Ready!",
		   { (Uint16)(gl::MAZE_WIDTH / 2 * gl::PIXEL_SCALED - 3 * CHAR_SIZE) + 10, 20 * gl::PIXEL_SCALED - 5 },
		   DRAW_FONT_SIZE, 0.f,
		   (Color){255, 255, 0, 255}
  );

  rl::draw_text_ex(self.font,
		   "Player One!",
		   { (Uint16)(gl::MAZE_WIDTH / 2 * gl::PIXEL_SCALED - 5 * CHAR_SIZE - 22) + 10, 14 * gl::PIXEL_SCALED - 5 },
		   DRAW_FONT_SIZE, 0.f,
		   (Color){0, 255, 255, 255}
  );
}

fn void GameUI.draw_ui(&self, Uint8 pacman_lives, bool draw_fruits = true) {  
  ZString str = (ZString)mem::new_array(char, 12);
  
  if(self.score >= self.high_score) self.high_score = self.score;
  
  // High Score    
  libc::sprintf(str, "%d", self.high_score);
  Uint16[<2>] high_score_pos = {
    (Uint16)(gl::MAZE_WIDTH / 2 * gl::PIXEL_SCALED - (str.char_len() - 3) * gl::CHAR_SIZE),
    gl::CHAR_SIZE + 10
  };

  rl::draw_text_ex(self.font,
		   "High Score",
		   { gl::MAZE_WIDTH / 2 * gl::PIXEL_SCALED - 10 * gl::CHAR_SIZE / 2, 0 },
		   gl::DRAW_FONT_SIZE, 0.f,
		   (Color){255, 255, 255, 255}
  );
  
  rl::draw_text_ex(self.font, str, high_score_pos, gl::DRAW_FONT_SIZE, 0.f, (Color){255, 255, 255, 255});

  // Player score    
  Uint16[<2>] player_score_pos = {
    (Uint16)(gl::MAZE_WIDTH / 6 * gl::PIXEL_SCALED - (str.char_len() - 3) * gl::CHAR_SIZE),
    gl::CHAR_SIZE + 10
  };

  libc::sprintf(str, "%d", self.score);
  rl::draw_text_ex(self.font,
		   "1UP",
		   { gl::MAZE_WIDTH / 6 * gl::PIXEL_SCALED - 2 * gl::CHAR_SIZE / 2, 0 },
		   gl::DRAW_FONT_SIZE, 0.f,
		   (Color){255, 255, 255, 255}
  );

  rl::draw_text_ex(self.font, str, player_score_pos, gl::DRAW_FONT_SIZE, 0.f, (Color){255, 255, 255, 255});

  free(str);
  
  // Lives
  for(Uint8 i = 0; i < pacman_lives; i++) {
    Rectangle dest = {
      (float)(2 * gl::CHAR_SIZE + 2 * i * gl::CHAR_SIZE),
      (gl::MAZE_HEIGHT + gl::TOP_UI_SIZE) * gl::PIXEL_SCALED,
      gl::SPRITE_SIZE_SCALED,
      gl::SPRITE_SIZE_SCALED,
    };
    
    rl::draw_texture_pro(*self.atlas_ptr,
			 { /*src*/
			   2.f + gl::SPRITE_SIZE,
			   1.f,
			   -1 * gl::SPRITE_SIZE,
			   gl::SPRITE_SIZE
			 },
			  
			 { /*destination*/
			   (float)(2 * gl::CHAR_SIZE + 2 * i * gl::CHAR_SIZE),
			   (gl::MAZE_HEIGHT + gl::TOP_UI_SIZE) * gl::PIXEL_SCALED,
			   gl::SPRITE_SIZE_SCALED,
			   gl::SPRITE_SIZE_SCALED,
			 },
			  
			 (float[<2>]){0, 0}, 0, (Color){255, 255, 255, 255}
    );
  }

  if(!draw_fruits) return;
  
  Rectangle src = {
    0 * gl::SPRITE_SIZE + 0 * gl::PADDING + gl::PADDING,
    9 * gl::SPRITE_SIZE + 9 * gl::PADDING + gl::PADDING,
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
      (float)(gl::MAZE_WIDTH * gl::PIXEL_SCALED - (2 * gl::CHAR_SIZE + 2 * idx * gl::CHAR_SIZE) - gl::CHAR_SIZE),
      (gl::MAZE_HEIGHT + gl::TOP_UI_SIZE) * gl::PIXEL_SCALED,
      gl::SPRITE_SIZE_SCALED,
      gl::SPRITE_SIZE_SCALED,
    };

    rl::draw_texture_pro(*self.atlas_ptr, src, dest, (float[<2>]){0, 0}, 0, (Color){255, 255, 255, 255});
  }
}

fn void GameUI.free(&self) {
  ui::save_high_score(self.high_score);
  rl::unload_font(self.font);
}
