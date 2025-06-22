module audio_manager;

import std::io;

import rl;
import gl;

import game_ctx::gameplay;

const GHOST_SFX_ENABLED @private  = 0x01;
const PACMAN_SFX_ENABLED @private = 0x02;

enum MusicType : Uint8 (inline Uint8 state) {
  NONE          = 1 << 0,
  START_MUSIC   = 1 << 1,
  NORMAL_SPEED	= 1 << 2, 
  SPUR_MODE_1	= 1 << 3, 
  SPUR_MODE_2	= 1 << 4, 
  SPUR_MODE_3	= 1 << 5, 
  SPUR_MODE_4	= 1 << 6, 
  FRIGHTEN_MODE = 1 << 7
}

struct AudioManager {
  Music music;
  Sound* sound;
  Sound pac;
}

fn void? AudioManager.init(&self) {
  const GHOST_NORMAL_SPEED_SFX = "assets/sfx/ghost-normal-speed.wav";
  
  self.sound = null;
  
  self.music = rl::load_music_stream(GHOST_NORMAL_SPEED_SFX);
  if(!rl::is_music_valid(self.music)) {
    io::eprintn("Intro music has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }
    
  rl::play_music_stream(self.music);
}

fn void AudioManager.update_ghost_music(&self, Uint8 flags, MusicType type) {
  const GHOST_NORMAL_SPEED_SFX = "assets/sfx/ghost-normal-speed.wav";
  const GHOST_SPURT_1_SFX      = "assets/sfx/ghost-spurt-move-1.wav";
  const GHOST_SPURT_2_SFX      = "assets/sfx/ghost-spurt-move-2.wav";
  const GHOST_SPURT_3_SFX      = "assets/sfx/ghost-spurt-move-3.wav";
  const GHOST_SPURT_4_SFX      = "assets/sfx/ghost-spurt-move-4.wav";
  const GHOST_FRIGHTEN_SFX     = "assets/sfx/ghost-frighten.wav";

  ZString path = "";
  
  defer rl::play_music_stream(self.music);
  
  if(rl::is_music_stream_playing(self.music)) {
    rl::stop_music_stream(self.music);
    rl::unload_music_stream(self.music);
  }
  
  if(flags & GameplayState.FRIGHTEN_MODE) {
    self.music = rl::load_music_stream(GHOST_FRIGHTEN_SFX);
    return;
  }

  switch(type) {
    case SPUR_MODE_1: path = GHOST_SPURT_1_SFX;      break;
    case SPUR_MODE_2: path = GHOST_SPURT_2_SFX;      break;
    case SPUR_MODE_3: path = GHOST_SPURT_3_SFX;      break;
    case SPUR_MODE_4: path = GHOST_SPURT_4_SFX;      break;
    default:          path = GHOST_NORMAL_SPEED_SFX; break;
  }

  self.music = rl::load_music_stream(path);
}

fn void AudioManager.update_sound(&self, Uint8 flags, bool dot_eaten, bool fruit_eaten) {
  const PACMAN_EATEN_SFX = "assets/sfx/fail.wav";
  const DOT_EATEN_SFX    = "assets/sfx/pacman-eating-dot.wav";
  const GHOST_EATEN_SFX  = "assets/sfx/pacman-eating-ghost.wav";
  const FRUIT_EATEN_SFX  = "assets/sfx/pacman-eating-fruit.wav";

  static bool playing_dot_eaten = false;
  
  ZString path = "";
  
  if(self.sound == null) { self.sound = mem::new(Sound); }
  else if(playing_dot_eaten && dot_eaten && rl::is_sound_playing(*self.sound)) { return; }
  else { rl::stop_sound(*self.sound); }

  switch {
    case dot_eaten:
      path = DOT_EATEN_SFX;
      playing_dot_eaten = true;
      break;
    case fruit_eaten:
      path = FRUIT_EATEN_SFX;
      playing_dot_eaten = false;
      break;
    case (bool)(flags & GameplayState.RESET_LEVEL):
      path = PACMAN_EATEN_SFX;
      playing_dot_eaten = false;
      break;
    case (bool)(flags & GameplayState.GHOST_EATEN):
      path = GHOST_EATEN_SFX;
      playing_dot_eaten = false;
      break;
  }

  *self.sound = rl::load_sound(path);
  rl::play_sound(*self.sound);
}

fn void AudioManager.update(&self) {
  rl::update_music_stream(self.music);
}

fn void AudioManager.free(&self) {
  free(self.sound);
  rl::unload_music_stream(self.music);
}
