module jump_game;

fn long jump_game(long* input, usz length) @export("jump_game") {
    if (input == null || length < 2 || length > 1025 || input[0] < 1 || input[0] > 1024 || length != (usz)input[0] + 1) return -2;
    usz n = (usz)input[0];
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] > 1000000) return -2;
    usz last_pos = n - 1;
    for (usz i = n; i > 0; i--) {
        usz index = i - 1;
        if (index + (usz)input[index + 1] >= last_pos) last_pos = index;
    }
    return last_pos == 0 ? 1 : 0;
}
