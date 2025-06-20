module rl;

//----------------------------------------------------------------------------------------------------
// Structures Definition
//----------------------------------------------------------------------------------------------------

struct Vector2 {
  float x;
  float y;
}

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

// Opaque structs declaration
// NOTE: Actual structs are defined internally in raudio module
typedef AudioBufferRef = void*;
typedef AudioProcessorRef = void*;

// AudioStream, custom audio stream
struct AudioStream {
  AudioBufferRef buffer;       // Pointer to internal data used by the audio system
  AudioProcessorRef processor; // Pointer to internal data processor, useful for audio effects

  uint sample_rate;            // Frequency (samples per second)
  uint sample_size;            // Bit depth (bits per sample): 8, 16, 32 (24 not supported)
  uint channels;               // Number of channels (1-mono, 2-stereo, ...)
}

// Sound
struct Sound {
  AudioStream stream; // Audio stream
  uint frame_count;   // Total number of frames (considering channels)
}

// Music, audio stream, anything longer than ~10 seconds should be streamed
struct Music {
  AudioStream stream; // Audio stream
  uint frame_count;   // Total number of frames (considering channels)
  bool looping;       // Music looping enable

  int ctx_type;       // Type of music context (audio filetype)
  void* ctx_data;     // Audio context data, depends on type
}
