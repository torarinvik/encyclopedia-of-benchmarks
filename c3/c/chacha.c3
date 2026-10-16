module chacha;

const int CHACHA_WORDS = 16;
const int CHACHA_BYTES = 64;
const ulong WORD_MASK = 0xFFFF_FFFF;

fn ulong chacha_rotate_left(ulong value, uint count) {
    return ((value << count) | (value >> (32 - count))) & WORD_MASK;
}

fn void chacha_quarter_round(ulong* state, int a, int b, int c, int d) {
    state[a] = (state[a] + state[b]) & WORD_MASK;
    state[d] = chacha_rotate_left(state[d] ^ state[a], 16);
    state[c] = (state[c] + state[d]) & WORD_MASK;
    state[b] = chacha_rotate_left(state[b] ^ state[c], 12);
    state[a] = (state[a] + state[b]) & WORD_MASK;
    state[d] = chacha_rotate_left(state[d] ^ state[a], 8);
    state[c] = (state[c] + state[d]) & WORD_MASK;
    state[b] = chacha_rotate_left(state[b] ^ state[c], 7);
}

fn long chacha(long* input, usz length, char* output, usz output_capacity)
        @export("chacha") {
    if (input == null || length != CHACHA_WORDS) return -1;
    ulong[CHACHA_WORDS] initial;
    for (usz index = 0; index < CHACHA_WORDS; index++) {
        if (input[index] < 0 || input[index] > 4294967295) return -1;
        initial[index] = (ulong)input[index];
    }
    if (output == null || output_capacity < CHACHA_BYTES) return -2;

    ulong[CHACHA_WORDS] state;
    for (usz index = 0; index < CHACHA_WORDS; index++) state[index] = initial[index];
    for (int round = 0; round < 10; round++) {
        chacha_quarter_round(&state[0], 0, 4, 8, 12);
        chacha_quarter_round(&state[0], 1, 5, 9, 13);
        chacha_quarter_round(&state[0], 2, 6, 10, 14);
        chacha_quarter_round(&state[0], 3, 7, 11, 15);
        chacha_quarter_round(&state[0], 0, 5, 10, 15);
        chacha_quarter_round(&state[0], 1, 6, 11, 12);
        chacha_quarter_round(&state[0], 2, 7, 8, 13);
        chacha_quarter_round(&state[0], 3, 4, 9, 14);
    }
    for (usz index = 0; index < CHACHA_WORDS; index++) {
        uint word = (uint)((state[index] + initial[index]) & WORD_MASK);
        output[index * 4] = (char)(word & 255);
        output[index * 4 + 1] = (char)((word >> 8) & 255);
        output[index * 4 + 2] = (char)((word >> 16) & 255);
        output[index * 4 + 3] = (char)((word >> 24) & 255);
    }
    return CHACHA_BYTES;
}
