// Evento de colisão do obj_destructible com obj_player
if (other.sprite_index == spr_player_dash) {
    instance_destroy();
}