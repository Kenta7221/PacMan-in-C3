module game_ctx::title_screen;

import std::io;

import rl;
import gl;

import ghost;
import ui;
import timer;

/*

Index of this module:
// Struct and methods definitions
// Helper functions

*/

//------------------------------------------------------------------------------------
// Struct and methods definitions
//------------------------------------------------------------------------------------

struct TitleScreen {  
  Font font;
  Texture2D maze_atlas; // Used only for dots and pellets
  Texture2D ghost_atlas;
  
  Music music;

  GameUI ui;
  Ghost[4] ghosts;
}

fn void? TitleScreen.init(&self) {
  const MAZE_ATLAS_DIR  = "assets/textures/maze-spritesheet.png";
  const GHOST_ATLAS_DIR = "assets/textures/ghosts.png";
  const FONT_DIR	= "assets/fonts/emulogic.ttf";
  const INTRO_DIR	= "assets/sfx/start-music.wav";

  const Int16    GHOST_DRAW_POS_X = 5 * gl::TILE_SCALED + gl::TILE_SCALED / 2;
  const Int16[4] GHOST_DRAW_POS_Y = {
    8  * gl::TILE_SCALED, // Blinky
    11 * gl::TILE_SCALED, // Pinky
    14 * gl::TILE_SCALED, // Inky
    17 * gl::TILE_SCALED, // Clyde
  };

  self.font = rl::load_font_ex(FONT_DIR, gl::FONT_BASE_SIZE, null, 0);
  if(!rl::is_font_valid(self.font)) {
    io::eprintn("Font has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }
  
  self.maze_atlas = rl::load_texture(MAZE_ATLAS_DIR);
  if(!rl::is_texture_valid(self.maze_atlas)) {
    io::eprintn("Maze atlas has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }

  self.ghost_atlas = rl::load_texture(GHOST_ATLAS_DIR);
  if(!rl::is_texture_valid(self.ghost_atlas)) {
    io::eprintn("Ghost atlas has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }

  self.music = rl::load_music_stream(INTRO_DIR);
  if(!rl::is_music_valid(self.music)) {
    io::eprintn("Intro music has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }

  rl::play_music_stream(self.music);

  self.ui.init()!;

  self.ghosts[0].init(GhostType.BLINKY, &self.ghost_atlas);
  self.ghosts[1].init(GhostType.PINKY , &self.ghost_atlas);
  self.ghosts[2].init(GhostType.INKY  , &self.ghost_atlas);
  self.ghosts[3].init(GhostType.CLYDE , &self.ghost_atlas);
  
  foreach(idx, &ghost : self.ghosts) {
    ghost.dir = Direction.RIGHT;
    ghost.pos = {GHOST_DRAW_POS_X, GHOST_DRAW_POS_Y[idx] };
  }
}

<*
 @param [&out] state : "Game state passed as null!"
*>
fn void TitleScreen.update(&self, GameState *state, TimeSpan dt) {
  rl::update_music_stream(self.music);
  
  if(rl::is_key_down(rl::KEY_SPACE)) {
    *state = GAMEPLAY;
  }

  foreach(&ghost : self.ghosts) { ghost.update_animation(dt); }
}
fn void TitleScreen.draw(&self) {
  static Uint8 blinks = 0;
  static bool flash = true;

  blinks += 1;
 
  rl::draw_text_ex(self.font,
		   "Character / Nickname",
		   {
		     (float)(self.ghosts[0].pos.x + 2 * gl::TEXT_SIZE),
		     (float)(self.ghosts[0].pos.y - gl::SPRITE_SIZE_SCALED)
		   },
		   gl::TEXT_SIZE,
		   0.0f,
		   {255, 255, 255, 255}
  );

  self.ui.draw(pacman_texture: null, pacman_lives: 0, draw_lives_fruits: false);
 
  draw_ghost_with_name(&self.ghosts[0], GhostType.BLINKY, &self.font, "-Shadow    \"Blinky\"");
  draw_ghost_with_name(&self.ghosts[1], GhostType.PINKY , &self.font, "-Speedy    \"Pinky\"" );
  draw_ghost_with_name(&self.ghosts[2], GhostType.INKY  , &self.font, "-Bashful   \"Inky\""  );
  draw_ghost_with_name(&self.ghosts[3], GhostType.CLYDE , &self.font, "-Pokey     \"Clyde\"" );

  draw_maze_points(&self.maze_atlas, &self.font);
 
  rl::draw_text_ex(self.font,
		   "Made by Kenta",
		   {
		     (float)(self.ghosts[3].pos.x + 3 * gl::TILE_SCALED),
		     (float)(self.ghosts[3].pos.y + 15 * gl::TILE_SCALED)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   {255, 185, 255, 255}
  );

  if(blinks >= 32) {
    blinks = 0;
    flash = !flash;
  }

  if(!flash) return;
 
  rl::draw_text_ex(self.font,
		   "Press space to start!",
		   {
		     (float)(self.ghosts[3].pos.x),
		     (float)(self.ghosts[3].pos.y + 2 * gl::SPRITE_SIZE_SCALED + gl::TILE_SCALED / 2)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   {255, 255, 255, 255}
  );
}

//------------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------------

<*
 @ensure nicknames != null
 @param [&in] ghost : "Ghost passed as null!"
 @param [&in] font : "Font passed as null!"
*>
fn void draw_ghost_with_name(Ghost *ghost, Uint8 ghost_type, Font *font, ZString nicknames) {
  const Color[4] FONT_COLOR = {
    {255,   0,   0, 255},
    {255, 185, 255, 255},
    {  0, 255, 255, 255},
    {255, 185,  81, 255}
  };
 
  ghost.draw();

  rl::draw_text_ex(*font,
		   nicknames,
		   {
		     (float)(ghost.pos.x + 2 * gl::TEXT_SIZE),
		     (float)(ghost.pos.y)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   FONT_COLOR[ghost_type]
  );
}

<*
 @param [&in] maze_atlas : "Maze atlas passed as null!"
 @param [&in] font : "Font passed as null!"
*>
fn void draw_maze_points(Texture2D *maze_atlas, Font *font) {
  const Uint8[<2>] ENERGIZER_UV = {
    ((48 - 1) % 16) * gl::TILE_SIZE + ( (48 - 1) % 16) * gl::PADDING + gl::PADDING,
    ((48 - 1) / 16) * gl::TILE_SIZE + ( (48 - 1) / 16) * gl::PADDING + gl::PADDING
  };

  const Uint8[<2>] DOT_UV = {
    ((46 - 1) % 16) * gl::TILE_SIZE + ( (46 - 1) % 16) * gl::PADDING + gl::PADDING,
    ((46 - 1) / 16) * gl::TILE_SIZE + ( (46 - 1) / 16) * gl::PADDING + gl::PADDING,
  };
   
  const Int16 DRAW_POS_X = 10 * gl::TILE_SCALED;

  Rectangle src;
  Rectangle dest;

  src = {
    (float)DOT_UV.x,
    (float)DOT_UV.y,
    gl::TILE_SIZE,
    gl::TILE_SIZE
  };
 
  dest = {
    DRAW_POS_X,
    25 * gl::TILE_SCALED + gl::TILE_SCALED / 2,
    gl::TILE_SCALED,
    gl::TILE_SCALED
  };
           
  rl::draw_texture_pro(*maze_atlas, src, dest, {0, 0}, 0, {255, 255, 255, 255});

  rl::draw_text_ex(*font,
		   "10 pts",
		   {
		     (float)(DRAW_POS_X + 2 * gl::TEXT_SIZE),
		     (float)(25 * gl::TILE_SCALED + gl::TILE_SCALED / 2)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   {255, 255, 255, 255}
  );
 
  src.x = ENERGIZER_UV.x;
  src.y = ENERGIZER_UV.y;

  dest.y = 27 * gl::TILE_SCALED + gl::TILE_SCALED / 2;
 
  rl::draw_texture_pro(*maze_atlas, src, dest, {0, 0}, 0, {255, 255, 255, 255});
 
  rl::draw_text_ex(*font,
		   "50 pts",
		   {
		     (float)(DRAW_POS_X + 2 * gl::TEXT_SIZE),
		     (float)(27 * gl::TILE_SCALED + gl::TILE_SCALED / 2)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   {255, 255, 255, 255}
  );
}

fn void TitleScreen.free(&self) {
  rl::unload_font(self.font);
  rl::unload_texture(self.maze_atlas);
  rl::unload_texture(self.ghost_atlas);
  rl::unload_music_stream(self.music);

  self.ui.free();
}
