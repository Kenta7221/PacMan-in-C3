module audio_manager;

import std::io;

import rl;
import gl;

import ghost;
import game_ctx::gameplay;

/*

Index of this module:
// Struct, enums and methods definitions

*/

//------------------------------------------------------------------------------------
// Struct, enums and methods definitions
//------------------------------------------------------------------------------------

enum QueueState : Uint8 (inline Uint8 state) {
  ACTIVATE_SPEED_CYCLE	 = 1 << 0, 
  ACTIVATE_FRIGHTEN_MODE = 1 << 1,
  ACTIVATE_GO_HOME       = 1 << 2,
  PLAYING_SPEED_CYCLE	 = 1 << 3, 
  PLAYING_FRIGHTEN_MODE  = 1 << 4,
  PLAYING_GO_HOME        = 1 << 5,
  INCREMENT_SPEED_CYCLE  = 1 << 6
}

struct AudioManager {
  Uint8 priority_queue; // To deal with switching music

  Music[2] musics; // One for ghost and pacman
  Sound* sound;
}

fn void? AudioManager.init(&self) {
  const GHOST_NORMAL_SPEED_SFX = "assets/sfx/ghost-normal-speed.wav";
  const PACMAN_EATING_SFX      = "assets/sfx/pacman-eating-dot.wav";

  self.priority_queue = 0;
  self.priority_queue |= QueueState.PLAYING_SPEED_CYCLE;  
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

fn void AudioManager.reset(&self) {
  const GHOST_NORMAL_SPEED_SFX = "assets/sfx/ghost-normal-speed.wav";
  const PACMAN_EATING_SFX      = "assets/sfx/pacman-eating-dot.wav";

  self.priority_queue = 0;
  self.priority_queue |= QueueState.PLAYING_SPEED_CYCLE;;
    
  self.sound = null;

  self.musics[0] = rl::load_music_stream(GHOST_NORMAL_SPEED_SFX);
  if(!rl::is_music_valid(self.musics[0])) {
    io::eprintn("Ghost normal speed music has not been loaded!");
    return;
  }

  self.musics[1] = rl::load_music_stream(PACMAN_EATING_SFX);
  if(!rl::is_music_valid(self.musics[1])) {
    io::eprintn("PacMan eating dot music has not been loaded!");
    return;
  }
    
  rl::play_music_stream(self.musics[0]);  
  rl::play_music_stream(self.musics[1]);
}

fn void AudioManager.disable_previous_ghost_music(&self) @private @inline {
  const ALL_MUSIC_PLAYING_MASK = 0x38;

  self.priority_queue |= ALL_MUSIC_PLAYING_MASK;
  self.priority_queue ^= ALL_MUSIC_PLAYING_MASK;
}

<*
 @param [&in] ghosts : "Ghosts were passed as null!"
*>
fn void AudioManager.update_ghost_music(&self, Ghost *ghosts, uint chase_cycle) {
  const ZString[5] GHOST_SPEED_SFXS = {
    "assets/sfx/ghost-normal-speed.wav",
    "assets/sfx/ghost-spurt-move-1.wav",
    "assets/sfx/ghost-spurt-move-2.wav",
    "assets/sfx/ghost-spurt-move-3.wav",
    "assets/sfx/ghost-spurt-move-4.wav"
  };
  const GHOST_FRIGHTEN_SFX     = "assets/sfx/ghost-frighten.wav";
  const GHOST_RETURN_HOME_SFX  = "assets/sfx/ghost-go-home.wav";
  
  if(self.priority_queue & QueueState.PLAYING_GO_HOME) {
    bool stop_music = true;
    if(self.priority_queue & QueueState.INCREMENT_SPEED_CYCLE) {
      self.priority_queue ^= QueueState.INCREMENT_SPEED_CYCLE;
      self.priority_queue |= QueueState.PLAYING_SPEED_CYCLE;
    }
    
    for(Uint8 i = 0; i < 3; i++) {
      if(ghosts[i].state_flags & GhostState.DEAD || ghosts[i].state_flags & GhostState.ENTERING_SPAWN) {
	stop_music = false;
	break;
      }
    } 
   
    if(!stop_music) {
      rl::update_music_stream(self.musics[0]);
      return;
    }
    
    // After the ghost enters the spawn and the next update begins, now all the
    // playing musics change to activate which will make it to play the previous song
    // or play the new state depending on priority
    self.priority_queue ^= QueueState.PLAYING_GO_HOME;
    self.priority_queue >>= 3;
  }

  ZString path = "";
  
  switch {
    case (bool)(self.priority_queue & QueueState.ACTIVATE_GO_HOME):
      path = GHOST_RETURN_HOME_SFX;
      self.priority_queue ^= QueueState.ACTIVATE_GO_HOME;
      self.priority_queue |= QueueState.PLAYING_GO_HOME;
      break;
    case (bool)(self.priority_queue & QueueState.ACTIVATE_FRIGHTEN_MODE):
      path = GHOST_FRIGHTEN_SFX;
      self.disable_previous_ghost_music();
      self.priority_queue ^= QueueState.ACTIVATE_FRIGHTEN_MODE;
      self.priority_queue |= QueueState.PLAYING_FRIGHTEN_MODE;
      break;
    case (bool)(self.priority_queue & QueueState.INCREMENT_SPEED_CYCLE):
      self.priority_queue ^= QueueState.INCREMENT_SPEED_CYCLE;
      self.priority_queue |= QueueState.ACTIVATE_SPEED_CYCLE;
      nextcase;
    case (bool)(self.priority_queue & QueueState.ACTIVATE_SPEED_CYCLE):
      path = GHOST_SPEED_SFXS[chase_cycle];
      self.disable_previous_ghost_music();
      self.priority_queue ^= QueueState.ACTIVATE_SPEED_CYCLE;
      self.priority_queue |= QueueState.PLAYING_SPEED_CYCLE;
      break;
    default:
      rl::update_music_stream(self.musics[0]);
      return;
  }

  if(rl::is_music_stream_playing(self.musics[0])) {
    rl::stop_music_stream(self.musics[0]);
    rl::unload_music_stream(self.musics[0]);
  }
  
  self.musics[0] = rl::load_music_stream(path);
  rl::play_music_stream(self.musics[0]);
}

fn void AudioManager.update_pacman_music(&self, bool dot_eaten, TimeSpan dt) {
  static TimeSpan duration = 0.f;
  
  if(dot_eaten) {
    duration = rl::get_music_time_lenght(self.musics[1]) / 2;
    rl::resume_music_stream(self.musics[1]);
  }

  duration -= dt;
  if(duration <= 0.f) {
    duration = 0.f;
    rl::pause_music_stream(self.musics[1]);

    // Set the music to beginning
    float time_left = 1 - rl::get_music_time_played(self.musics[1]);
    rl::seek_music_stream(self.musics[1], 0.f);
    return;
  }

  rl::update_music_stream(self.musics[1]);
}

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
    case (bool)(flags & GameplayFlags.RESET_LEVEL):
      path = PACMAN_EATEN_SFX;
      break;
    case (bool)(flags & GameplayFlags.GHOST_EATEN):
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
