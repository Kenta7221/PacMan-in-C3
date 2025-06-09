module animator;

import rl;
import gl;

const FLIP_HORIZONTALLY = 0x0F;
const FLIP_VERTICALLY   = 0xF0;

struct Animator {
  Texture2D *atlas_ptr;

  Uint8 start;
  Uint8 end;
  Uint8 curr_image;
  
  TimeSpan switch_time;
  TimeSpan total_time;
}

<*
 @require atlas_ptr != null : "Atlas pointer is null"
*>
fn void Animator.init(&animator, Texture2D *atlas_ptr, Uint8 start, Uint8 end, TimeSpan switch_time) {
  animator.atlas_ptr = atlas_ptr;
  animator.start = start;
  animator.end = end;
  animator.curr_image = start;
  animator.switch_time = switch_time;
  animator.total_time = 0.f;
}

fn void Animator.reset(&animator) {
  animator.curr_image = animator.start;
  animator.total_time = 0.f;
}

fn void Animator.update_count(&animator, Uint8 start, Uint8 end) {
  animator.start = start;
  animator.end = end;

  if(animator.curr_image < animator.start || animator.curr_image > animator.end) animator.curr_image = animator.start;
}

fn void Animator.update_everything(&animator, Uint8 start, Uint8 end, TimeSpan switch_time) {
  animator.start = start;
  animator.end = end;
  animator.curr_image = animator.start;
  animator.switch_time = switch_time;
  animator.total_time = 0.f;
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
