module rl;

extern fn void set_texture_filter(Texture2D texture, CInt filter) @extern("SetTextureFilter");

extern fn void set_texture_wrap(Texture2D texture, CInt wrap) @extern("SetTextureWrap");

extern fn Texture2D load_texture(ZString file_name) @extern("LoadTexture");

extern fn bool is_texture_valid(Texture2D texture) @extern("IsTextureValid");

extern fn void draw_texture(Texture2D texture, int pos_x, int pos_y, Color tint) @extern("DrawTexture");

extern fn void draw_texture_v(Texture2D texture, float[<2>] pos, Color tint) @extern("DrawTextureV");

extern fn void draw_texture_ex(Texture2D texture, float[<2>] position, float rotation, float scale, Color tint) @extern("DrawTextureEx");

extern fn void draw_texture_pro(Texture2D texture, Rectangle source, Rectangle dest, float[<2>] origin, float rotation, Color tint) @extern("DrawTexturePro");

extern fn void unload_texture(Texture2D texture) @extern("UnloadTexture");
