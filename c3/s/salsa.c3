module salsa;

fn uint add32(uint left, uint right) {
    return (uint)(((ulong)left + (ulong)right) & 0xFFFFFFFFul);
}

fn uint rotate_left(uint value, uint amount) {
    return (value << amount) | (value >> (32 - amount));
}

fn void quarter_round(uint* state, usz first, usz second, usz third, usz fourth) {
    state[second] ^= rotate_left(add32(state[first], state[fourth]), 7);
    state[third] ^= rotate_left(add32(state[second], state[first]), 9);
    state[fourth] ^= rotate_left(add32(state[third], state[second]), 13);
    state[first] ^= rotate_left(add32(state[fourth], state[third]), 18);
}

fn void store_u32_le(char* output, usz offset, uint value) {
    for (usz byte = 0; byte < 4; byte += 1)
        output[offset + byte] = (char)(value >> (byte * 8));
}

// Reproduce the pinned 16-word Salsa core variant; this is not a stream cipher.
fn long salsa(int* input, usz length, char* output, usz output_capacity)
    @export("salsa") {
    if (input == null || length != 16) return -1;
    uint[16] original;
    for (usz index = 0; index < 16; index += 1) original[index] = (uint)input[index];
    if (output == null || output_capacity < 64) return -2;

    uint[16] state;
    for (usz index = 0; index < 16; index += 1) state[index] = original[index];
    for (usz round = 0; round < 10; round += 1) {
        quarter_round(&state[0], 0, 4, 8, 12);
        quarter_round(&state[0], 5, 9, 13, 1);
        quarter_round(&state[0], 10, 14, 2, 6);
        quarter_round(&state[0], 15, 3, 7, 11);
        quarter_round(&state[0], 0, 1, 2, 3);
        quarter_round(&state[0], 5, 6, 7, 4);
        quarter_round(&state[0], 10, 11, 8, 9);
        quarter_round(&state[0], 15, 12, 13, 14);
    }
    for (usz index = 0; index < 16; index += 1) {
        state[index] = add32(state[index], original[index]);
        store_u32_le(output, index * 4, state[index]);
    }
    return 64;
}
