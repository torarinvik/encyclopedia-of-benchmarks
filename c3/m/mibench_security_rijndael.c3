module mibench_security_rijndael;

const usz KEY_BYTES = 32;
const usz BLOCK_BYTES = 16;
const usz INPUT_BYTES = 48;

fn uint8 gf_mul(uint8 left_value, uint8 right_value) {
    uint8 left = left_value;
    uint8 right = right_value;
    uint8 result = 0;
    while (right != 0) {
        if ((right & 1) != 0) result ^= left;
        uint16 doubled = (uint16(left) << 1) ^ ((left & 0x80) != 0 ? 0x1b : 0);
        left = (uint8)doubled;
        right >>= 1;
    }
    return result;
}

fn uint8 gf_pow(uint8 value_value, uint32 exponent_value) {
    uint8 value = value_value;
    uint32 exponent = exponent_value;
    uint8 result = 1;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = gf_mul(result, value);
        value = gf_mul(value, value);
        exponent >>= 1;
    }
    return result;
}

fn uint8 rotl8(uint8 value, usz amount) {
    return (uint8)((uint16(value) << amount) | (uint16(value) >> (8 - amount)));
}

fn void make_sbox(uint8* sbox) {
    for (usz value = 0; value < 256; value++) {
        uint8 inverse = value == 0 ? 0 : gf_pow((uint8)value, 254);
        sbox[value] = inverse ^ rotl8(inverse, 1) ^ rotl8(inverse, 2) ^
            rotl8(inverse, 3) ^ rotl8(inverse, 4) ^ 0x63;
    }
}

fn void encrypt_block(uint8* key, uint8* block, uint8* output) {
    uint8[256] sbox;
    make_sbox(&sbox[0]);
    uint8[7] round_constants = {1, 2, 4, 8, 16, 32, 64};
    uint8[240] round_keys;
    for (usz index = 0; index < KEY_BYTES; index++) round_keys[index] = key[index];
    usz written = KEY_BYTES;
    while (written < 240) {
        usz word = written / 4;
        uint8[4] temporary;
        for (usz index = 0; index < 4; index++) temporary[index] = round_keys[written - 4 + index];
        if (word % 8 == 0) {
            uint8 first = temporary[0];
            temporary[0] = sbox[temporary[1]] ^ round_constants[word / 8 - 1];
            temporary[1] = sbox[temporary[2]];
            temporary[2] = sbox[temporary[3]];
            temporary[3] = sbox[first];
        } else if (word % 8 == 4) {
            for (usz index = 0; index < 4; index++) temporary[index] = sbox[temporary[index]];
        }
        for (usz index = 0; index < 4; index++) {
            round_keys[written] = round_keys[written - KEY_BYTES] ^ temporary[index];
            written++;
        }
    }

    uint8[16] state;
    for (usz index = 0; index < BLOCK_BYTES; index++) state[index] = block[index] ^ round_keys[index];
    for (usz round = 1; round < 14; round++) {
        for (usz index = 0; index < BLOCK_BYTES; index++) state[index] = sbox[state[index]];
        uint8[16] previous;
        for (usz index = 0; index < BLOCK_BYTES; index++) previous[index] = state[index];
        for (usz column = 0; column < 4; column++)
            for (usz row = 0; row < 4; row++) state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)];
        for (usz column = 0; column < 4; column++) {
            usz offset = 4 * column;
            uint8 a = state[offset], b = state[offset + 1], c = state[offset + 2], d = state[offset + 3];
            uint8 total = a ^ b ^ c ^ d;
            state[offset] = a ^ total ^ gf_mul(a ^ b, 2);
            state[offset + 1] = b ^ total ^ gf_mul(b ^ c, 2);
            state[offset + 2] = c ^ total ^ gf_mul(c ^ d, 2);
            state[offset + 3] = d ^ total ^ gf_mul(d ^ a, 2);
        }
        usz key_offset = round * BLOCK_BYTES;
        for (usz index = 0; index < BLOCK_BYTES; index++) state[index] ^= round_keys[key_offset + index];
    }
    for (usz index = 0; index < BLOCK_BYTES; index++) state[index] = sbox[state[index]];
    uint8[16] previous;
    for (usz index = 0; index < BLOCK_BYTES; index++) previous[index] = state[index];
    for (usz column = 0; column < 4; column++)
        for (usz row = 0; row < 4; row++) state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)];
    for (usz index = 0; index < BLOCK_BYTES; index++) output[index] = state[index] ^ round_keys[224 + index];
}

fn long mibench_security_rijndael(long* values, usz length, uint8* output,
    usz output_capacity) @export("mibench_security_rijndael") {
    if (values == null || length != INPUT_BYTES) return -1;
    for (usz index = 0; index < INPUT_BYTES; index++)
        if (values[index] < 0 || values[index] > 255) return -1;
    if (output == null || output_capacity < BLOCK_BYTES) return -2;
    uint8[32] key;
    uint8[16] block;
    uint8[16] ciphertext;
    for (usz index = 0; index < KEY_BYTES; index++) key[index] = (uint8)values[index];
    for (usz index = 0; index < BLOCK_BYTES; index++) block[index] = (uint8)values[KEY_BYTES + index];
    encrypt_block(&key[0], &block[0], &ciphertext[0]);
    for (usz index = 0; index < BLOCK_BYTES; index++) output[index] = ciphertext[index];
    return 16;
}
