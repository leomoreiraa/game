/// @description Inserir descrição aqui
// Você pode escrever seu código neste editor
// Evento Create do obj_music_controller

// Tocar a música de fundo em loop
if (!audio_is_playing(snd_background)) {
    audio_play_sound(snd_background, 1, true);
}