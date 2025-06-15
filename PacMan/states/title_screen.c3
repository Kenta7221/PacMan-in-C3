module game_ctx::title_screen;

import std::io;

import rl;
import gl;

import ghost;
import ui;
import timer;

struct TitleScreen {
  Texture2D* entity_atlas; // Pacman, ghosts and fruits
  Texture2D maze_atlas;    // Only for dots and pellets
  Timer *timer;

  GameUI ui;
  
  Font font;
  Ghost[4] ghosts;
}

fn void? TitleScreen.init(&self, Texture2D *entity_atlas, Timer *timer) {
  const String MAZE_ATLAS_DIR = "assets/textures/maze-spritesheet.png";
  const String FONT_DIR = "assets/fonts/emulogic.ttf";

  const Int16    GHOST_DRAW_POS_X = 5 * gl::PIXEL_SCALED;
  const Int16[4] GHOST_DRAW_POS_Y = {
    8  * gl::PIXEL_SCALED, // Blinky
    11 * gl::PIXEL_SCALED, // Pinky
    14 * gl::PIXEL_SCALED, // Inky
    17 * gl::PIXEL_SCALED, // Clyde
  };

  self.entity_atlas = malloc(Texture2D.sizeof);
  self.entity_atlas = entity_atlas;
  
  self.timer = timer;

  self.maze_atlas = rl::load_texture(MAZE_ATLAS_DIR);
  if(!rl::is_texture_valid(self.maze_atlas)) {
    io::printn("Maze atlas has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }
  
  self.font = rl::load_font_ex(FONT_DIR, gl::FONT_BASE_SIZE, null, 0);
  if(!rl::is_font_valid(self.font)) {
    io::printn("Font has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }

  self.ui.init(entity_atlas)!;
  
  self.ghosts[0].init(GhostType.BLINKY, entity_atlas);
  self.ghosts[1].init(GhostType.PINKY , entity_atlas);
  self.ghosts[2].init(GhostType.INKY  , entity_atlas);
  self.ghosts[3].init(GhostType.CLYDE , entity_atlas);

  
  foreach(idx, &ghost : self.ghosts) {
    ghost.dir = Direction.RIGHT;
    ghost.pos = {GHOST_DRAW_POS_X, GHOST_DRAW_POS_Y[idx] };
  }
}

<*
 @param [&out] state : "Game state passed as null!"
*>
fn void TitleScreen.update(&self, GameState *state) {
  if(rl::is_key_down(rl::KEY_SPACE)) {
    *state = GAMEPLAY;
  }
}

fn void TitleScreen.draw(&self, TimeSpan dt) {
  static TimeSpan total_time = 0.0f;
  static bool flash = true;

  total_time += dt;
  
  rl::draw_text_ex(self.font,
		   "Character / Nickname",
		   {
		     (float)(self.ghosts[0].pos.x + 2 * gl::TEXT_SIZE),
		     (float)(self.ghosts[0].pos.y - gl::SPRITE_SIZE_SCALED)
		   },
		   gl::TEXT_SIZE,
		   0.0f,
		   (Color){255, 255, 255, 255}
  );

  self.ui.draw_ui(pacman_lives: 0, draw_fruits: false);
  
  draw_ghost_with_name(&self.ghosts[0], GhostType.BLINKY, &self.font, "-Shadow     Blinky", self.timer.dt);
  draw_ghost_with_name(&self.ghosts[1], GhostType.PINKY , &self.font, "-Speedy     Pinky", self.timer.dt);
  draw_ghost_with_name(&self.ghosts[2], GhostType.INKY  , &self.font, "-Bashful    Inky", self.timer.dt);
  draw_ghost_with_name(&self.ghosts[3], GhostType.CLYDE , &self.font, "-Pokey      Clyde", self.timer.dt);

  draw_maze_points(&self.maze_atlas, &self.font);
  
  rl::draw_text_ex(self.font,
		   "2025 made by Kenta",
		   {
		     (float)(self.ghosts[3].pos.x + gl::TEXT_SIZE),
		     (float)(self.ghosts[3].pos.y + 8 * gl::SPRITE_SIZE_SCALED)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   (Color){255, 185, 255, 255}
  );

  if(total_time >= 0.8) {
    total_time = 0.0f;
    flash = !flash;
  }

  if(!flash) return;
  
  rl::draw_text_ex(self.font,
		   "Press space to start!",
		   {
		     (float)(self.ghosts[3].pos.x),
		     (float)(self.ghosts[3].pos.y + 2 * gl::SPRITE_SIZE_SCALED)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   (Color){255, 255, 255, 255}
  );
}

<*
 @ensure nicknames != null
 @param [&in] ghost : "Ghost passed as null!"
 @param [&in] font : "Font passed as null!"
*>
fn void draw_ghost_with_name(Ghost *ghost, Uint8 ghost_type, Font *font, ZString nicknames, TimeSpan dt) {
  const Color[4] FONT_COLOR = {
    {255,   0,   0, 255},
    {255, 185, 255, 255},
    {  0, 255, 255, 255},
    {255, 185,  81, 255}
  };
  
  ghost.draw(ghost_type, dt);

  rl::draw_text_ex(*font,
		   nicknames,
		   {
		     (float)(ghost.pos.x + 2 * gl::TEXT_SIZE),
		     (float)(ghost.pos.y + gl::TEXT_SIZE / 18)
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
   ((48 - 1) % 16) * gl::PIXEL_SIZE + ( (48 - 1) % 16) * gl::PADDING + gl::PADDING,
   ((48 - 1) / 16) * gl::PIXEL_SIZE + ( (48 - 1) / 16) * gl::PADDING + gl::PADDING
  };

  const Uint8[<2>] DOT_UV = {
    ((46 - 1) % 16) * gl::PIXEL_SIZE + ( (46 - 1) % 16) * gl::PADDING + gl::PADDING,
    ((46 - 1) / 16) * gl::PIXEL_SIZE + ( (46 - 1) / 16) * gl::PADDING + gl::PADDING,
  };
    
  const Int16 DRAW_POS_X = 10 * gl::PIXEL_SCALED;

  Rectangle src;
  Rectangle dest;

  src = {
    (float)DOT_UV.x,
    (float)DOT_UV.y,
    gl::PIXEL_SIZE,
    gl::PIXEL_SIZE
  };
  
  dest = {
    DRAW_POS_X,
    24 * gl::PIXEL_SCALED,
    gl::PIXEL_SCALED,
    gl::PIXEL_SCALED
  };
            
  rl::draw_texture_pro(*maze_atlas, src, dest, (float[<2>]){0, 0}, 0, (Color){255, 255, 255, 255});

  rl::draw_text_ex(*font,
		   "10 pts",
		   {
		     (float)(DRAW_POS_X + 1.5f * gl::TEXT_SIZE),
		     (float)(24 * gl::PIXEL_SCALED - gl::TEXT_SIZE / 8)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   (Color){255, 255, 255, 255}
  );
  
  src.x = ENERGIZER_UV.x;
  src.y = ENERGIZER_UV.y;

  dest.y = 26 * gl::PIXEL_SCALED;
  
  rl::draw_texture_pro(*maze_atlas, src, dest, (float[<2>]){0, 0}, 0, (Color){255, 255, 255, 255});
  
  rl::draw_text_ex(*font,
		   "50 pts",
		   {
		     (float)(DRAW_POS_X + 1.5f * gl::TEXT_SIZE),
		     (float)(26 * gl::PIXEL_SCALED - gl::TEXT_SIZE / 8)
		   },
		   gl::TEXT_SIZE,
		   0.f,
		   (Color){255, 255, 255, 255}
  );
}

fn void TitleScreen.free(&self) {
  rl::unload_texture(self.maze_atlas);

  self.entity_atlas = null;
  self.timer = null;

  self.ui.free();

  rl::unload_font(self.font);
}
