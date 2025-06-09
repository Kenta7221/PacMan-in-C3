module rl;

//----------------------------------------------------------------------------------------------------
// Basic shapes Definition
//----------------------------------------------------------------------------------------------------

extern fn void draw_rect_rec(Rectangle rec, Color color) @extern("DrawRectangleRec");

extern fn void draw_rect_v(float[<2>] position, float[<2>] size, Color color) @extern("DrawRectangleV");

extern fn bool check_coll_rect(Rectangle rec1, Rectangle rec2) @extern("CheckCollisionRecs");
