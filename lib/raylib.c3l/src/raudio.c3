module rl;

alias AudioCallback = fn void(void* buffer_data, uint frames);

extern fn void init_audio_device() @extern("InitAudioDevice");

extern fn void close_audio_device() @extern("CloseAudioDevice");

extern fn Music load_music_stream(char *file_name) @extern("LoadMusicStream");

extern fn void unload_musci_stream(Music music) @extern("UnloadMusicStream"); 

extern fn bool is_music_valid(Music music) @extern("IsMusicValid");

extern fn void update_music_stream(Music music) @extern("UpdateMusicStream");

extern fn float get_music_time_played(Music music) @extern("GetMusicTimePlayed");

extern fn void play_music_stream(Music music) @extern("PlayMusicStream");

<* Set volume for music (1.0 is max level) *>
extern fn void set_music_volume(Music music, float volume) @extern("SetMusicVolume");
