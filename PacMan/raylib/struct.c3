module rl;

//----------------------------------------------------------------------------------------------------
// Structures Definition
//----------------------------------------------------------------------------------------------------

struct Color {
  char r;
  char g;
  char b;
  char a;
}

struct Rectangle {
  float x;
  float y;
  float width;
  float height;
}

struct Texture2D {
  uint id;
  int width;
  int height;
  int minimaps;
  PixelFormat format;
}

struct Image {
  void *data;             // Image raw data
  int width;              // Image base width
  int height;             // Image base height
  int mipmaps;            // Mipmap levels, 1 by default
  int format;             // Data format (PixelFormat type)
}

struct GlyphInfo {
  int value;              // Character value (Unicode)
  int offsetX;            // Character offset X when drawing
  int offsetY;            // Character offset Y when drawing
  int advanceX;           // Character advance position X
  Image image;            // Character image data
}

struct Font {
  int baseSize;           // Base size (default chars height)
  int glyphCount;         // Number of glyph characters
  int glyphPadding;       // Padding around the glyph characters
  Texture2D texture;      // Texture atlas containing the glyphs
  Rectangle *recs;        // Rectangles in texture for the glyphs
  GlyphInfo *glyphs;      // Glyphs info data
}
