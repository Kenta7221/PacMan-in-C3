module animator;

import rl;
import gl;

const FLIP_HORIZONTALLY = 0x0F;
const FLIP_VERTICALLY   = 0xF0;

interface AnimatorHandler {
  fn void update_animation(TimeSpan dt);
}

struct Animator {
  Rectangle uv_rect;
  Texture2D *atlas_ptr;

  Uint8 start;
  Uint8 end;
  Uint8 curr_image;
  
  TimeSpan switch_time;
  TimeSpan total_time;
}

<*
 @param [&in] atlas_ptr : "Atlas pointer is null"
*>
fn void Animator.init(&self, Texture2D *atlas_ptr, Uint8 start, Uint8 end, TimeSpan switch_time) {
  self.uv_rect = {1, 1, gl::SPRITE_SIZE, gl::SPRITE_SIZE};
  self.atlas_ptr = atlas_ptr;
  self.start = start;
  self.end = end;
  self.curr_image = start;
  self.switch_time = switch_time;
  self.total_time = 0.f;
}

fn void Animator.reset(&self) {
  self.uv_rect = {1, 1, gl::SPRITE_SIZE, gl::SPRITE_SIZE};
  self.curr_image = self.start;
  self.total_time = 0.f;
}

fn void Animator.update_swtich_time(&self, TimeSpan switch_time) {
  self.curr_image = 0;
  self.switch_time = switch_time;
}

fn void Animator.update_count(&self, Uint8 start, Uint8 end) {
  self.start = start;
  self.end = end;

  if(self.curr_image < self.start || self.curr_image > self.end) self.curr_image = self.start;
}

fn void Animator.update_frame(&self, Uint8 row, TimeSpan dt, Uint8 flip = 0) {
  self.total_time += dt;

  if(self.total_time >= self.switch_time) {
    self.total_time -= self.switch_time;
    self.curr_image++;

    if(self.curr_image >= self.end) self.curr_image = self.start;
  }

  self.uv_rect = {
    (float)(self.curr_image * gl::SPRITE_SIZE + self.curr_image * gl::PADDING + gl::PADDING),
    (float)(row * gl::SPRITE_SIZE + row * gl::PADDING + gl::PADDING),
    gl::SPRITE_SIZE,
    gl::SPRITE_SIZE
  };

  if(flip & FLIP_HORIZONTALLY) self.uv_rect.width  *= -1;
  if(flip & FLIP_VERTICALLY)   self.uv_rect.height *= -1;
}

fn Rectangle Animator.get_src(&animator, Uint8 row, TimeSpan dt, Uint8 flip = 0) {
  animator.total_time += dt;

  if(animator.total_time >= animator.switch_time) {
    animator.total_time -= animator.switch_time;
    animator.curr_image++;

    if(animator.curr_image >= animator.end) animator.curr_image = animator.start;
  }
   
  Rectangle src = {
    (float)(animator.curr_image * gl::SPRITE_SIZE + animator.curr_image * gl::PADDING + gl::PADDING),
    (float)(row * gl::SPRITE_SIZE + row * gl::PADDING + gl::PADDING),
    gl::SPRITE_SIZE,
    gl::SPRITE_SIZE
  };

  if(flip & FLIP_HORIZONTALLY) src.width  *= -1;
  if(flip & FLIP_VERTICALLY)   src.height *= -1;

  return src;
}
