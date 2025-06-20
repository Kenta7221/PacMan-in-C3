module rl;

extern fn Font load_font(char *fileName) @extern("LoadFont");

extern fn Font load_font_ex(char *fileName, CInt fontSize, CInt *codepoints, CInt codepointCount) @extern("LoadFontEx");

extern fn bool is_font_valid(Font font) @extern("IsFontValid");

extern fn Vector2 measure_text_font(Font font, char *text, float fontSize, float spacing) @extern("MeasureTextEx");   

extern fn void draw_text_ex(Font font, char *text,  Vector2 position, float fontSize, float spacing, Color tint) @extern("DrawTextEx");

extern fn void draw_text_pro(Font font, char *text, Vector2 position, Vector2 origin, float rotation, float fontSize, float spacing, Color tint) @extern("DrawTextPro");

extern fn void unload_font(Font font)  @extern("UnloadFont");
