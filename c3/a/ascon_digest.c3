module ascon_digest;

const usz MAX_MESSAGE_BYTES = 4096;

fn ulong rotate_right(ulong value, usz count) {
    return (value >> count) | (value << (64 - count));
}

fn void permute(ulong* state, usz rounds) {
    ulong[12] constants = {0xf0, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5,
                           0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b};
    usz first = rounds == 12 ? 0 : 4;
    for (usz round = first; round < 12; round++) {
        ulong x0 = state[0]; ulong x1 = state[1]; ulong x2 = state[2];
        ulong x3 = state[3]; ulong x4 = state[4];
        ulong c = constants[round];
        ulong t0 = x0 ^ x1 ^ x2 ^ x3 ^ c ^ (x1 & (x0 ^ x2 ^ x4 ^ c));
        ulong t1 = x0 ^ x2 ^ x3 ^ x4 ^ c ^ ((x1 ^ x2 ^ c) & (x1 ^ x3));
        ulong t2 = x1 ^ x2 ^ x4 ^ c ^ (x3 & x4);
        ulong t3 = x0 ^ x1 ^ x2 ^ c ^ (~x0 & (x3 ^ x4));
        ulong t4 = x1 ^ x3 ^ x4 ^ ((x0 ^ x4) & x1);
        state[0] = t0 ^ rotate_right(t0, 19) ^ rotate_right(t0, 28);
        state[1] = t1 ^ rotate_right(t1, 39) ^ rotate_right(t1, 61);
        state[2] = ~(t2 ^ rotate_right(t2, 1) ^ rotate_right(t2, 6));
        state[3] = t3 ^ rotate_right(t3, 10) ^ rotate_right(t3, 17);
        state[4] = t4 ^ rotate_right(t4, 7) ^ rotate_right(t4, 41);
    }
}

fn void write_u64_be(char* output, usz offset, ulong value) {
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(value >> (56 - byte * 8));
    }
}

fn long ascon_digest_impl(long* input, usz length, char* output, usz capacity) {
    if (input == null || length < 2) return -1;
    long variant = input[0];
    long message_length_value = input[1];
    if ((variant != 0 && variant != 1) || message_length_value < 0 ||
        message_length_value > (long)MAX_MESSAGE_BYTES || length != (usz)message_length_value + 2) {
        return -1;
    }
    usz message_length = (usz)message_length_value;
    for (usz index = 0; index < message_length; index++) {
        if (input[index + 2] < 0 || input[index + 2] > 255) return -1;
    }

    ulong[5] state;
    if (variant == 0) {
        state[0] = 0xee9398aadb67f03d; state[1] = 0x8bb21831c60f1002;
        state[2] = 0xb48a92db98d5da62; state[3] = 0x43189921b8f8e3e8;
        state[4] = 0x348fa5c9d525e140;
    } else {
        state[0] = 0x01470194fc6528a6; state[1] = 0x738ec38ac0adffa7;
        state[2] = 0x2ec8e3296c76384c; state[3] = 0xd6f6a54d7f52377d;
        state[4] = 0xa13c42a223be8d87;
    }
    usz rounds = variant == 0 ? 12 : 8;
    usz complete_length = message_length - message_length % 8;
    for (usz offset = 0; offset < complete_length; offset += 8) {
        ulong word = 0;
        for (usz byte = 0; byte < 8; byte++) word = (word << 8) | (ulong)input[offset + byte + 2];
        state[0] ^= word;
        permute(&state[0], rounds);
    }
    usz tail_length = message_length - complete_length;
    ulong final_word = ((ulong)0x80) << (56 - tail_length * 8);
    for (usz byte = 0; byte < tail_length; byte++) {
        final_word |= (ulong)input[complete_length + byte + 2] << (56 - byte * 8);
    }
    state[0] ^= final_word;
    permute(&state[0], 12);

    if (output == null || capacity < 32) return -2;
    for (usz block = 0; block < 4; block++) {
        write_u64_be(output, block * 8, state[0]);
        if (block != 3) permute(&state[0], rounds);
    }
    return 32;
}

fn long ascon_digest(long* input, usz length, char* output, usz capacity)
    @export("ascon_digest") {
    return ascon_digest_impl(input, length, output, capacity);
}
