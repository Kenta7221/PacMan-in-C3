module timer;

import gl;

/*

Index of this module:
// Struct, const value and methods definitions
// Helper functions

*/

//------------------------------------------------------------------------------------
// Struct, const value and methods definitions
//------------------------------------------------------------------------------------

const TimeSpan INDEFINITE @private = TimeSpan.max / 2;

struct Timer {
  uint level;
  Uint8 which_cycle;
  
  TimeSpan elapsed_time;
  TimeSpan frighten_mode;
  TimeSpan cycle;
  TimeSpan dot_not_eaten;
}

fn void Timer.init(&self) {
  self.which_cycle = 1;
  self.level = 1;
  
  self.elapsed_time = 0.f;  
  self.frighten_mode = 0.f;
  self.cycle = 0.f;
  self.dot_not_eaten = 0.f;
}

fn void Timer.reset(&self) {
  self.which_cycle = 1;
  
  self.frighten_mode = 0.f;
  self.cycle = 0.f;
  self.dot_not_eaten = 0.f;
}


fn void Timer.update(&self, TimeSpan new_time) @inline {  
  self.elapsed_time = new_time;
}

fn void Timer.reset_dot_not_eaten(&self) @inline {
  self.dot_not_eaten = 0.f;
}

fn bool Timer.exceeds_dot_not_eaten_dur(&self, TimeSpan dt, bool dot_eaten) {
  if(dot_eaten) {
    self.dot_not_eaten = 0.f;
    return false;
  }

  self.dot_not_eaten += dt;
  
  if(self.level >= 1 && self.level <= 5) return self.dot_not_eaten > 4.f;

  return self.dot_not_eaten > 3.f;
}

fn bool Timer.end_frighten_mode(&self, TimeSpan dt, TimeSpan *duration) {
  TimeSpan dur = get_frighten_mode_dur(self.level);

  *duration = dur;
  
  // Immedietly end chase mode
  if(dur == INDEFINITE) return true;
  
  self.frighten_mode += dt;
  return self.frighten_mode > dur;
}

fn bool Timer.new_cycle(&self, TimeSpan dt) {
  TimeSpan duration = get_ghost_cycle_dur(self.level, self.which_cycle);

  // If in the last cycle ghost are indefinitely in chase mode
  if(duration == INDEFINITE) return false;
  
  self.cycle += dt;
  return self.cycle > duration;
}

//------------------------------------------------------------------------------------
// Helper functions
//------------------------------------------------------------------------------------

<*
 @require level > 0 : "ERROR: level val is out of bounds!"
*>
fn TimeSpan get_ghost_cycle_dur(uint level, uint cycle) @private {
  const TimeSpan[8][3] CYCLE_GHOST_MODE = {
    // Scatter, chase, scatter ...
    { 7, 20, 7, 20, 5, 20  , 5   , INDEFINITE }, // Lv. 1 
    { 7, 20, 7, 20, 5, 1033, 1/60, INDEFINITE }, // Lv. 2 - 4
    { 5, 20, 5, 20, 5, 1037, 1/60, INDEFINITE }, // Lv. 5+
  };

  // Clamping just in case
  cycle -= 1;
  if(cycle > 7 ) cycle = 7;
  
  if(level == 1) {
    return CYCLE_GHOST_MODE[0][cycle];
  } else if(level > 1 && level < 5) {
    return CYCLE_GHOST_MODE[1][cycle];
  }

  return CYCLE_GHOST_MODE[2][cycle];
}
<*
 @require level > 0 : "ERROR: level val is out of bounds!"
*>
fn TimeSpan get_frighten_mode_dur(uint level) @private {
  const TimeSpan[7] FRIGHTEN_MODE_DUR = {
    6,          // Lv. 1
    5,          // Lv. 2, 6, 10
    3,          // Lv. 4, 14
    4,          // Lv. 3
    2,          // Lv. 5, 7, 8, 11
    1,          // Lv. 9, 12, 13, 15, 16, 18
    INDEFINITE, // Lv. 17, 19+
  };

  switch(level) {
    case 1:
      return FRIGHTEN_MODE_DUR[0];
    case 2:
    case 6:
    case 10:
      return FRIGHTEN_MODE_DUR[1];
    case 4:
    case 14:
      return FRIGHTEN_MODE_DUR[2];
    case 3:
      return FRIGHTEN_MODE_DUR[3];
    case 5:
    case 7:
    case 8:
    case 11:
      return FRIGHTEN_MODE_DUR[4];
    case 9:
    case 12:
    case 13:
    case 15:
    case 16:
    case 18:
      return FRIGHTEN_MODE_DUR[4];
    default:
      return FRIGHTEN_MODE_DUR[5];
  }
}
