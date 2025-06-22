module audio_manager;

import std::io;

import rl;
import gl;

import game_ctx::gameplay;


/*

Index of this module:
// Struct, enums and methods definitions

*/

//------------------------------------------------------------------------------------
// Struct, enums and methods definitions
//------------------------------------------------------------------------------------

enum GhostMusicType : Uint8 (inline Uint8 state) {
  NONE          = 1 << 0,
  NORMAL_SPEED	= 1 << 1, 
  SPUR_MODE_1	= 1 << 2, 
  SPUR_MODE_2	= 1 << 3, 
  SPUR_MODE_3	= 1 << 4, 
  SPUR_MODE_4	= 1 << 5, 
  FRIGHTEN_MODE = 1 << 6,
  GO_HOME       = 1 << 7
}

struct AudioManager {
  bool go_home_playing; // To deal with return home sfx make easier
  bool music_in_queue;  // Only is for ghost music ofx
  GhostMusicType next_music;

  Music[2] musics; // One for ghost and pacman
  Sound* sound;
}

fn void? AudioManager.init(&self) {
  const GHOST_NORMAL_SPEED_SFX = "assets/sfx/ghost-normal-speed.wav";
  const PACMAN_EATING_SFX      = "assets/sfx/pacman-eating-dot.wav";

  self.go_home_playing = false;
  self.music_in_queue = false;
  self.sound = null;

  self.musics[0] = rl::load_music_stream(GHOST_NORMAL_SPEED_SFX);
  if(!rl::is_music_valid(self.musics[0])) {
    io::eprintn("Ghost normal speed music has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }

  self.musics[1] = rl::load_music_stream(PACMAN_EATING_SFX);
  if(!rl::is_music_valid(self.musics[1])) {
    io::eprintn("PacMan eating dot music has not been loaded!");
    return io::FILE_NOT_FOUND?;
  }
    
  rl::play_music_stream(self.musics[0]);  
  rl::play_music_stream(self.musics[1]);
}

fn void AudioManager.update(&self) {
  rl::update_music_stream(self.musics[0]);
  rl::update_music_stream(self.musics[1]);
}

fn void AudioManager.update_ghost_music(&self, Uint8 flags, GhostMusicType type) {
  const GHOST_NORMAL_SPEED_SFX = "assets/sfx/ghost-normal-speed.wav";
  const GHOST_SPURT_1_SFX      = "assets/sfx/ghost-spurt-move-1.wav";
  const GHOST_SPURT_2_SFX      = "assets/sfx/ghost-spurt-move-2.wav";
  const GHOST_SPURT_3_SFX      = "assets/sfx/ghost-spurt-move-3.wav";
  const GHOST_SPURT_4_SFX      = "assets/sfx/ghost-spurt-move-4.wav";
  const GHOST_FRIGHTEN_SFX     = "assets/sfx/ghost-frighten.wav";
  const GHOST_RETURN_HOME_SFX  = "assets/sfx/ghost-go-home.wav";

  ZString path = "";
  
  defer rl::play_music_stream(self.musics[0]);
  
  if(rl::is_music_stream_playing(self.musics[0])) {
    rl::stop_music_stream(self.musics[0]);
    rl::unload_music_stream(self.musics[0]);
  }
  
  if(flags & GameplayState.FRIGHTEN_MODE) {
    self.musics[0] = rl::load_music_stream(GHOST_FRIGHTEN_SFX);
    return;
  }

  switch(type) {
    case SPUR_MODE_1: path = GHOST_SPURT_1_SFX;      break;
    case SPUR_MODE_2: path = GHOST_SPURT_2_SFX;      break;
    case SPUR_MODE_3: path = GHOST_SPURT_3_SFX;      break;
    case SPUR_MODE_4: path = GHOST_SPURT_4_SFX;      break;
    case GO_HOME: path = GHOST_RETURN_HOME_SFX;  break;
    default:          path = GHOST_NORMAL_SPEED_SFX; break;
  }

  self.musics[0] = rl::load_music_stream(path);
}

fn void AudioManager.update_pacman_music(&self, bool dot_eaten, TimeSpan dt) {
  static TimeSpan duration = 0.f;
  
  if(dot_eaten) {
    duration = rl::get_music_time_lenght(self.musics[1]) / 2;
    rl::resume_music_stream(self.musics[1]);
    return;
  }

  duration -= dt;
  if(duration <= 0.f) {
    duration = 0.f;
    rl::pause_music_stream(self.musics[1]);

    // set the music to beginning
    float time_left = 1 - rl::get_music_time_played(self.musics[1]);
    rl::seek_music_stream(self.musics[1], 0.f);
  }
}

// bool dot_eaten, 
fn void AudioManager.update_sound(&self, Uint8 flags, bool fruit_eaten) {
  const PACMAN_EATEN_SFX = "assets/sfx/fail.wav";
  const GHOST_EATEN_SFX  = "assets/sfx/pacman-eating-ghost.wav";
  const FRUIT_EATEN_SFX  = "assets/sfx/pacman-eating-fruit.wav";

  ZString path = "";
  
  if(self.sound == null) { self.sound = mem::new(Sound); }
  else { rl::stop_sound(*self.sound); }

  switch {
    case fruit_eaten:
      path = FRUIT_EATEN_SFX;
      break;
    case (bool)(flags & GameplayState.RESET_LEVEL):
      path = PACMAN_EATEN_SFX;
      break;
    case (bool)(flags & GameplayState.GHOST_EATEN):
      path = GHOST_EATEN_SFX;
      break;
  }

  *self.sound = rl::load_sound(path);
  rl::play_sound(*self.sound);
}

fn void AudioManager.free(&self) {
  free(self.sound);
  rl::unload_music_stream(self.musics[0]);
  rl::unload_music_stream(self.musics[1]);
}
