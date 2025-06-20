module rl;

//----------------------------------------------------------------------------------------------------
// Constants Definition
//----------------------------------------------------------------------------------------------------

alias TextureFilter = int;
const TextureFilter TEXTURE_FILTER_POINT     = 0;       // No filter, just pixel approximation
const TextureFilter TEXTURE_FILTER_BILINEAR  = 1;       // Linear filtering
const TextureFilter TEXTURE_FILTER_TRILINEAR = 2;       // Trilinear filtering (linear with mipmaps)
const TextureFilter TEXTURE_FILTER_ANISOTROPIC_4X  = 3; // Anisotropic filtering 4x
const TextureFilter TEXTURE_FILTER_ANISOTROPIC_8X  = 4; // Anisotropic filtering 8x
const TextureFilter TEXTURE_FILTER_ANISOTROPIC_16X = 5; // Anisotropic filtering 16x

const TEXTURE_WRAP_REPEAT = 0;                   // Repeats texture in tiled mode
const TEXTURE_WRAP_CLAMP  = 1;                   // Clamps texture to edge pixel in tiled mode
const TEXTURE_WRAP_MIRROR_REPEAT = 2;            // Mirrors and repeats the texture in tiled mode
const TEXTURE_WRAP_MIRROR_CLAMP  = 3;            // Mirrors and clamps to border the texture in tiled mode

// Pixel formats
// NOTE: Support depends on OpenGL version and platform
alias PixelFormat = int;
const PixelFormat PIXELFORMAT_UNCOMPRESSED_GRAYSCALE    = 1;  // 8 bit per pixel (no alpha)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA   = 2;  // 8*2 bpp (2 channels)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R5G6B5       = 3;  // 16 bpp
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R8G8B8       = 4;  // 24 bpp
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R5G5B5A1     = 5;  // 16 bpp (1 bit alpha)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R4G4B4A4     = 6;  // 16 bpp (4 bit alpha)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R8G8B8A8     = 7;  // 32 bpp
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R32          = 8;  // 32 bpp (1 channel - float)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R32G32B32    = 9;  // 32*3 bpp (3 channels - float)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R32G32B32A32 = 10; // 32*4 bpp (4 channels - float)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R16          = 11; // 16 bpp (1 channel - half float)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R16G16B16    = 12; // 16*3 bpp (3 channels - half float)
const PixelFormat PIXELFORMAT_UNCOMPRESSED_R16G16B16A16 = 13; // 16*4 bpp (4 channels - half float)
const PixelFormat PIXELFORMAT_COMPRESSED_DXT1_RGB       = 14; // 4 bpp (no alpha)
const PixelFormat PIXELFORMAT_COMPRESSED_DXT1_RGBA      = 15; // 4 bpp (1 bit alpha)
const PixelFormat PIXELFORMAT_COMPRESSED_DXT3_RGBA      = 16; // 8 bpp
const PixelFormat PIXELFORMAT_COMPRESSED_DXT5_RGBA      = 17; // 8 bpp
const PixelFormat PIXELFORMAT_COMPRESSED_ETC1_RGB       = 18; // 4 bpp
const PixelFormat PIXELFORMAT_COMPRESSED_ETC2_RGB       = 19; // 4 bpp
const PixelFormat PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA  = 20; // 8 bpp
const PixelFormat PIXELFORMAT_COMPRESSED_PVRT_RGB       = 21; // 4 bpp
const PixelFormat PIXELFORMAT_COMPRESSED_PVRT_RGBA      = 22; // 4 bpp
const PixelFormat PIXELFORMAT_COMPRESSED_ASTC_4X4_RGBA  = 23; // 8 bpp
const PixelFormat PIXELFORMAT_COMPRESSED_ASTC_8X8_RGBA  = 24; // 2 bpp


// Keyboard keys (US keyboard layout)
// NOTE: Use GetKeyPressed() to allow redefining
// required keys for alternative layouts
alias KeyboardKey = int;
const KeyboardKey KEY_NULL            = 0;        // Key: NULL, used for no key pressed
// Alphanumeric keys
const KeyboardKey KEY_APOSTROPHE      = 39;       // Key: '
const KeyboardKey KEY_COMMA           = 44;       // Key: ,
const KeyboardKey KEY_MINUS           = 45;       // Key: -
const KeyboardKey KEY_PERIOD          = 46;       // Key: .
const KeyboardKey KEY_SLASH           = 47;       // Key: /
const KeyboardKey KEY_ZERO            = 48;       // Key: 0
const KeyboardKey KEY_ONE             = 49;       // Key: 1
const KeyboardKey KEY_TWO             = 50;       // Key: 2
const KeyboardKey KEY_THREE           = 51;       // Key: 3
const KeyboardKey KEY_FOUR            = 52;       // Key: 4
const KeyboardKey KEY_FIVE            = 53;       // Key: 5
const KeyboardKey KEY_SIX             = 54;       // Key: 6
const KeyboardKey KEY_SEVEN           = 55;       // Key: 7
const KeyboardKey KEY_EIGHT           = 56;       // Key: 8
const KeyboardKey KEY_NINE            = 57;       // Key: 9
const KeyboardKey KEY_SEMICOLON       = 59;       // Key: ;
const KeyboardKey KEY_EQUAL           = 61;       // Key: =
const KeyboardKey KEY_A               = 65;       // Key: A | a
const KeyboardKey KEY_B               = 66;       // Key: B | b
const KeyboardKey KEY_C               = 67;       // Key: C | c
const KeyboardKey KEY_D               = 68;       // Key: D | d
const KeyboardKey KEY_E               = 69;       // Key: E | e
const KeyboardKey KEY_F               = 70;       // Key: F | f
const KeyboardKey KEY_G               = 71;       // Key: G | g
const KeyboardKey KEY_H               = 72;       // Key: H | h
const KeyboardKey KEY_I               = 73;       // Key: I | i
const KeyboardKey KEY_J               = 74;       // Key: J | j
const KeyboardKey KEY_K               = 75;       // Key: K | k
const KeyboardKey KEY_L               = 76;       // Key: L | l
const KeyboardKey KEY_M               = 77;       // Key: M | m
const KeyboardKey KEY_N               = 78;       // Key: N | n
const KeyboardKey KEY_O               = 79;       // Key: O | o
const KeyboardKey KEY_P               = 80;       // Key: P | p
const KeyboardKey KEY_Q               = 81;       // Key: Q | q
const KeyboardKey KEY_R               = 82;       // Key: R | r
const KeyboardKey KEY_S               = 83;       // Key: S | s
const KeyboardKey KEY_T               = 84;       // Key: T | t
const KeyboardKey KEY_U               = 85;       // Key: U | u
const KeyboardKey KEY_V               = 86;       // Key: V | v
const KeyboardKey KEY_W               = 87;       // Key: W | w
const KeyboardKey KEY_X               = 88;       // Key: X | x
const KeyboardKey KEY_Y               = 89;       // Key: Y | y
const KeyboardKey KEY_Z               = 90;       // Key: Z | z
const KeyboardKey KEY_LEFT_BRACKET    = 91;       // Key: [
const KeyboardKey KEY_BACKSLASH       = 92;       // Key: '\'
const KeyboardKey KEY_RIGHT_BRACKET   = 93;       // Key: ]
const KeyboardKey KEY_GRAVE           = 96;       // Key: `
// Function keys
const KeyboardKey KEY_SPACE           = 32;       // Key: Space
const KeyboardKey KEY_ESCAPE          = 256;      // Key: Esc
const KeyboardKey KEY_ENTER           = 257;      // Key: Enter
const KeyboardKey KEY_TAB             = 258;      // Key: Tab
const KeyboardKey KEY_BACKSPACE       = 259;      // Key: Backspace
const KeyboardKey KEY_INSERT          = 260;      // Key: Ins
const KeyboardKey KEY_DELETE          = 261;      // Key: Del
const KeyboardKey KEY_RIGHT           = 262;      // Key: Cursor right
const KeyboardKey KEY_LEFT            = 263;      // Key: Cursor left
const KeyboardKey KEY_DOWN            = 264;      // Key: Cursor down
const KeyboardKey KEY_UP              = 265;      // Key: Cursor up
const KeyboardKey KEY_PAGE_UP         = 266;      // Key: Page up
const KeyboardKey KEY_PAGE_DOWN       = 267;      // Key: Page down
const KeyboardKey KEY_HOME            = 268;      // Key: Home
const KeyboardKey KEY_END             = 269;      // Key: End
const KeyboardKey KEY_CAPS_LOCK       = 280;      // Key: Caps lock
const KeyboardKey KEY_SCROLL_LOCK     = 281;      // Key: Scroll down
const KeyboardKey KEY_NUM_LOCK        = 282;      // Key: Num lock
const KeyboardKey KEY_PRINT_SCREEN    = 283;      // Key: Print screen
const KeyboardKey KEY_PAUSE           = 284;      // Key: Pause
const KeyboardKey KEY_F1              = 290;      // Key: F1
const KeyboardKey KEY_F2              = 291;      // Key: F2
const KeyboardKey KEY_F3              = 292;      // Key: F3
const KeyboardKey KEY_F4              = 293;      // Key: F4
const KeyboardKey KEY_F5              = 294;      // Key: F5
const KeyboardKey KEY_F6              = 295;      // Key: F6
const KeyboardKey KEY_F7              = 296;      // Key: F7
const KeyboardKey KEY_F8              = 297;      // Key: F8
const KeyboardKey KEY_F9              = 298;      // Key: F9
const KeyboardKey KEY_F10             = 299;      // Key: F10
const KeyboardKey KEY_F11             = 300;      // Key: F11
const KeyboardKey KEY_F12             = 301;      // Key: F12
const KeyboardKey KEY_LEFT_SHIFT      = 340;      // Key: Shift left
const KeyboardKey KEY_LEFT_CONTROL    = 341;      // Key: Control left
const KeyboardKey KEY_LEFT_ALT        = 342;      // Key: Alt left
const KeyboardKey KEY_LEFT_SUPER      = 343;      // Key: Super left
const KeyboardKey KEY_RIGHT_SHIFT     = 344;      // Key: Shift right
const KeyboardKey KEY_RIGHT_CONTROL   = 345;      // Key: Control right
const KeyboardKey KEY_RIGHT_ALT       = 346;      // Key: Alt right
const KeyboardKey KEY_RIGHT_SUPER     = 347;      // Key: Super right
const KeyboardKey KEY_KB_MENU         = 348;      // Key: KB menu
// Keypad keys
const KeyboardKey KEY_KP_0            = 320;      // Key: Keypad 0
const KeyboardKey KEY_KP_1            = 321;      // Key: Keypad 1
const KeyboardKey KEY_KP_2            = 322;      // Key: Keypad 2
const KeyboardKey KEY_KP_3            = 323;      // Key: Keypad 3
const KeyboardKey KEY_KP_4            = 324;      // Key: Keypad 4
const KeyboardKey KEY_KP_5            = 325;      // Key: Keypad 5
const KeyboardKey KEY_KP_6            = 326;      // Key: Keypad 6
const KeyboardKey KEY_KP_7            = 327;      // Key: Keypad 7
const KeyboardKey KEY_KP_8            = 328;      // Key: Keypad 8
const KeyboardKey KEY_KP_9            = 329;      // Key: Keypad 9
const KeyboardKey KEY_KP_DECIMAL      = 330;      // Key: Keypad .
const KeyboardKey KEY_KP_DIVIDE       = 331;      // Key: Keypad /
const KeyboardKey KEY_KP_MULTIPLY     = 332;      // Key: Keypad *
const KeyboardKey KEY_KP_SUBTRACT     = 333;      // Key: Keypad -
const KeyboardKey KEY_KP_ADD          = 334;      // Key: Keypad +
const KeyboardKey KEY_KP_ENTER        = 335;      // Key: Keypad Enter
const KeyboardKey KEY_KP_EQUAL        = 336;      // Key: Keypad =
// Android key buttons
const KeyboardKey KEY_BACK            = 4;        // Key: Android back button
const KeyboardKey KEY_MENU            = 5;        // Key: Android menu button
const KeyboardKey KEY_VOLUME_UP       = 24;       // Key: Android volume up button
const KeyboardKey KEY_VOLUME_DOWN     = 25;       // Key: Android volume down button

// Mouse buttons
alias MouseButton = int;
const MOUSE_BUTTON_LEFT    = 0; // Mouse button left
const MOUSE_BUTTON_RIGHT   = 1; // Mouse button right
const MOUSE_BUTTON_MIDDLE  = 2; // Mouse button middle (pressed wheel)
const MOUSE_BUTTON_SIDE    = 3; // Mouse button side (advanced mouse device)
const MOUSE_BUTTON_EXTRA   = 4; // Mouse button extra (advanced mouse device)
const MOUSE_BUTTON_FORWARD = 5; // Mouse button forward (advanced mouse device)
const MOUSE_BUTTON_BACK    = 6; // Mouse button back (advanced mouse device)

// Mouse cursor
alias MouseCursor = int;
const MouseCursor MOUSE_CURSOR_DEFAULT       = 0;     // Default pointer shape
const MouseCursor MOUSE_CURSOR_ARROW         = 1;     // Arrow shape
const MouseCursor MOUSE_CURSOR_IBEAM         = 2;     // Text writing cursor shape
const MouseCursor MOUSE_CURSOR_CROSSHAIR     = 3;     // Cross shape
const MouseCursor MOUSE_CURSOR_POINTING_HAND = 4;     // Pointing hand cursor
const MouseCursor MOUSE_CURSOR_RESIZE_EW     = 5;     // Horizontal resize/move arrow shape
const MouseCursor MOUSE_CURSOR_RESIZE_NS     = 6;     // Vertical resize/move arrow shape
const MouseCursor MOUSE_CURSOR_RESIZE_NWSE   = 7;     // Top-left to bottom-right diagonal resize/move arrow shape
const MouseCursor MOUSE_CURSOR_RESIZE_NESW   = 8;     // The top-right to bottom-left diagonal resize/move arrow shape
const MouseCursor MOUSE_CURSOR_RESIZE_ALL    = 9;     // The omnidirectional resize/move cursor shape
const MouseCursor MOUSE_CURSOR_NOT_ALLOWED   = 10;    // The operation-not-allowed shape

const FLAG_VSYNC_HINT         = 0x00000040;   // Set to try enabling V-Sync on GPU
const FLAG_FULLSCREEN_MODE    = 0x00000002;   // Set to run program in fullscreen
const FLAG_WINDOW_RESIZABLE   = 0x00000004;   // Set to allow resizable window
const FLAG_WINDOW_UNDECORATED = 0x00000008;   // Set to disable window decoration (frame and buttons)
const FLAG_WINDOW_HIDDEN      = 0x00000080;   // Set to hide window
const FLAG_WINDOW_MINIMIZED   = 0x00000200;   // Set to minimize window (iconify)
const FLAG_WINDOW_MAXIMIZED   = 0x00000400;   // Set to maximize window (expanded to monitor)
const FLAG_WINDOW_UNFOCUSED   = 0x00000800;   // Set to window non focused
const FLAG_WINDOW_TOPMOST     = 0x00001000;   // Set to window always on top
const FLAG_WINDOW_ALWAYS_RUN  = 0x00000100;   // Set to allow windows running while minimized
const FLAG_WINDOW_TRANSPARENT = 0x00000010;   // Set to allow transparent framebuffer
const FLAG_WINDOW_HIGHDPI     = 0x00002000;   // Set to support HighDPI
const FLAG_WINDOW_MOUSE_PASSTHROUGH = 0x00004000; // Set to support mouse passthrough; only supported when FLAG_WINDOW_UNDECORATED
const FLAG_BORDERLESS_WINDOWED_MODE = 0x00008000; // Set to run program in borderless windowed mode
const FLAG_MSAA_4X_HINT       = 0x00000020;   // Set to try enabling MSAA 4X
const FLAG_INTERLACED_HINT    = 0x00010000;    // Set to try enabling interlaced video format (for V3D)

