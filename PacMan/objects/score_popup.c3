module score_popup;

import std::io;
import libc;

import rl;
import gl;

<*
 @param [inout] score_popup
*>
fn void handler(ScorePopup **score_popup,
			   Uint16[<2>] pos,
			   Uint8 ghost_eaten,
			   Uint16 fruit_points,
			   PopupState state,
			   EventType event) {
  switch(state) {
    case INIT:
      if((*score_popup) != null) nextcase UPDATE;
      *score_popup = (ScorePopup*)mem::new(ScorePopup);
      (*score_popup).init(event, pos, ghost_eaten, fruit_points)!!;
      break;
    case UPDATE:
      (*score_popup).update(event, pos, ghost_eaten, fruit_points);
      break;
    case DESTROY:
      if(score_popup == null) break;
      
      rl::unload_font((*score_popup).font);
      free((*score_popup));
      (*score_popup) = null;
    default:
      break;
  }
}

enum PopupState : inline Uint8 {
  NONE,
  INIT,
  UPDATE,
  DESTROY
}

struct ScorePopup {
  Font font;
  ZString str;
  Color color;
  Uint16[<2>] pos;
  TimeSpan total_time;
}

<*
 Returns the amount of points in ZString based on two events
 @require event == EventType.GHOST_EATEN || EventType.FRUIT_EATEN : "Passed wrong event type"
*>
fn void? ScorePopup.init(&self, EventType event, Uint16[<2>] pos, Uint8 ghost_eaten, Uint16 fruit_points) {
  const String FONT_FILENAME = "assets/fonts/pixgamer.ttf";

  self.font = rl::load_font_ex(FONT_FILENAME, gl::FONT_BASE_SIZE, null, 0);
  if(!rl::is_font_valid(self.font)) {
    io::printn("Font for score popup was not loaded!");
    return io::FILE_NOT_FOUND?;
  }

  self.str = (ZString)mem::new_array(char, 12);;
  Uint16 points;
  
  if(event == EventType.GHOST_EATEN) {
    points = ghost_eaten * 400;
    self.color = {0, 255, 255, 255};
  }
  else {
    points = fruit_points;
    self.color = {255, 200, 255, 255};
  }
  
  libc::sprintf(self.str, "%d", points);

  self.pos = (pos / gl::PIXEL_SCALED) * gl::PIXEL_SCALED;
  self.total_time = 0.f;
}

<*
 Returns the amount of points in ZString based on two events
 @require event == EventType.GHOST_EATEN || EventType.FRUIT_EATEN : "Passed wrong event type"
*>
fn void ScorePopup.update(&self, EventType event, Uint16[<2>] pos, Uint8 ghost_eaten, Uint16 fruit_points) {
  Uint16 points;
  
  if(event == EventType.GHOST_EATEN) {
    points = ghost_eaten * 400;
    self.color = {0, 255, 255, 255};
  }
  else {
    points = fruit_points;
    self.color = {255, 200, 255, 255};
  }
  
  libc::sprintf(self.str, "%d", points);

  // Clamp position to a tile
  self.pos = (pos / gl::PIXEL_SCALED) * gl::PIXEL_SCALED;
  self.total_time = 0.f;
}

fn bool ScorePopup.can_drawn(&self, TimeSpan dt) @inline {
  self.total_time += dt;
  return self.total_time <= 2.f;
}

fn void ScorePopup.draw(&self) {
  float[<2>] center_pos = self.pos;
  
  rl::draw_text_ex(self.font,
		   self.str,
		   center_pos,
		   gl::MIDDLE_TEXT_SIZE,
		   3.f,
		   self.color
  );
}

fn void ScorePopup.free(&self) {
  rl::unload_font(self.font);
}
