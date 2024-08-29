// Evento etapa personagem

#region Control
key_right = keyboard_check(vk_right); // Move para direita
key_left = keyboard_check(vk_left);   // Move para esquerda
key_up = keyboard_check(vk_up);       // Move para cima
key_down = keyboard_check(vk_down);   // Move para baixo
key_jump = keyboard_check_pressed(ord("C"));  // Move para pula
key_dash = keyboard_check_pressed(ord("X"));  // Move para dash
#endregion

#region Variables
if (!variable_global_exists("coyote_time")) {
    global.coyote_time = 0;
}
if (!variable_instance_exists(id, "dash_cooldown")) {
    dash_cooldown = 0;
}
if (!variable_instance_exists(id, "dashes_left")) {
    dashes_left = 1; // Limitar o dash por sala
}
#endregion

#region Move
var move = key_right - key_left;

if (!is_dashing) {
    hspd = move * spd;
    if (!key_jump) {
        vspd += grv;
    }
} else {
    // Aplicar gravidade e desaceleração à velocidade residual
    vspd += grv;
}

// Lógica de movimento normal
vspd += grv;

// Clamp vertical speed
vspd = clamp(vspd, -20, 20);

if (hspd != 0) image_xscale = sign(hspd);

// Colisão H
if (place_meeting(x + hspd + sign(hspd), y, obj_wall) || place_meeting(x + hspd + sign(hspd), y, obj_destructible)) {
    while (!place_meeting(x + sign(hspd), y, obj_wall) && !place_meeting(x + sign(hspd), y, obj_destructible)) {
        x += sign(hspd);
    }
    x -= sign(hspd); // Ajustar a posição para ficar a 1 pixel de distância
    hspd = 0; // Bloquear movimento na direção da parede
    sprite_index = spr_player_idle; // Alterar para sprite de idle
}

x += hspd;

// Colisão V
if (place_meeting(x, y + vspd, obj_wall) || place_meeting(x, y + vspd, obj_destructible)) {
    while (!place_meeting(x, y + sign(vspd), obj_wall) && !place_meeting(x, y + sign(vspd), obj_destructible)) {
        y += sign(vspd);
    }
    vspd = 0;
    dable = true; // Resetar dash quando tocar no chão
    dash_reset_collected = false; // Resetar a flag de dash reset quando tocar no chão
    is_dashing = false; // Resetar o estado de dashing quando tocar no chão
    global.coyote_time = 15; // Resetar o coyote time quando tocar no chão
} else {
    global.coyote_time = max(global.coyote_time - 1, 0); // Diminuir o coyote time
}

y += vspd;
#endregion

#region Jump
if (!is_dashing && dash_cooldown == 0 && (place_meeting(x, y + 1, obj_wall) || place_meeting(x, y + 1, obj_destructible) || global.coyote_time > 0)) {
    if (key_jump) {
        vspd = jspd;
        dable = true; // Permitir dash após pular
        global.coyote_time = 0; // Resetar o coyote time após pular
    }
    dash_reset_collected = false; // Resetar a flag de dash reset quando tocar no chão
} else if (!keyboard_check(ord("C")) && vspd < 0) {
    vspd = 0; // Parar de subir se a tecla de pulo não estiver pressionada
}
#endregion

#region Dash
if (dtimer > 0) {
    dtimer--;
    is_dashing = true;
    sprite_index = spr_player_dash; // Alterar o sprite para spr_player_dash durante o dash
    hspd = dash_hspd;
    vspd = dash_vspd;

    // Verificar colisão com obj_destructible durante o dash
    if (place_meeting(x + hspd, y + vspd, obj_destructible)) {
        var instance = instance_place(x + hspd, y + vspd, obj_destructible);
        if (instance != noone) {
            with (instance) {
                instance_destroy();
            }
            // Empurrar o jogador para trás e parar o dash
            hspd = 0; // Parar o movimento horizontal
            vspd = 0; // Parar o movimento vertical
            is_dashing = false; // Parar o dash
            sprite_index = spr_player_idle; // Alterar para sprite de idle
            dtimer = 0; // Resetar o timer do dash
            dash_cooldown = 5; // Iniciar cooldown de 5 frames
        }
    }

    // Verificar colisão com obj_wall durante o dash
    if (place_meeting(x + hspd, y + vspd, obj_wall)) {
        // Parar o dash
        hspd = 0; // Parar o movimento horizontal
        vspd = 0; // Parar o movimento vertical
        is_dashing = false; // Parar o dash
        sprite_index = spr_player_idle; // Alterar para sprite de idle
        dtimer = 0; // Resetar o timer do dash
        dash_cooldown = 5; // Iniciar cooldown de 5 frames
    }
} else if (key_dash && dable && !is_dashing && dash_cooldown == 0 && dashes_left > 0) {
    dtimer = dtime; // Definir a duração do dash para 15 frames
    is_dashing = true;
    sprite_index = spr_player_dash; // Alterar o sprite para spr_player_dash durante o dash
    dable = false; // Desabilitar dash até tocar no chão novamente
    dashes_left--; // Reduzir o número de dashes restantes

    // Se nenhuma tecla de direção for pressionada, usar a direção do sprite
    if (key_right == 0 && key_left == 0 && key_up == 0 && key_down == 0) {
        dash_hspd = image_xscale * dspd;
        dash_vspd = 0;
    } else {
        dash_hspd = (key_right - key_left) * dspd;
        dash_vspd = (key_down - key_up) * dspd;

        // Normalizar a velocidade do dash nas direções diagonais
        if (dash_hspd != 0 && dash_vspd != 0) {
            var dash_length = sqrt(sqr(dash_hspd) + sqr(dash_vspd));
            dash_hspd = (dash_hspd / dash_length) * dspd;
            dash_vspd = (dash_vspd / dash_length) * dspd;
        }
    }
} else {
    is_dashing = false;
    dtimer = 0; // Resetar o timer do dash para garantir que o dash não continue
    if (dash_cooldown > 0) {
        dash_cooldown--; // Diminuir o cooldown do dash
    }
}
#endregion

#region Animation
if (is_dashing) {
    sprite_index = spr_player_dash;
} else if (hspd != 0 || vspd != 0) {
    sprite_index = spr_player_run;
} else {
    sprite_index = spr_player_idle;
}
#endregion

#region Collect Dash Reset
if (place_meeting(x, y, obj_dash_reset)) {
    var dash_reset_instance = instance_place(x, y, obj_dash_reset);
    if (dash_reset_instance != noone) {
        with (dash_reset_instance) {
            instance_destroy();
        }
        dable = true; // Permitir dash após coletar o objeto de reset
        dash_reset_collected = true; // Marcar que o objeto de reset foi coletado
        dashes_left++; // Incrementar o número de dashes disponíveis
    }
}
#endregion

#region Screen Wrap
if (x > room_width) {
    x = 0;
} else if (x < 0) {
    x = room_width;
}

if (y > room_height) {
    y = 0;
} else if (y < 0) {
    y = room_height;
}
#endregion

#region Win Condition
if (place_meeting(x, y, obj_win)) {
    var win_instance = instance_place(x, y, obj_win);
    if (win_instance != noone) {
        with (win_instance) {
            instance_destroy();
        }
        // Resetar dashes e ir para a próxima sala
        dashes_left = 1;
        room_goto_next();
    }
}
#endregion

#region Position Correction
// Função para corrigir a posição do personagem se ele estiver dentro de uma hitbox
function correct_position() {
    var directions = [
        [2, 0],  // Direita
        [-2, 0], // Esquerda
        [0, 2],  // Baixo
        [0, -2]  // Cima
    ];

    for (var i = 0; i < array_length(directions); i++) {
        if (place_meeting(x, y, obj_wall)) {
            x += directions[i][0];
            y += directions[i][1];
        }
    }
}

// Chamar a função de correção de posição
correct_position();
#endregion