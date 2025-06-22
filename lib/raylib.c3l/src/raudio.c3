module rl;

/*

Index of this module:
// Audio device management functions
// Sound management functions
// Music management functions

*/

alias AudioCallback = fn void(void* buffer_data, uint frames);

//------------------------------------------------------------------------------------
// Audio devide management functions
//------------------------------------------------------------------------------------

extern fn void init_audio_device() @extern("InitAudioDevice");

extern fn void close_audio_device() @extern("CloseAudioDevice");

<*
 Set master volume (listener)
 @require volume >= 0.f && volume <= 1.f
*>
extern fn void set_master_volume(float volume) @extern("SetMasterVolume");

<*
 Get master volume (listener)
*>
extern fn float get_master_volume() @extern("GetMasterVolume");

//------------------------------------------------------------------------------------
// Sound management functions
//------------------------------------------------------------------------------------

extern fn Sound load_sound(char *file_name) @extern("LoadSound");

extern fn void unload_sound(Sound sound) @extern("UnloadSound"); 

extern fn bool is_sound_valid(Sound sound) @extern("IsSoundValid");

extern fn void update_sound(Sound sound, void *data, CInt sample_count) @extern("UpdateSound");

extern fn void play_sound(Sound sound) @extern("PlaySound");

extern fn void stop_sound(Sound sound) @extern("StopSound");

extern fn bool is_sound_playing(Sound sound) @extern("IsSoundPlaying");

//------------------------------------------------------------------------------------
// Music management functions
//------------------------------------------------------------------------------------

extern fn Music load_music_stream(char *file_name) @extern("LoadMusicStream");

extern fn void unload_music_stream(Music music) @extern("UnloadMusicStream"); 

extern fn void play_musing_stream(Music music) @extern("PlayMusicStream");

extern fn bool is_music_valid(Music music) @extern("IsMusicValid");

extern fn void stop_music_stream(Music music) @extern("StopMusicStream");

extern fn void pause_music_stream(Music music) @extern("PauseMusicStream");

extern fn void resume_music_stream(Music music) @extern("ResumeMusicStream");

extern fn bool is_music_stream_playing(Music music) @extern("IsMusicStreamPlaying");

extern fn void update_music_stream(Music music) @extern("UpdateMusicStream");

extern fn float get_music_time_played(Music music) @extern("GetMusicTimePlayed");

extern fn float get_music_time_lenght(Music music) @extern("GetMusicTimeLength");

extern fn void play_music_stream(Music music) @extern("PlayMusicStream");

<*
 Set volume for music (1.0 is max level)
 @require volume >= 0.f && volume <= 1.f
*>
extern fn void set_music_volume(Music music, float volume) @extern("SetMusicVolume");
